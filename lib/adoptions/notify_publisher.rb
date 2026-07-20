module Adoptions
  class NotifyPublisher < ApplicationService
    def initialize(adoption_request:)
      @request = adoption_request
    end

    def call
      publisher = @request.pet.publisher
      return Result.failure([ "No publisher associated with this request" ]) unless publisher

      case @request.status
      when "pending"
        AdoptionMailer.new_request_notification(@request, publisher).deliver_later
      when "accepted", "declined"
        AdoptionMailer.status_changed(@request).deliver_later
      end

      Result.success(
        request_id: @request.id,
        notified_publisher: publisher.email,
        email_type: @request.status
      )
    rescue => e
      Result.failure([ "Publisher notification delivery failed: #{e.message}" ])
    end
  end
end
