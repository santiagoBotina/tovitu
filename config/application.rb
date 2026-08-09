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
  end
end
