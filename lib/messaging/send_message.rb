module Messaging
  class SendMessage < ApplicationService
    def initialize(to:, content:, provider: default_provider)
      @to = to
      @content = content
      @provider = provider
      super()
    end

    def call
      provider.send_message(to: to, content: content)
      Result.success
    end

    private

    attr_reader :to, :content, :provider

    def default_provider
      raise NotImplementedError, "Default messaging provider not configured"
    end
  end
end
