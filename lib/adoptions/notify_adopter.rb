module Adoptions
  class NotifyAdopter < ApplicationService
    def initialize(adoption_request:)
      @request = adoption_request
    end

    def call
      case @request.status
      when "pending"
        AdoptionMailer.request_confirmation(@request).deliver_later
      when "accepted", "declined", "in_validation"
        AdoptionMailer.status_changed(@request).deliver_later
      end

      Result.success(
        request_id: @request.id,
        notified_adopter: @request.adopter.email,
        email_type: @request.status
      )
    rescue => e
      Result.failure([ "Notification delivery failed: #{e.message}" ])
    end
  end
end
