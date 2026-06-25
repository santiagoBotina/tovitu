require "rails_helper"

RSpec.describe Pets::Search do
  describe "#call" do
    let(:shelter) { create(:shelter, city: "Portland", state: "OR") }
    let!(:pet1) { create(:pet, shelter: shelter, species: "dog", breed: "Labrador", age_category: "young", size: "large", sex: "male", name: "Buddy") }
    let!(:pet2) { create(:pet, shelter: shelter, species: "cat", breed: "Siamese", age_category: "adult", size: "small", sex: "female", name: "Whiskers") }
    let!(:on_hold_pet) { create(:pet, shelter: shelter, status: "on_hold") }
    let!(:discarded_pet) { create(:pet, shelter: shelter, status: "removed", discarded_at: Time.current) }

    it "returns available pets by default" do
      result = described_class.call
      expect(result).to include(pet1, pet2)
      expect(result).not_to include(on_hold_pet, discarded_pet)
    end

    it "filters by species" do
      result = described_class.call(params: { species: "cat" })
      expect(result).to include(pet2)
      expect(result).not_to include(pet1)
    end

    it "filters by breed" do
      result = described_class.call(params: { breed: "Labrador" })
      expect(result).to include(pet1)
      expect(result).not_to include(pet2)
    end

    it "filters by age_category" do
      result = described_class.call(params: { age_category: "young" })
      expect(result).to include(pet1)
    end

    it "filters by size" do
      result = described_class.call(params: { size: "large" })
      expect(result).to include(pet1)
    end

    it "filters by sex" do
      result = described_class.call(params: { sex: "female" })
      expect(result).to include(pet2)
    end

    it "filters by city" do
      result = described_class.call(params: { city: "portland" })
      expect(result).to include(pet1, pet2)
    end

    it "filters by state" do
      result = described_class.call(params: { state: "or" })
      expect(result).to include(pet1, pet2)
    end

    it "filters by shelter_id" do
      other_shelter = create(:shelter)
      other_pet = create(:pet, shelter: other_shelter)
      result = described_class.call(params: { shelter_id: shelter.id })
      expect(result).to include(pet1)
      expect(result).not_to include(other_pet)
    end

    it "searches by query text" do
      result = described_class.call(params: { query: "buddy" })
      expect(result).to include(pet1)
      expect(result).not_to include(pet2)
    end

    it "paginates results" do
      result = described_class.call(params: { page: 1, per_page: 1 })
      expect(result.size).to eq(1)
    end

    it "accepts a custom status filter" do
      result = described_class.call(params: { status: "on_hold" })
      expect(result).to include(on_hold_pet)
    end

    it "orders by created_at desc" do
      result = described_class.call
      expect(result.first).to eq(pet2)
    end

    it "includes shelter association" do
      result = described_class.call
      expect(result.first.association(:shelter)).to be_loaded
    end
  end
end
