# frozen_string_literal: true

module ActiveJob
  module QueueAdapters
    # Active Job adapter backed by Amazon SQS (emulated locally by LocalStack).
    #
    # Jobs are serialized to JSON and published to the queue that maps from
    # `job.queue_name` via Queuing::QueueRegistry. A separate worker process
    # (`bin/rails queuing:work`) long-polls the queues and executes them.
    #
    # SQS SendMessage DelaySeconds caps at 900s (15 min) — see
    # Queuing::Client for longer-delay guidance.
    class SqsAdapter
      def enqueue(job)
        Queuing::Client.publish(queue: job.queue_name, payload: job.serialize.to_json)
      end

      def enqueue_at(job, timestamp)
        delay_seconds = (timestamp.to_f - Time.current.to_f).ceil
        if delay_seconds > 900
          raise ArgumentError,
            "SQS DelaySeconds max is 900s (15 min). Use EventBridge Scheduler for longer delays."
        end
        Queuing::Client.publish(
          queue: job.queue_name,
          payload: job.serialize.to_json,
          delay_seconds: [ delay_seconds, 0 ].max
        )
      end
    end
  end
end
