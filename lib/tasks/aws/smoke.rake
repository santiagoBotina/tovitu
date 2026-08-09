# frozen_string_literal: true

# `bin/rails aws:smoke` — verify the AWS emulation layer (LocalStack) is
# reachable and provisioned for every service the migration relies on.
#
# Usage:
#   bin/rails aws:smoke                  # run all checks, exit 0 on success / 1 on failure
#   SKIP_AWS_SMOKE=1 bin/rails aws:smoke # skip (offline dev)
#
# Skips without failing when AWS_ENDPOINT_URL is unset so a machine without
# LocalStack configured never accidentally talks to real AWS.
#
# Each check returns [status, message]: :pass (nil message), :warn (does not
# fail the run), or :fail (exit 1). Warnings are reserved for environmental
# gaps — e.g. `sesv2` and `cognito-idp` are LocalStack Pro-only services that
# respond with a license error on the community image.
require "rails"

namespace :aws do
  desc "Verify the AWS emulation layer (LocalStack) is reachable and provisioned"
  task smoke: :environment do
    if ENV["SKIP_AWS_SMOKE"] == "1"
      puts "AWS smoke check skipped (SKIP_AWS_SMOKE=1)."
      next
    end

    if ENV["AWS_ENDPOINT_URL"].blank?
      puts "AWS smoke check skipped (AWS_ENDPOINT_URL not set). Start LocalStack with `docker compose up -d localstack` and add AWS_ENDPOINT_URL to .env."
      next
    end

    checks = {
      "S3" => s3_check,
      "SQS" => sqs_check,
      "SNS" => sns_check,
      "SES" => ses_check,
      "Secrets Manager" => secrets_check,
      "Cognito" => cognito_check,
      "EventBridge Scheduler" => scheduler_check
    }

    failed = false
    checks.each do |service, check|
      status, message = begin
        check.call
      rescue StandardError => e
        [ :fail, "unexpected error (#{e.class}: #{e.message})" ]
      end
      case status
      when :pass
        puts "  ✔ #{service}"
      when :warn
        puts "  ⚠ #{service}: #{message}"
      when :fail
        failed = true
        $stderr.puts "  ✘ #{service}: #{message}"
      end
    end

    if failed
      $stderr.puts "AWS smoke check FAILED — see messages above. Verify LocalStack is running (`docker compose up -d localstack`) and the init scripts provisioned every resource."
      exit 1
    end

    puts "AWS smoke check passed."
  end

  private

    def pass_result
      [ :pass, nil ]
    end

    def warn_result(message)
      [ :warn, message ]
    end

    def fail_result(message)
      [ :fail, message ]
    end

    def license_required?(error)
      error.message.include?("not included within your LocalStack license")
    end

    def s3_check
      require "aws-sdk-s3"
      lambda do
        bucket = ENV.fetch("S3_BUCKET", "tovitu-development")
        names = Aws::S3::Client.new.list_buckets.buckets.map(&:name)
        names.include?(bucket) ? pass_result : fail_result("bucket '#{bucket}' not found (found: #{names.join(", ")})")
      end
    end

    def sqs_check
      require "aws-sdk-sqs"
      lambda do
        client = Aws::SQS::Client.new
        queues = %w[tovitu-jobs tovitu-jobs-dlq tovitu-mailers tovitu-mailers-dlq]
        failures = []

        queues.each do |queue|
          client.get_queue_url(queue_name: queue)
        rescue Aws::SQS::Errors::QueueDoesNotExist, Aws::Errors::ServiceError => e
          failures << "#{queue} (#{e.class})"
        end

        # Primary queues must redrive to their DLQ after maxReceiveCount = 5.
        {
          "tovitu-jobs" => "tovitu-jobs-dlq",
          "tovitu-mailers" => "tovitu-mailers-dlq"
        }.each do |queue, dlq|
          url = client.get_queue_url(queue_name: queue).queue_url
          attrs = client.get_queue_attributes(queue_url: url, attribute_names: [ "RedrivePolicy" ]).attributes
          policy = attrs["RedrivePolicy"] ? JSON.parse(attrs["RedrivePolicy"]) : {}
          unless policy["maxReceiveCount"] == "5" && policy["deadLetterTargetArn"]&.end_with?(":#{dlq}")
            failures << "#{queue} redrive policy missing (expected maxReceiveCount=5 -> #{dlq})"
          end
        end

        failures.empty? ? pass_result : fail_result(failures.join("; "))
      end
    end

    def sns_check
      require "aws-sdk-sns"
      lambda do
        topics = Aws::SNS::Client.new.list_topics.topics.map(&:topic_arn)
        topics.any? { |arn| arn.end_with?(":tovitu-events") } ? pass_result : fail_result("topic 'tovitu-events' not found (found: #{topics.join(", ")})")
      end
    end

    def ses_check
      require "aws-sdk-sesv2"
      lambda do
        Aws::SESV2::Client.new.list_email_identities
        pass_result
      rescue Aws::Errors::ServiceError => e
        if license_required?(e)
          warn_result("sesv2 requires the LocalStack Pro/student image + license (LOCALSTACK_IMAGE=localstack/localstack-pro:4, LOCALSTACK_AUTH_TOKEN); skipping")
        else
          fail_result("list_email_identities failed (#{e.class}) — LocalStack SES may be unavailable")
        end
      end
    end

    def secrets_check
      require "aws-sdk-secretsmanager"
      lambda do
        name = ENV.fetch("SECRETS_PREFIX", "tovitu/development/runtime")
        Aws::SecretsManager::Client.new.describe_secret(secret_id: name)
        pass_result
      rescue Aws::Errors::ServiceError => e
        fail_result("secret '#{name}' missing or unreachable (#{e.class})")
      end
    end

    def cognito_check
      require "aws-sdk-cognitoidentityprovider"
      lambda do
        pools = Aws::CognitoIdentityProvider::Client.new.list_user_pools(max_results: 60).user_pools
        return pass_result if pools.any? { |pool| pool.name == "tovitu" }

        state = Rails.root.join(".localstack/state/cognito.env")
        hint = state.exist? ? "" : " (run `docker compose restart localstack` to recreate the pool — state file missing at .localstack/state/cognito.env)"
        fail_result("user pool 'tovitu' not found#{hint}")
      rescue Aws::Errors::ServiceError => e
        if license_required?(e)
          warn_result("cognito-idp requires the LocalStack Pro/student image + license (LOCALSTACK_IMAGE=localstack/localstack-pro:4, LOCALSTACK_AUTH_TOKEN); skipping")
        else
          fail_result("user pool 'tovitu' unreachable (#{e.class}: #{e.message})")
        end
      end
    end

    def scheduler_check
      require "aws-sdk-scheduler"
      lambda do
        client = Aws::Scheduler::Client.new
        schedules = client.list_schedules.schedules.map(&:name)
        schedules.any? { |name| name == "tovitu-nightly-maintenance" } ? pass_result : fail_result("schedule 'tovitu-nightly-maintenance' not found (found: #{schedules.join(", ")})")
      end
    end
end
