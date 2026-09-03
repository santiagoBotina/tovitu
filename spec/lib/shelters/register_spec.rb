require "rails_helper"

RSpec.describe Shelters::Register do
  describe "#call" do
    let(:user) { create(:user, :verified) }
    let(:shelter_params) do
      {
        name: "Happy Paws Shelter",
        street: "123 Main St",
        city: "Portland",
        state: "OR",
        zip: "97201",
        phone: "555-1234",
        species_served: [ "dog", "cat" ]
      }
    end

    context "with verified user" do
      it "creates a shelter" do
        expect { described_class.call(user: user, shelter_params: shelter_params) }
          .to change(Shelter, :count).by(1)
      end

      it "returns a successful Result" do
        result = described_class.call(user: user, shelter_params: shelter_params)
        expect(result).to be_success
      end

      it "updates user role to shelter_admin" do
        described_class.call(user: user, shelter_params: shelter_params)
        expect(user.reload.role).to eq("shelter_admin")
      end

      it "grants the creator the owner shelter role" do
        described_class.call(user: user, shelter_params: shelter_params)
        expect(user.reload.shelter_role).to eq("owner")
      end

      it "associates the user with the shelter" do
        result = described_class.call(user: user, shelter_params: shelter_params)
        expect(user.reload.shelter_id).to eq(result.data.id)
      end
    end

    context "with unverified user" do
      let(:user) { create(:user) }

      it "returns failure" do
        result = described_class.call(user: user, shelter_params: shelter_params)
        expect(result).to be_failure
      end
    end

    context "with user who already has a shelter" do
      let(:shelter) { create(:shelter) }
      let(:user) { create(:user, :verified, shelter: shelter, role: "shelter_admin") }

      it "returns failure" do
        result = described_class.call(user: user, shelter_params: shelter_params)
        expect(result).to be_failure
      end
    end

    context "with invalid params" do
      it "returns failure" do
        result = described_class.call(user: user, shelter_params: { name: "" })
        expect(result).to be_failure
      end
    end
  end
end
