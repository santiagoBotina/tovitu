require "rails_helper"

RSpec.describe Pets::PhotoManager do
  describe ".attach" do
    let(:pet) { create(:pet) }
    let(:photo) { fixture_file_upload("spec/fixtures/files/valid_photo.jpg", "image/jpeg") }

    it "attaches a photo" do
      result = described_class.attach(pet: pet, file: photo)
      expect(result).to be_success
      expect(pet.reload.photos).to be_attached
    end

    it "updates photo_order" do
      expect { described_class.attach(pet: pet, file: photo) }
        .to change { pet.reload.photo_order }
    end

    context "with invalid content type" do
      let(:gif) { fixture_file_upload("spec/fixtures/files/valid_photo.gif", "image/gif") }

      it "returns failure" do
        result = described_class.attach(pet: pet, file: gif)
        expect(result).to be_failure
      end
    end
  end

  describe ".primary" do
    let(:pet) { create(:pet) }

    it "returns nil when no photos" do
      expect(described_class.primary(pet: pet)).to be_nil
    end
  end
end
