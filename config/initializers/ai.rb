Rails.application.config.ai = ActiveSupport::OrderedOptions.new unless Rails.application.config.respond_to?(:ai)
Rails.application.config.ai.embedding_provider = ENV.fetch("AI_EMBEDDING_PROVIDER", "anthropic")
