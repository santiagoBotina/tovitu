module Locations
  class Place
    attr_reader :city, :region, :country

    def initialize(city:, region: nil, country: nil)
      @city = city
      @region = region
      @country = country
      freeze
    end
  end
end
