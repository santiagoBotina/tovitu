require "rails_helper"

RSpec.describe Locations::SaveFromDevice do
  let(:user) { create(:user) }

  # A fake provider so specs never hit the real Nominatim network endpoint.
  let(:fake_provider) do
    Class.new do
      def reverse(latitude:, longitude:)
        Locations::Place.new(city: "Austin", region: "TX", country: "United States")
      end
    end.new
  end

  describe "#call" do
    it "reduces coordinates to city-level precision (2 decimals) before storage" do
      result = described_class.call(user: user, latitude: "30.267153", longitude: "-97.7431", provider: fake_provider)

      expect(result).to be_success
      location = user.reload.user_location
      expect(location.latitude.to_f).to eq(30.27)
      expect(location.longitude.to_f).to eq(-97.74)
      expect(location.latitude.to_s).not_to eq("30.267153")
      expect(location.longitude.to_s).not_to eq("-97.7431")
    end

    it "stores the reverse-geocoded place with source device" do
      described_class.call(user: user, latitude: "30.267153", longitude: "-97.7431", provider: fake_provider)

      location = user.reload.user_location
      expect(location.city).to eq("Austin")
      expect(location.region).to eq("TX")
      expect(location.country).to eq("United States")
      expect(location.source).to eq("device")
      expect(location).to be_device
    end

    it "records the shared consent decision" do
      described_class.call(user: user, latitude: "30.267153", longitude: "-97.7431", provider: fake_provider)

      user.reload
      expect(user.location_decision).to eq("shared")
      expect(user.location_disclosure_version).to eq(Locations::DISCLOSURE_VERSION)
      expect(user.location_decision_at).to be_present
    end

    it "upserts the existing location instead of creating a duplicate" do
      existing = create(:user_location, user: user, city: "Old City", source: "manual")

      described_class.call(user: user, latitude: "30.267153", longitude: "-97.7431", provider: fake_provider)

      expect(user.reload.user_location.id).to eq(existing.id)
      expect(user.user_location.city).to eq("Austin")
      expect(user.user_location.source).to eq("device")
    end

    context "when coordinates are missing" do
      it "returns failure with a localized error" do
        result = described_class.call(user: user, latitude: nil, longitude: nil, provider: fake_provider)

        expect(result).to be_failure
        expect(result.errors).to include(I18n.t("locations.errors.coordinates_required"))
      end

      it "does not create a location" do
        expect {
          described_class.call(user: user, latitude: nil, longitude: nil, provider: fake_provider)
        }.not_to change(UserLocation, :count)
      end
    end

    context "when reverse geocoding fails" do
      let(:failing_provider) do
        Class.new do
          def reverse(latitude:, longitude:)
            raise Locations::ProviderError, "boom"
          end
        end.new
      end

      it "returns failure with a localized error" do
        result = described_class.call(user: user, latitude: "30.267153", longitude: "-97.7431", provider: failing_provider)

        expect(result).to be_failure
        expect(result.errors).to include(I18n.t("locations.errors.reverse_geocode_failed"))
      end

      it "does not create a location" do
        expect {
          described_class.call(user: user, latitude: "30.267153", longitude: "-97.7431", provider: failing_provider)
        }.not_to change(UserLocation, :count)
      end
    end
  end
end
