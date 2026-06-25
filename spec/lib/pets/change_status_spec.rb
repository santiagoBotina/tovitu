require "rails_helper"

RSpec.describe Pets::ChangeStatus do
  describe "#call" do
    let(:pet) { create(:pet, status: "available") }

    context "with valid transition" do
      it "changes status" do
        result = described_class.call(pet: pet, new_status: "on_hold")
        expect(result).to be_success
        expect(pet.reload.status).to eq("on_hold")
      end

      it "sets adopted_at when adopting" do
        result = described_class.call(pet: pet, new_status: "adopted")
        expect(result).to be_success
        expect(pet.reload.adopted_at).to be_present
      end

      it "accepts custom adopted_at" do
        custom_date = 2.days.ago
        result = described_class.call(pet: pet, new_status: "adopted", adopted_at: custom_date)
        expect(result).to be_success
        expect(pet.reload.adopted_at.to_i).to eq(custom_date.to_i)
      end
    end

    context "with invalid transition" do
      it "prevents transitioning removed to anything else" do
        removed_pet = create(:pet, status: "removed")
        result = described_class.call(pet: removed_pet, new_status: "available")
        expect(result).to be_failure
      end

      it "prevents transitioning available to invalid status" do
        result = described_class.call(pet: pet, new_status: "invalid_status")
        expect(result).to be_failure
      end
    end
  end
end
