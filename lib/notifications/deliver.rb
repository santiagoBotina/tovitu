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
      notification = create_notification_record!
      deliver_to_channels(notification)
      Result.success(notification)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    rescue => e
      Result.failure([ "Notification delivery failed: #{e.message}" ])
    end

    private

    attr_reader :recipient, :kind, :notifiable, :title, :body,
                :actor, :action_url, :metadata

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

    def deliver_to_channels(notification)
      preferences = NotificationPreference.defaults_for(recipient)

      deliver_in_app(notification) if preferences.kind_enabled?(kind, :in_app)
      deliver_email(notification)  if preferences.kind_enabled?(kind, :email)
      deliver_whatsapp(notification) if preferences.kind_enabled?(kind, :whatsapp)
    end

    def deliver_in_app(notification)
      # In-app delivery is already done — the record is created.
      # Future: broadcast via ActionCable for real-time updates.
      true
    end

    def deliver_email(notification)
      case kind.to_s
      when "request_submitted"
        if notifiable.is_a?(AdoptionRequest)
          if recipient == notifiable.adopter
            AdoptionMailer.request_confirmation(notifiable).deliver_later
          else
            AdoptionMailer.new_request_notification(notifiable, recipient).deliver_later
          end
        end
      when "request_accepted", "request_declined", "request_in_validation"
        if notifiable.is_a?(AdoptionRequest)
          AdoptionMailer.status_changed(notifiable).deliver_later
        end
      when "request_withdrawn"
        if notifiable.is_a?(AdoptionRequest)
          AdoptionMailer.request_withdrawn(notifiable, recipient).deliver_later
        end
      when "info_requested", "info_received"
        if notifiable.is_a?(AdoptionRequest)
          AdoptionMailer.status_changed(notifiable).deliver_later
        end
      when "message_received"
        # Conversation messages will use their own mailer in Phase 2
        Rails.logger.debug("Email for message_received kind not implemented yet")
      when "pet_status_changed"
        # Pet status change notifications use a different mailer
        Rails.logger.debug("Email for pet_status_changed kind not implemented yet")
      when "welcome"
        # Welcome handled by AuthenticationMailer
        Rails.logger.debug("Email for welcome kind not implemented yet")
      end
    rescue => e
      Rails.logger.warn("Email delivery failed for notification #{notification.id}: #{e.message}")
    end

    def deliver_whatsapp(notification)
      # WhatsApp delivery will be implemented when the WhatsApp provider is ready.
      # See Messaging::WhatsAppProvider.
      true
    end
  end
end
