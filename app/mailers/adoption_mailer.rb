class AdoptionMailer < ApplicationMailer
  HEADER = "X-Tovitu-Notification-Id"

  def request_confirmation(adoption_request, notification_id = nil)
    @request = adoption_request
    @adopter = @request.adopter
    @pet     = @request.pet
    @shelter = @request.shelter
    @recipient = @adopter

    render_in_recipient_locale(@recipient) do
      headers[HEADER] = notification_id.to_s if notification_id.present?
      mail to: @adopter.email, subject: t(".subject", pet_name: @pet.name)
    end
  end

  def status_changed(adoption_request, notification_id = nil)
    @request = adoption_request
    @adopter = @request.adopter
    @pet     = @request.pet
    @shelter = @request.shelter
    @status  = @request.status
    @recipient = @adopter

    render_in_recipient_locale(@recipient) do
      headers[HEADER] = notification_id.to_s if notification_id.present?
      mail to: @adopter.email, subject: t(".subject", pet_name: @pet.name)
    end
  end

  def new_request_notification(adoption_request, recipient, notification_id = nil)
    @request   = adoption_request
    @adopter   = @request.adopter
    @pet       = @request.pet
    @shelter   = @request.shelter
    @recipient = recipient

    render_in_recipient_locale(@recipient) do
      headers[HEADER] = notification_id.to_s if notification_id.present?
      mail to: recipient.email, subject: t(".subject", pet_name: @pet.name)
    end
  end

  def request_withdrawn(adoption_request, recipient = nil, notification_id = nil)
    @request    = adoption_request
    @adopter    = @request.adopter
    @pet        = @request.pet
    @shelter    = @request.shelter
    @recipient  = recipient
    @recipient_name = recipient&.name || @request.responsible_party_name

    render_in_recipient_locale(@recipient) do
      headers[HEADER] = notification_id.to_s if notification_id.present?
      mail to: recipient&.email || @request.responsible_party_email,
           subject: t(".subject", pet_name: @pet.name, adopter_name: @adopter.name)
    end
  end

  private

  # Render the email in the recipient's own language. Shelter staff and
  # publishers must never receive the adopter's language — the recipient's
  # locale wins, falling back to the default. `@locale` is also used by views
  # to build locale-scoped URLs.
  def render_in_recipient_locale(recipient)
    @locale = recipient&.locale.presence || I18n.default_locale
    I18n.with_locale(@locale) { yield }
  end
end
