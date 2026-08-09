module Notifications
  # Table-driven routing from a notification kind to the mailer message to send.
  #
  # New kinds register here — one mapping per kind, no growing case statement.
  # A kind with no route simply means "no email for this kind yet" (deferred);
  # Deliver logs and skips it, keeping email failures visible instead of silent.
  #
  # The notification id is threaded into the mailer actions so the delivered
  # message carries an X-Tovitu-Notification-Id header, which
  # Notifications::DeliveryTracker uses to write the real delivery outcome back
  # onto the Notification record.
  class EmailRouting
    Route = Struct.new(:kind, :builder, keyword_init: true)

    ROUTES = [
      Route.new(kind: "request_submitted", builder: ->(notifiable, recipient, notification_id) {
        return nil unless notifiable.is_a?(AdoptionRequest)

        if recipient == notifiable.adopter
          AdoptionMailer.request_confirmation(notifiable, notification_id)
        else
          AdoptionMailer.new_request_notification(notifiable, recipient, notification_id)
        end
      }),
      Route.new(kind: "request_in_validation", builder: ->(notifiable, _recipient, notification_id) {
        notifiable.is_a?(AdoptionRequest) ? AdoptionMailer.status_changed(notifiable, notification_id) : nil
      }),
      Route.new(kind: "request_accepted", builder: ->(notifiable, _recipient, notification_id) {
        notifiable.is_a?(AdoptionRequest) ? AdoptionMailer.status_changed(notifiable, notification_id) : nil
      }),
      Route.new(kind: "request_declined", builder: ->(notifiable, _recipient, notification_id) {
        notifiable.is_a?(AdoptionRequest) ? AdoptionMailer.status_changed(notifiable, notification_id) : nil
      }),
      Route.new(kind: "request_withdrawn", builder: ->(notifiable, recipient, notification_id) {
        return nil unless notifiable.is_a?(AdoptionRequest)

        AdoptionMailer.request_withdrawn(notifiable, recipient, notification_id)
      }),
      Route.new(kind: "welcome", builder: ->(notifiable, _recipient, notification_id) {
        # notifiable is the verified User
        AuthenticationMailer.welcome(notifiable, notification_id)
      })
    ].freeze

    # Returns a mailer message (responds to #deliver_later) or nil when the kind
    # has no email route (deferred / not implemented).
    def self.route_for(kind, notifiable, recipient, notification_id = nil)
      route = ROUTES.find { |r| r.kind == kind.to_s }
      route&.builder&.call(notifiable, recipient, notification_id)
    end
  end
end
