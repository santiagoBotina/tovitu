module Notifications
  class GetUnreadCount < ApplicationService
    def initialize(recipient:)
      @recipient = recipient
    end

    def call
      count = Notification.where(recipient: @recipient, read_at: nil).count
      Result.success(count)
    end
  end
end
