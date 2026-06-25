require "rails_helper"

RSpec.describe "Shelter::Pets" do
  let(:shelter) { create(:shelter) }
  let(:user) { create(:user, :verified, :shelter_admin, shelter: shelter) }

  before do
    post session_path, params: { session: { email: user.email, password: "password123" } }
  end

  describe "POST /shelter/pets" do
    let(:valid_params) do
      {
        pet: {
          name: "Test Pet",
          species: "dog",
          breed: "Mixed",
          age_category: "adult",
          sex: "male"
        }
      }
    end

    context "with valid photo attachments" do
      it "creates a pet with JPEG photos" do
        file = Rack::Test::UploadedFile.new(
          Rails.root.join("spec/fixtures/files/valid_photo.jpg"),
          "image/jpeg"
        )

        expect {
          post shelter_pets_path, params: valid_params.deep_merge(pet: { photos: [ file ] })
        }.to change(Pet, :count).by(1)

        expect(response).to redirect_to(shelter_pet_path(id: Pet.last))
        expect(Pet.last.photos).to be_attached
      end

      it "attaches multiple photos and sets photo_order" do
        files = [
          Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/valid_photo.jpg"), "image/jpeg"),
          Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/valid_photo_2.jpg"), "image/jpeg")
        ]

        post shelter_pets_path, params: valid_params.deep_merge(pet: { photos: files })

        expect(Pet.last.photos.count).to eq(2)
        expect(Pet.last.photo_order.length).to eq(2)
      end
    end

    context "with invalid file types" do
      it "rejects GIF files" do
        file = Rack::Test::UploadedFile.new(
          Rails.root.join("spec/fixtures/files/valid_photo.gif"),
          "image/gif"
        )

        expect {
          post shelter_pets_path, params: valid_params.deep_merge(pet: { photos: [ file ] })
        }.not_to change(Pet, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "without photos" do
      it "rejects pet creation" do
        expect {
          post shelter_pets_path, params: valid_params
        }.not_to change(Pet, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
