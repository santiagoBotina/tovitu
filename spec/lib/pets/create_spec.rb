require "rails_helper"

RSpec.describe Pets::Create do
  describe "#call" do
    let(:shelter) { create(:shelter) }
    let(:valid_params) do
      {
        name: "Buddy",
        species: "dog",
        age_category: "young",
        sex: "male",
        status: "available",
        breed: "Labrador"
      }
    end
    let(:photo) { fixture_file_upload("spec/fixtures/files/valid_photo.jpg", "image/jpeg") }

    context "with valid params and photos" do
      it "creates a pet" do
        expect { described_class.call(shelter: shelter, params: valid_params, photos: [ photo ]) }
          .to change(Pet, :count).by(1)
      end

      it "returns a successful Result" do
        result = described_class.call(shelter: shelter, params: valid_params, photos: [ photo ])
        expect(result).to be_success
      end

      it "attaches photos to the pet" do
        result = described_class.call(shelter: shelter, params: valid_params, photos: [ photo ])
        expect(result.data.photos).to be_attached
      end

      it "sets photo_order" do
        result = described_class.call(shelter: shelter, params: valid_params, photos: [ photo ])
        expect(result.data.photo_order).to be_present
      end
    end

    context "without photos" do
      it "returns failure" do
        result = described_class.call(shelter: shelter, params: valid_params, photos: [])
        expect(result).to be_failure
      end
    end

    context "with invalid file type" do
      let(:gif_photo) { fixture_file_upload("spec/fixtures/files/valid_photo.gif", "image/gif") }

      it "returns failure" do
        result = described_class.call(shelter: shelter, params: valid_params, photos: [ gif_photo ])
        expect(result).to be_failure
      end
    end

    context "with invalid params" do
      it "returns failure when name is missing" do
        result = described_class.call(shelter: shelter, params: valid_params.except(:name), photos: [ photo ])
        expect(result).to be_failure
      end
    end
  end
end
