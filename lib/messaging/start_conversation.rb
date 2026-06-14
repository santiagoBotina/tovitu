module Messaging
  class StartConversation < ApplicationService
    def initialize(recipient:, context:, provider: default_provider)
      @recipient = recipient
      @context = context
      @provider = provider
      super()
    end

    def call
      raise NotImplementedError
    end

    private

    attr_reader :recipient, :context, :provider

    def default_provider
      raise NotImplementedError, "Default messaging provider not configured"
    end
  end
end
