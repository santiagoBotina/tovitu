require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Tovitu
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Use structure.sql for custom PostgreSQL types (pgvector)
    config.active_record.schema_format = :sql

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Internationalization
    config.i18n.default_locale = :en
    config.i18n.available_locales = [ :en, :es ]

    # Use SQS for Active Job (emulated locally by LocalStack).
    # Consume queues with `bin/rails queuing:work`.
    config.active_job.queue_adapter = :sqs

    # Keep mailer delivery off the default queue so long-running AI jobs don't
    # delay email. Mailers route to <prefix>-mailers via Queuing::QueueRegistry.
    config.action_mailer.deliver_later_queue_name = :mailers

    # Permit locale param from routing scope — not user input
    config.action_controller.always_permitted_parameters = %w[locale]

    # Serve Active Storage images through the app (proxy mode) instead of
    # redirecting to short-lived S3 presigned URLs. The proxy controller sets
    # `Cache-Control: max-age=..., immutable` (http_cache_forever), so browsers
    # cache pet photos for a year and repeat visits skip the network entirely.
    # Variant URLs are content-addressed, so immutable caching is safe.
    # Trade-off: image bytes flow through the app until a CDN is added in front.
    config.active_storage.resolve_model_to_route = :rails_storage_proxy

    # Route Active Storage's internal transform job (preprocessed/named
    # variants) to the dedicated `variants` queue instead of the shared
    # default queue. Pets::GeneratePhotoVariantsJob also uses `queue_as
    # :variants`; see Queuing::QueueRegistry.
    config.active_storage.queues = { transform: :variants }

    # Track generated variants in `active_storage_variant_records` so URLs
    # resolve from the DB instead of a per-request S3 HEAD. Safe because
    # Pets::GeneratePhotoVariantsJob pre-generates every canonical variant at
    # upload time, which records each one.
    config.active_storage.track_variants = true
  end
end
