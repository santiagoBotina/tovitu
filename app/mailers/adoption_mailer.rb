class AdoptionMailer < ApplicationMailer
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
end
