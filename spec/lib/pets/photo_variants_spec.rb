require "rails_helper"

RSpec.describe Pets::PhotoVariants do
  let(:shelter) { create(:shelter) }
  let(:pet) { create(:pet, shelter: shelter) }
  let(:photo) do
    pet.photos.attach(io: File.open(Rails.root.join("spec/fixtures/files/valid_photo.jpg")), filename: "pet.jpg", content_type: "image/jpeg")
    pet.photos.first
  end

  describe ".for" do
    it "builds a variant with the canonical webp options" do
      variant = described_class.for(photo, :medium)

      expect(variant.variation.transformations).to include(
        resize_to_limit: [ 400, 400 ],
        format: :webp,
        saver: { quality: 80 }
      )
    end

    it "supports every canonical variant key" do
      described_class.keys.each do |key|
        expect { described_class.for(photo, key) }.not_to raise_error
      end
    end

    it "raises for an unknown variant" do
      expect { described_class.for(photo, :huge) }.to raise_error(KeyError)
    end
  end

  describe ".display_dimensions" do
    it "returns container-matching dimensions for each variant" do
      expect(described_class.display_dimensions(:thumb)).to eq([ 150, 150 ])
      expect(described_class.display_dimensions(:medium)).to eq([ 400, 300 ])
      expect(described_class.display_dimensions(:large)).to eq([ 1200, 750 ])
    end
  end
end
