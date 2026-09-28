require "rails_helper"

RSpec.describe Locations::Delete do
  let(:user) { create(:user) }

  describe "#call" do
    it "destroys the user's location" do
      create(:user_location, user: user)

      expect {
        described_class.call(user: user)
      }.to change(UserLocation, :count).by(-1)

      expect(user.reload.user_location).to be_nil
    end

    it "keeps the consent record (REQ-48-4 deletion semantics)" do
      create(:user_location, user: user)
      user.update!(
        location_decision: "shared",
        location_disclosure_version: Locations::DISCLOSURE_VERSION,
        location_decision_at: Time.current
      )

      described_class.call(user: user)

      user.reload
      expect(user.location_decision).to eq("shared")
      expect(user.location_disclosure_version).to eq(Locations::DISCLOSURE_VERSION)
      expect(user.location_decision_at).to be_present
    end

    it "succeeds when the user has no location" do
      result = described_class.call(user: user)

      expect(result).to be_success
    end
  end
end
