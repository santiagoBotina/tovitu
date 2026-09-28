# frozen_string_literal: true

require "rails_helper"

RSpec.describe Queuing::Worker do
  subject(:worker) { described_class.new(queues: %w[default]) }

  def message_for(body, receipt_handle: "receipt-1")
    instance_double(Aws::SQS::Types::Message, body: body, receipt_handle: receipt_handle)
  end

  before do
    allow(Queuing::Client).to receive(:ack)
  end

  describe "#poll_once" do
    context "with a serialized Active Job payload" do
      it "executes it via ActiveJob and acks the message" do
        serialized = { "job_class" => "SomeJob", "job_id" => "job-123", "arguments" => [] }
        message = message_for(serialized.to_json)

        allow(Queuing::Client).to receive(:receive).and_return([ message ])

        expect(ActiveJob::Base).to receive(:execute).with(serialized)
        expect(Queuing::Client).to receive(:ack).with(queue: "default", receipt_handle: "receipt-1")

        worker.poll_once
      end
    end

    context "with an invocation spec for a whitelisted job" do
      it "invokes the job directly and acks the message" do
        message = message_for({ "job_class" => "MaintenanceJob", "arguments" => [] }.to_json)

        allow(Queuing::Client).to receive(:receive).and_return([ message ])

        expect(MaintenanceJob).to receive(:perform_now)
        expect(Queuing::Client).to receive(:ack).with(queue: "default", receipt_handle: "receipt-1")

        worker.poll_once
      end

      it "passes invocation arguments through to the job" do
        message = message_for({ "job_class" => "MaintenanceJob", "arguments" => [ 1, "two" ] }.to_json)

        allow(Queuing::Client).to receive(:receive).and_return([ message ])

        expect(MaintenanceJob).to receive(:perform_now).with(1, "two")

        worker.poll_once
      end
    end

    context "with an invocation spec for a non-whitelisted job" do
      it "does not ack the message (redelivers, then lands in the DLQ)" do
        message = message_for({ "job_class" => "SomeUnknownJob", "arguments" => [] }.to_json)

        allow(Queuing::Client).to receive(:receive).and_return([ message ])

        expect(Queuing::Client).not_to receive(:ack)

        worker.poll_once
      end
    end

    context "with a job whose underlying records are gone" do
      it "discards the message (acks) instead of retrying" do
        message = message_for({ "job_class" => "SomeJob", "job_id" => "job-123", "arguments" => [] }.to_json)

        allow(Queuing::Client).to receive(:receive).and_return([ message ])
        allow(ActiveJob::Base).to receive(:execute) do
          begin
            raise NameError, "uninitialized constant SomeJob"
          rescue NameError
            # ActiveJob raises DeserializationError from inside a rescue, so
            # its constructor can read `$!` — mirror that here.
            raise ActiveJob::DeserializationError
          end
        end

        expect(Queuing::Client).to receive(:ack).with(queue: "default", receipt_handle: "receipt-1")

        worker.poll_once
      end
    end
  end
end
