# frozen_string_literal: true

require "aws-sdk-sqs"

module Queuing
  # Thin wrapper around Aws::SQS::Client. The single place that knows SQS
  # exists — jobs, workers, and adapters use this seam, never the SDK directly.
  #
  # SQS notes:
  # - SendMessage DelaySeconds caps at 900s (15 min). For longer delays use
  #   EventBridge Scheduler -> SQS instead (see config for scheduled jobs).
  # - SQS is at-least-once: consumers must tolerate duplicate delivery.
  class Client
    class << self
      def publish(queue:, payload:, delay_seconds: nil)
        new.publish(queue: queue, payload: payload, delay_seconds: delay_seconds)
      end

      def receive(queue:, max_messages: 10, wait_time: 20)
        new.receive(queue: queue, max_messages: max_messages, wait_time: wait_time)
      end

      def ack(queue:, receipt_handle:)
        new.ack(queue: queue, receipt_handle: receipt_handle)
      end
    end

    def publish(queue:, payload:, delay_seconds: nil)
      options = { queue_url: url_for(queue), message_body: payload }
      options[:delay_seconds] = delay_seconds if delay_seconds
      sqs.send_message(options)
    end

    def receive(queue:, max_messages: 10, wait_time: 20)
      response = sqs.receive_message(
        queue_url: url_for(queue),
        max_number_of_messages: max_messages,
        wait_time_seconds: wait_time
      )
      response.messages || []
    end

    def ack(queue:, receipt_handle:)
      sqs.delete_message(queue_url: url_for(queue), receipt_handle: receipt_handle)
    end

    private

    def url_for(active_job_queue_name)
      sqs.get_queue_url(queue_name: Queuing::QueueRegistry.sqs_name_for(active_job_queue_name)).queue_url
    end

    def sqs
      @sqs ||= Aws::SQS::Client.new
    end
  end
end
