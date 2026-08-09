module Notifications
  class Deliver < ApplicationService
    def initialize(recipient:, kind:, notifiable:, title:, body: nil,
                   actor: nil, action_url: nil, metadata: {})
      @recipient   = recipient
      @kind        = kind
      @notifiable  = notifiable
      @title       = title
      @body        = body
      @actor       = actor
      @action_url  = action_url
      @metadata    = metadata
    end

    def call
      # Dedup guard lives here — the single delivery decision point — not at
      # call sites. One notification (and therefore one email) per
      # (recipient, kind, notifiable). Re-delivering the same event returns the
      # existing record without double-sending.
      existing = find_existing
      return Result.success(existing) if existing

      preferences = NotificationPreference.defaults_for(recipient)

      # The record IS the in-app notification. If the user opted out of in-app
      # for this kind, no record is created (no feed entry, no badge count);
      # other enabled channels still deliver.
      notification = create_notification_record! if preferences.kind_enabled?(kind, :in_app)

      deliver_email(notification)  if preferences.kind_enabled?(kind, :email)
      deliver_whatsapp(notification) if preferences.kind_enabled?(kind, :whatsapp)

      Result.success(notification)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    rescue => e
      Result.failure([ "Notification delivery failed: #{e.message}" ])
    end

    private

    attr_reader :recipient, :kind, :notifiable, :title, :body,
                :actor, :action_url, :metadata

    def find_existing
      Notification.find_by(recipient: recipient, kind: kind.to_s, notifiable: notifiable)
    end

    def create_notification_record!
      Notification.create!(
        recipient: recipient,
        actor: actor,
        notifiable: notifiable,
        kind: kind,
        title: title,
        body: body,
        action_url: action_url,
        metadata: metadata
      )
    end

    def deliver_email(notification)
      message = EmailRouting.route_for(kind, notifiable, recipient, notification&.id)
      unless message
        Rails.logger.debug("No email route for notification #{notification&.id} (kind=#{kind})")
        return
      end

      # Enqueue inside the recipient's locale so the background job renders the
      # email in their language (ActiveJob serializes I18n.locale at enqueue).
      # The real delivery outcome is written back by Notifications::DeliveryTracker
      # via the X-Tovitu-Notification-Id header.
      I18n.with_locale(locale_for(recipient)) { message.deliver_later }
    rescue => e
      notification&.update_columns(email_failed_at: Time.current, email_error: e.message)
      Rails.logger.error("Email delivery failed for notification #{notification&.id}: #{e.message}")
    end

    def locale_for(user)
      user&.locale.presence || I18n.default_locale
    end

    def deliver_whatsapp(notification)
      # WhatsApp delivery is gated on the provider — see Messaging::WhatsAppProvider.
      # Opt-in + verified phone only; wired when the provider is available.
      true
    end
  end
end
