module Notifications
  # Writes the real mail delivery outcome back onto the Notification record.
  #
  # `Deliver` enqueues the mail with the notification id in an
  # `X-Tovitu-Notification-Id` header. Mailers run inside the background job, so
  # render/delivery failures there were previously invisible on the record —
  # this tracker subscribes to `deliver.action_mailer` and records the actual
  # outcome (delivered / failed + error), closing that observability gap.
  class DeliveryTracker
    EVENT = "deliver.action_mailer"
    HEADER = "X-Tovitu-Notification-Id"

    def self.subscribe!
      ActiveSupport::Notifications.subscribe(EVENT) do |*args|
        new(*args).call
      end
    end

    def self.call(*args)
      new(*args).call
    end

    def initialize(*args)
      @event = ActiveSupport::Notifications::Event.new(*args)
    end

    def call
      notification_id = extract_notification_id
      return if notification_id.blank?

      notification = Notification.find_by(id: notification_id)
      return unless notification

      if @event.payload[:exception].present?
        notification.update_columns(email_failed_at: Time.current, email_error: exception_message)
      else
        notification.update_columns(email_delivered_at: Time.current)
      end
    end

    private

    def extract_notification_id
      mail = @event.payload[:mail]
      return if mail.blank? || !mail.include?(HEADER)

      Mail::Message.new(mail).header[HEADER]&.value
    end

    def exception_message
      Array(@event.payload[:exception]).join(": ")
    end
  end
end
