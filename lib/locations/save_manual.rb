module Locations
  class SaveManual < ApplicationService
    def initialize(user:, city:, region: nil, country: nil)
      @user = user
      @city = city
      @region = region
      @country = country
    end

    def call
      return Result.failure([ I18n.t("locations.errors.city_required") ]) if city.blank?

      location = nil
      UserLocation.transaction do
        location = @user.user_location || @user.build_user_location
        location.assign_attributes(
          city: city,
          region: region,
          country: country,
          latitude: nil,
          longitude: nil,
          source: "manual"
        )
        location.save!

        Locations::RecordDecision.call(user: @user, decision: "shared")
      end

      Result.success(location)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end

    private

    attr_reader :user, :city, :region, :country
  end
end
