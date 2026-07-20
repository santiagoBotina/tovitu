module Adoptions
  class NotifyShelter < ApplicationService
    def initialize(adoption_request:)
      @request = adoption_request
    end

    def call
      shelter = @request.shelter
      return Result.failure([ "No shelter associated with this request" ]) unless shelter

      staff   = shelter.users.undiscarded.where(role: %w[shelter_admin shelter_staff])

      admins = staff.select(&:shelter_admin?)
      admins.each do |admin|
        AdoptionMailer.new_request_notification(@request, admin).deliver_later
      end

      Result.success(
        request_id: @request.id,
        shelter_id: shelter.id,
        notified: admins.map(&:email),
        total_staff: staff.count
      )
    rescue => e
      Result.failure([ "Shelter notification delivery failed: #{e.message}" ])
    end
  end
end
