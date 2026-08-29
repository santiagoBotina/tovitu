# frozen_string_literal: true

require "rails_helper"

RSpec.describe Queuing::QueueRegistry do
  describe ".queues" do
    around do |example|
      original = ENV["SQS_QUEUES"]
      ENV["SQS_QUEUES"] = nil
      example.run
    ensure
      ENV["SQS_QUEUES"] = original
    end

    it "returns the default queue set including variants" do
      expect(described_class.queues).to eq(%w[default mailers variants])
    end

    it "returns only the requested queues when SQS_QUEUES is set" do
      ENV["SQS_QUEUES"] = "variants"
      expect(described_class.queues).to eq(%w[variants])
    end

    it "parses a comma-separated list, stripping whitespace and blanks" do
      ENV["SQS_QUEUES"] = " variants , default , "
      expect(described_class.queues).to eq(%w[variants default])
    end
  end

  describe ".sqs_name_for" do
    around do |example|
      original = ENV["SQS_QUEUE_PREFIX"]
      ENV["SQS_QUEUE_PREFIX"] = "tovitu"
      example.run
    ensure
      ENV["SQS_QUEUE_PREFIX"] = original
    end

    it "maps the canonical queue names to their SQS suffix" do
      expect(described_class.sqs_name_for(:default)).to eq("tovitu-jobs")
      expect(described_class.sqs_name_for(:mailers)).to eq("tovitu-mailers")
      expect(described_class.sqs_name_for(:variants)).to eq("tovitu-variants")
    end

    it "falls back to the raw name for unknown queues" do
      expect(described_class.sqs_name_for(:imports)).to eq("tovitu-imports")
    end

    it "honors SQS_QUEUE_PREFIX" do
      ENV["SQS_QUEUE_PREFIX"] = "acme"
      expect(described_class.sqs_name_for(:variants)).to eq("acme-variants")
    end
  end
end
