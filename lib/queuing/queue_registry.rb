# frozen_string_literal: true

module Queuing
  # Canonical SQS queue names, env-driven, mirrored by the LocalStack init
  # scripts (`.localstack/02-queues.sh`) so dev resources match production.
  #
  # Active Job queue name -> SQS queue suffix:
  #   default  -> <prefix>-jobs      (tovitu-jobs)
  #   mailers  -> <prefix>-mailers   (tovitu-mailers)
  #   variants -> <prefix>-variants  (tovitu-variants)
  #
  # Any other Active Job queue name falls back to `<prefix>-<name>`; create the
  # matching SQS queue (and DLQ) before enqueueing to it.
  class QueueRegistry
    QUEUE_MAP = {
      "default" => "jobs",
      "mailers" => "mailers",
      "variants" => "variants"
    }.freeze

    # Queues the worker long-polls by default. Override with SQS_QUEUES
    # (comma-separated) to run a dedicated worker — e.g. `SQS_QUEUES=variants`
    # so image variant generation gets its own process(es) and never
    # head-of-line-blocks behind AI/import jobs on `default`, nor delays
    # `mailers`. Mirrors the init script's queue set.
    DEFAULT_QUEUES = %w[default mailers variants].freeze

    def self.queues
      if ENV["SQS_QUEUES"].present?
        ENV["SQS_QUEUES"].split(",").map(&:strip).reject(&:empty?)
      else
        DEFAULT_QUEUES
      end
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
