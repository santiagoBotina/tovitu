class AdoptionMailer < ApplicationMailer
  before_action :set_locale

  def request_confirmation(adoption_request)
    @request = adoption_request
    @adopter = @request.adopter
    @pet     = @request.pet
    @shelter = @request.shelter

    mail to: @adopter.email, subject: t(".subject", pet_name: @pet.name)
  end

  def status_changed(adoption_request)
    @request = adoption_request
    @adopter = @request.adopter
    @pet     = @request.pet
    @shelter = @request.shelter
    @status  = @request.status

    mail to: @adopter.email, subject: t(".subject", pet_name: @pet.name)
  end

  def new_request_notification(adoption_request, recipient)
    @request   = adoption_request
    @adopter   = @request.adopter
    @pet       = @request.pet
    @shelter   = @request.shelter
    @recipient = recipient

    mail to: recipient.email, subject: t(".subject", pet_name: @pet.name)
  end

  def request_withdrawn(adoption_request, recipient = nil)
    @request    = adoption_request
    @adopter    = @request.adopter
    @pet        = @request.pet
    @shelter    = @request.shelter
    @recipient  = recipient
    @recipient_name = recipient&.name || @request.responsible_party_name

    mail to: recipient&.email || @request.responsible_party_email,
         subject: t(".subject", pet_name: @pet.name, adopter_name: @adopter.name)
  end

  private

  def set_locale
    @locale = @adopter&.locale.presence || @recipient&.locale.presence || I18n.locale
  end
end
