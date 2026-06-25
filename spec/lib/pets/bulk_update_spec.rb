require "rails_helper"

RSpec.describe Pets::BulkUpdate do
  describe "#call" do
    let(:shelter) { create(:shelter) }
    let!(:pet1) { create(:pet, shelter: shelter, status: "available") }
    let!(:pet2) { create(:pet, shelter: shelter, status: "available") }

    context "with valid params" do
      it "updates multiple pets" do
        result = described_class.call(shelter: shelter, pet_ids: [ pet1.id, pet2.id ], new_status: "on_hold")
        expect(result).to be_success
        expect(result.data[:updated_count]).to eq(2)
        expect(pet1.reload.status).to eq("on_hold")
        expect(pet2.reload.status).to eq("on_hold")
      end

      it "sets adopted_at when adopting" do
        result = described_class.call(shelter: shelter, pet_ids: [ pet1.id ], new_status: "adopted")
        expect(result).to be_success
        expect(pet1.reload.adopted_at).to be_present
      end
    end

    context "with no pet ids" do
      it "returns failure" do
        result = described_class.call(shelter: shelter, pet_ids: [], new_status: "available")
        expect(result).to be_failure
      end
    end

    context "with invalid status" do
      it "returns failure" do
        result = described_class.call(shelter: shelter, pet_ids: [ pet1.id ], new_status: "invalid")
        expect(result).to be_failure
      end
    end

    context "with non-existent pets" do
      it "returns failure" do
        result = described_class.call(shelter: shelter, pet_ids: [ 99999 ], new_status: "available")
        expect(result).to be_failure
      end
    end

    context "with pets from another shelter" do
      let(:other_shelter) { create(:shelter) }
      let!(:other_pet) { create(:pet, shelter: other_shelter) }

      it "ignores pets not belonging to the shelter" do
        result = described_class.call(shelter: shelter, pet_ids: [ other_pet.id ], new_status: "on_hold")
        expect(result).to be_failure
      end
    end
  end
end
