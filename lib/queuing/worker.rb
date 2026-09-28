# frozen_string_literal: true

module Queuing
  # Consumes SQS queues and executes jobs. Long-polls every configured queue,
  # decodes the serialized Active Job payload, executes it, and deletes the
  # message on success.
  #
  # Message formats:
  # - Serialized Active Job payload (from the SQS adapter / perform_later) ->
  #   executed via ActiveJob::Base.execute.
  # - Scheduler invocation spec (from EventBridge Scheduler -> SQS, see
  #   .localstack/06-scheduler.sh) -> the whitelisted job class is
  #   instantiated and run via perform_now. Only classes listed in
  #   SCHEDULED_JOB_WHITELIST are ever constantized — never arbitrary input.
  #
  # Failure semantics:
  # - ActiveJob::DeserializationError / missing records -> discard (the job's
  #   underlying data is gone; retrying cannot succeed). Matches the repo's
  #   `discard_on ActiveJob::DeserializationError` philosophy.
  # - Any other error -> the message is left in flight. The queue's visibility
  #   timeout makes it visible again for retry; after maxReceiveCount it moves
  #   to the matching DLQ (see .localstack/02-queues.sh).
  class Worker
    POLL_TIMEOUT = 20
    MAX_MESSAGES = 10

    # Job classes allowed to be invoked from a Scheduler invocation spec
    # ({"job_class": "...", "arguments": [...]}). Add new recurring jobs here
    # and keep .localstack/06-scheduler.sh in sync.
    SCHEDULED_JOB_WHITELIST = %w[MaintenanceJob].freeze

    def initialize(queues: Queuing::QueueRegistry.queues, logger: Rails.logger)
      @queues = queues
      @logger = logger
    end

    def run
      @logger.info "Queuing::Worker started; polling #{@queues.join(", ")}"
      loop do
        poll_once
        break if ENV["QUEUING_WORK_ONCE"] == "1"
      end
    rescue Interrupt
      @logger.info "Queuing::Worker stopped."
    end

    def poll_once
      @queues.each do |queue|
        messages = Queuing::Client.receive(queue: queue, max_messages: MAX_MESSAGES, wait_time: POLL_TIMEOUT)
        messages.each { |message| process(queue, message) }
      rescue Aws::Errors::ServiceError => e
        @logger.error "Queuing::Worker SQS poll failed on #{queue}: #{e.class} #{e.message}"
      end
    end

    private

    def process(queue, message)
      job_data = ActiveSupport::JSON.decode(message.body)
      execute(job_data)
      Queuing::Client.ack(queue: queue, receipt_handle: message.receipt_handle)
      @logger.info "Processed #{job_data["job_class"]} on #{queue}"
    rescue ActiveJob::DeserializationError => e
      # The record the job references no longer exists — discard instead of retrying.
      Queuing::Client.ack(queue: queue, receipt_handle: message.receipt_handle)
      @logger.warn "Discarded #{queue} message (#{e.message})"
    rescue StandardError => e
      # Retryable failure: leave the message in flight. It will be redelivered
      # after the visibility timeout, then moved to the DLQ at maxReceiveCount.
      @logger.error "Job failed on #{queue}: #{e.class} #{e.message}"
    end

    def execute(job_data)
      if invocation_spec?(job_data)
        invoke_scheduled_job(job_data)
      else
        ActiveJob::Base.execute(job_data)
      end
    end

    # A Scheduler invocation spec carries `job_class` + optional `arguments`
    # but none of the keys Active Job adds when serializing a job (job_id,
    # queue_name, executions, ...).
    def invocation_spec?(job_data)
      job_data.is_a?(Hash) && job_data["job_class"].present? && job_data["job_id"].nil?
    end

    def invoke_scheduled_job(job_data)
      job_class = job_data.fetch("job_class")
      unless SCHEDULED_JOB_WHITELIST.include?(job_class)
        raise ArgumentError, "Scheduled job #{job_class} is not whitelisted"
      end

      job_class.constantize.perform_now(*Array(job_data["arguments"]))
    end
  end
end
