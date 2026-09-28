module Locations
  class SaveFromDevice < ApplicationService
    def initialize(user:, latitude:, longitude:, provider: nil)
      @user = user
      @latitude = latitude
      @longitude = longitude
      @provider = provider
    end

    def call
      return Result.failure([ I18n.t("locations.errors.coordinates_required") ]) if latitude.blank? || longitude.blank?

      # Full device precision is NEVER persisted (REQ-48-4 / AC-48-4). Reduce
      # to city-level precision before storage.
      reduced_lat = latitude.to_f.round(2)
      reduced_lng = longitude.to_f.round(2)

      # Reverse geocode the ORIGINAL coordinates so the city name is accurate.
      geocode_result = reverse_geocode
      return geocode_result if geocode_result.failure?

      place = geocode_result.data

      location = nil
      UserLocation.transaction do
        location = @user.user_location || @user.build_user_location
        location.assign_attributes(
          city: place.city,
          region: place.region,
          country: place.country,
          latitude: reduced_lat,
          longitude: reduced_lng,
          source: "device"
        )
        location.save!

        Locations::RecordDecision.call(user: @user, decision: "shared")
      end

      Result.success(location)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end

    private

    attr_reader :user, :latitude, :longitude, :provider

    def reverse_geocode
      args = { latitude: latitude, longitude: longitude }
      args[:provider] = provider if provider
      Locations::ReverseGeocode.call(**args)
    end
  end
end
