# frozen_string_literal: true

module Queuing
  # Canonical SQS queue names, env-driven, mirrored by the LocalStack init
  # scripts (`.localstack/02-queues.sh`) so dev resources match production.
  #
  # Active Job queue name -> SQS queue suffix:
  #   default  -> <prefix>-jobs      (tovitu-jobs)
  #   mailers  -> <prefix>-mailers   (tovitu-mailers)
  #
  # Any other Active Job queue name falls back to `<prefix>-<name>`; create the
  # matching SQS queue (and DLQ) before enqueueing to it.
  class QueueRegistry
    QUEUE_MAP = {
      "default" => "jobs",
      "mailers" => "mailers"
    }.freeze

    # Queues the worker long-polls. Mirrors the init script's queue set.
    def self.queues
      %w[default mailers]
    end

    def self.sqs_name_for(active_job_queue_name)
      suffix = QUEUE_MAP.fetch(active_job_queue_name.to_s) { active_job_queue_name.to_s }
      "#{prefix}-#{suffix}"
    end

    def self.prefix
      ENV.fetch("SQS_QUEUE_PREFIX", "tovitu")
    end
  end
end
