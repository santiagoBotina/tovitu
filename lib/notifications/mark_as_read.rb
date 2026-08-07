module Notifications
  class MarkAsRead < ApplicationService
    def initialize(notification_or_ids:, recipient:)
      @notification_ids =
        case notification_or_ids
        when Notification
          [ notification_or_ids.id ]
        when Array
          notification_or_ids.map { |n| n.is_a?(Notification) ? n.id : n }
        else
          [ notification_or_ids.to_i ]
        end
      @recipient = recipient
    end

    def call
      count = Notification.where(id: @notification_ids, recipient: @recipient, read_at: nil)
                          .update_all(read_at: Time.current)
      Result.success(count: count)
    end

    class All < ApplicationService
      def initialize(recipient:)
        @recipient = recipient
      end

      def call
        count = Notification.where(recipient: @recipient, read_at: nil)
                            .update_all(read_at: Time.current)
        Result.success(count: count)
      end
    end
  end
end
