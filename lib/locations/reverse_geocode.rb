module Locations
  class ReverseGeocode < ApplicationService
    def initialize(latitude:, longitude:, provider: default_provider)
      @latitude = latitude
      @longitude = longitude
      @provider = provider
    end

    def call
      place = provider.reverse(latitude: latitude, longitude: longitude)
      Result.success(place)
    rescue Locations::ProviderError
      Result.failure([ I18n.t("locations.errors.reverse_geocode_failed") ])
    end

    private

    attr_reader :latitude, :longitude, :provider

    def default_provider
      Locations::Providers::Nominatim.new
    end
  end
end
