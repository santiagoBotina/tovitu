require "httparty"

module Locations
  module Providers
    class Nominatim < Base
      ENDPOINT = "https://nominatim.openstreetmap.org/reverse".freeze
      USER_AGENT = "Tovitu/1.0".freeze

      def reverse(latitude:, longitude:)
        response = HTTParty.get(
          ENDPOINT,
          query: { lat: latitude, lon: longitude, format: "json", addressdetails: 1 },
          headers: { "User-Agent" => USER_AGENT }
        )

        raise Locations::ProviderError, "Nominatim returned HTTP #{response.code}" unless response.success?

        data = response.parsed_response
        raise Locations::ProviderError, "Nominatim returned an unexpected payload" unless data.is_a?(Hash)

        address = data["address"]
        raise Locations::ProviderError, "Nominatim response missing address" if address.blank?

        Locations::Place.new(
          city: address["city"] || address["town"] || address["village"] || address["hamlet"] || address["county"],
          region: address["state"] || address["region"],
          country: address["country"]
        )
      rescue HTTParty::Error, JSON::ParserError => e
        raise Locations::ProviderError, "Nominatim request failed: #{e.message}"
      end
    end
  end
end
