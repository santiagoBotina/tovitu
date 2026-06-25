require "rails_helper"

RSpec.describe Pets::Update do
  describe "#call" do
    let(:pet) { create(:pet) }

    context "with valid params" do
      it "updates the pet" do
        result = described_class.call(pet: pet, params: { name: "New Name" })
        expect(result).to be_success
        expect(pet.reload.name).to eq("New Name")
      end
    end

    context "with invalid params" do
      it "returns failure" do
        result = described_class.call(pet: pet, params: { name: "" })
        expect(result).to be_failure
      end
    end
  end
end
