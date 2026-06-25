require "rails_helper"

RSpec.describe Onboarding::DetermineDestination do
  describe "#call" do
    context "with adopter user" do
      let(:adopter) { create(:user, :verified, role: "adopter") }

      it "returns onboarding path when not completed" do
        result = described_class.call(user: adopter)
        expect(result).to eq("/onboarding/adopter/questions")
      end

      it "returns pets path when completed" do
        adopter.update!(onboarding_completed_at: Time.current)
        result = described_class.call(user: adopter)
        expect(result).to eq("/pets")
      end

      it "returns pets path when completed" do
        adopter.update!(onboarding_completed_at: Time.current)
        result = described_class.call(user: adopter)
        expect(result).to eq("/pets")
      end
    end

    context "with shelter user" do
      let(:shelter) { create(:shelter) }
      let(:shelter_admin) { create(:user, :verified, shelter: shelter, role: "shelter_admin") }

      it "returns onboarding path when not completed" do
        result = described_class.call(user: shelter_admin)
        expect(result).to eq("/onboarding/shelter/questions")
      end

      it "returns new shelter path when completed but no shelter" do
        shelter_admin.update!(onboarding_completed_at: Time.current, shelter_id: nil)
        result = described_class.call(user: shelter_admin)
        expect(result).to eq("/shelters/new")
      end

      it "returns dashboard when completed with shelter" do
        shelter_admin.update!(onboarding_completed_at: Time.current)
        result = described_class.call(user: shelter_admin)
        expect(result).to eq("/shelters/#{shelter_admin.shelter_id}/dashboard")
      end
    end

    context "with admin role" do
      let(:admin) { create(:user, :verified, role: "admin") }

      it "returns onboarding path (admin falls under shelter_user)" do
        result = described_class.call(user: admin)
        expect(result).to eq("/onboarding/shelter/questions")
      end
    end
  end
end
