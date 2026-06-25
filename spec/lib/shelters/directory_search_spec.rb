require "rails_helper"

RSpec.describe Shelters::DirectorySearch do
  describe "#call" do
    let!(:shelter1) { create(:shelter, name: "A Shelter", city: "Portland", state: "OR", species_served: [ "dog", "cat" ]) }
    let!(:shelter2) { create(:shelter, name: "B Shelter", city: "Portland", state: "OR", species_served: [ "dog" ]) }
    let!(:shelter3) { create(:shelter, name: "C Shelter", city: "Seattle", state: "WA", species_served: [ "cat" ]) }
    let!(:inactive_shelter) { create(:shelter, :inactive, city: "Portland", state: "OR") }
    let!(:discarded_shelter) { create(:shelter, :discarded, city: "Portland", state: "OR") }

    it "returns active undiscarded shelters" do
      result = described_class.call
      expect(result).to include(shelter1, shelter2, shelter3)
      expect(result).not_to include(inactive_shelter, discarded_shelter)
    end

    it "filters by city" do
      result = described_class.call(params: { city: "portland" })
      expect(result).to include(shelter1, shelter2)
      expect(result).not_to include(shelter3)
    end

    it "filters by state" do
      result = described_class.call(params: { state: "wa" })
      expect(result).to include(shelter3)
      expect(result).not_to include(shelter1, shelter2)
    end

    it "filters by species" do
      result = described_class.call(params: { species: "cat" })
      expect(result).to include(shelter1, shelter3)
      expect(result).not_to include(shelter2)
    end

    it "orders by name" do
      result = described_class.call
      expect(result.first).to eq(shelter1)
      expect(result.last).to eq(shelter3)
    end
  end
end
