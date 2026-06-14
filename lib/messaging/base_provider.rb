module Messaging
  class BaseProvider
    def send_message(to:, content:)
      raise NotImplementedError, "#{self.class} must implement #send_message"
    end

    def parse_webhook(payload)
      raise NotImplementedError, "#{self.class} must implement #parse_webhook"
    end
  end
end
