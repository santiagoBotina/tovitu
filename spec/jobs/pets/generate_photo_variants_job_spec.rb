require "rails_helper"

RSpec.describe Pets::GeneratePhotoVariantsJob do
  let(:shelter) { create(:shelter) }
  let(:pet) { create(:pet, shelter: shelter) }
  let!(:photo) do
    pet.photos.attach(io: File.open(Rails.root.join("spec/fixtures/files/valid_photo.jpg")), filename: "pet.jpg", content_type: "image/jpeg")
    pet.photos.first
  end

  it "pre-generates every canonical variant" do
    described_class.perform_now(photo.blob_id)

    Pets::PhotoVariants.keys.each do |variant|
      key = Pets::PhotoVariants.for(photo, variant).key
      expect(ActiveStorage::Blob.service.exist?(key)).to be(true)
    end
  end

  it "is a no-op when the blob no longer exists" do
    expect { described_class.perform_now(999_999) }.not_to raise_error
  end

  it "does not raise when a variant cannot be processed" do
    allow(Pets::PhotoVariants).to receive(:for).and_raise(ActiveStorage::InvariableError)

    expect { described_class.perform_now(photo.blob_id) }.not_to raise_error
  end
end
