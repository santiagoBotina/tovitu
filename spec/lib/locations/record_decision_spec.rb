require "rails_helper"

RSpec.describe Locations::RecordDecision do
  let(:user) { create(:user) }

  describe "#call" do
    it "records the decision with the disclosure version and timestamp" do
      result = described_class.call(user: user, decision: "shared")

      expect(result).to be_success
      user.reload
      expect(user.location_decision).to eq("shared")
      expect(user.location_disclosure_version).to eq(Locations::DISCLOSURE_VERSION)
      expect(user.location_decision_at).to be_present
    end

    it "records a skipped decision" do
      described_class.call(user: user, decision: "skipped")

      user.reload
      expect(user.location_decision).to eq("skipped")
      expect(user.location_disclosure_version).to eq(Locations::DISCLOSURE_VERSION)
      expect(user.location_decision_at).to be_present
    end

    it "does not overwrite the timestamp when the same decision is recorded again (REQ-48-4)" do
      described_class.call(user: user, decision: "shared")
      original = user.reload.location_decision_at

      travel 1.day do
        described_class.call(user: user, decision: "shared")
      end

      expect(user.reload.location_decision_at).to eq(original)
    end

    it "re-records when the decision changes" do
      described_class.call(user: user, decision: "shared")
      original = user.reload.location_decision_at

      travel 1.day do
        described_class.call(user: user, decision: "skipped")
      end

      user.reload
      expect(user.location_decision).to eq("skipped")
      expect(user.location_decision_at).not_to eq(original)
    end
  end
end
