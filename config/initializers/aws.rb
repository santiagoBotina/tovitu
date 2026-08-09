# frozen_string_literal: true

# Centralized AWS client configuration.
#
# The same code runs against LocalStack (development/test/CI) and real AWS
# (production) — only ENV changes:
#
#   AWS_ENDPOINT_URL                     e.g. http://localhost:4566 (LocalStack); unset in prod
#   AWS_REGION                           e.g. us-east-1
#   AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
#                                        static credentials (LocalStack/test); unset in prod (IAM role)
#   AWS_LOG_LEVEL                        logger level (default :info)
#
# Business code must never hardcode endpoints, credentials, or regions.
# Consumers require their own client, e.g. `require "aws-sdk-sqs"`.

require "aws-sdk-core"

Aws.config.update(region: ENV.fetch("AWS_REGION", "us-east-1"))

Aws.config[:endpoint] = ENV["AWS_ENDPOINT_URL"] if ENV["AWS_ENDPOINT_URL"].present?

if ENV["AWS_ACCESS_KEY_ID"].present? && ENV["AWS_SECRET_ACCESS_KEY"].present?
  Aws.config[:credentials] = Aws::Credentials.new(
    ENV.fetch("AWS_ACCESS_KEY_ID"),
    ENV.fetch("AWS_SECRET_ACCESS_KEY")
  )
end

Aws.config[:logger] = Rails.logger
Aws.config[:log_level] = ENV.fetch("AWS_LOG_LEVEL", "info").to_sym
