module Messaging
  class ReceiveWebhook < ApplicationService
    def initialize(payload:, provider:)
      @payload = payload
      @provider = provider
      super()
    end

    def call
      message = provider.parse_webhook(payload)
      raise NotImplementedError
    end

    private

    attr_reader :payload, :provider
  end
end
