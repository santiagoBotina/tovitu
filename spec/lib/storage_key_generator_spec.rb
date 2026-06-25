require "rails_helper"

RSpec.describe StorageKeyGenerator do
  describe ".pet_photo" do
    it "generates a key with shelter and pet name" do
      key = described_class.pet_photo("Happy Paws", "Buddy")
      expect(key).to match(%r{^happy-paws/pets/buddy/[a-z0-9]+$})
    end

    it "handles special characters" do
      key = described_class.pet_photo("McDonald's Rescue!", "Luna #1")
      expect(key).to match(%r{^mcdonald-s-rescue/pets/luna-1/[a-z0-9]+$})
    end

    it "uses unnamed fallback" do
      key = described_class.pet_photo("", "")
      expect(key).to match(%r{^unnamed/pets/unnamed/[a-z0-9]+$})
    end
  end

  describe ".shelter_logo" do
    it "generates a logo key" do
      key = described_class.shelter_logo("Happy Paws")
      expect(key).to match(%r{^happy-paws/logo/[a-z0-9]+$})
    end
  end

  describe ".shelter_cover" do
    it "generates a cover image key" do
      key = described_class.shelter_cover("Happy Paws")
      expect(key).to match(%r{^happy-paws/cover/[a-z0-9]+$})
    end
  end

  describe ".shelter_profile" do
    it "generates a profile image key" do
      key = described_class.shelter_profile("Happy Paws")
      expect(key).to match(%r{^happy-paws/profile/[a-z0-9]+$})
    end
  end

  describe ".ai_document" do
    it "generates a document key" do
      key = described_class.ai_document("Happy Paws")
      expect(key).to match(%r{^happy-paws/documents/[a-z0-9]+$})
    end
  end

  describe ".random_key" do
    it "generates a random string" do
      key1 = described_class.random_key
      key2 = described_class.random_key
      expect(key1).not_to eq(key2)
      expect(key1.length).to eq(28)
    end
  end
end
