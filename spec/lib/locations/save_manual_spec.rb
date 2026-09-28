require "rails_helper"

RSpec.describe Locations::SaveManual do
  let(:user) { create(:user) }

  describe "#call" do
    it "creates a manual location with nil coordinates" do
      result = described_class.call(user: user, city: "Austin", region: "TX", country: "United States")

      expect(result).to be_success
      location = user.reload.user_location
      expect(location.city).to eq("Austin")
      expect(location.region).to eq("TX")
      expect(location.country).to eq("United States")
      expect(location.source).to eq("manual")
      expect(location).to be_manual
      expect(location.latitude).to be_nil
      expect(location.longitude).to be_nil
    end

    it "records the shared consent decision" do
      described_class.call(user: user, city: "Austin")

      user.reload
      expect(user.location_decision).to eq("shared")
      expect(user.location_disclosure_version).to eq(Locations::DISCLOSURE_VERSION)
      expect(user.location_decision_at).to be_present
    end

    it "upserts the existing location instead of creating a duplicate" do
      existing = create(:user_location, user: user, city: "Old City", source: "device")

      described_class.call(user: user, city: "Round Rock")

      expect(user.reload.user_location.id).to eq(existing.id)
      expect(user.user_location.city).to eq("Round Rock")
      expect(user.user_location.source).to eq("manual")
    end

    context "when city is blank" do
      it "returns failure with a localized error" do
        result = described_class.call(user: user, city: "")

        expect(result).to be_failure
        expect(result.errors).to include(I18n.t("locations.errors.city_required"))
      end

      it "does not create a location" do
        expect {
          described_class.call(user: user, city: "")
        }.not_to change(UserLocation, :count)
      end
    end
  end
end
