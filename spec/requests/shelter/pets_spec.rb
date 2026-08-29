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

  describe "GET /shelter/pets/:id/media" do
    let(:pet) { create(:pet, shelter: shelter) }

    it "renders the media management page" do
      get media_shelter_pet_path(pet)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("shelter.pets.media.add_title"))
    end

    it "denies access to pets from another shelter" do
      other_shelter = create(:shelter)
      other_pet = create(:pet, shelter: other_shelter)

      get media_shelter_pet_path(other_pet)

      expect(response).to redirect_to(shelter_pets_path)
    end
  end

  describe "POST /shelter/pets/:id/photos" do
    let(:pet) { create(:pet, shelter: shelter) }
    let(:jpg) { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/valid_photo.jpg"), "image/jpeg") }

    it "attaches multiple files via turbo_stream" do
      second = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/valid_photo_2.jpg"), "image/jpeg")

      post shelter_pet_photos_path(pet), params: { files: [ jpg, second ] }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(pet.reload.photos.count).to eq(2)
      expect(response.body).to include("pet-media-grid")
    end

    it "adds an image by URL" do
      allow(HTTParty).to receive(:get).and_return(
        double(code: 200, success?: true, headers: { "content-type" => "image/jpeg" }, body: File.binread(Rails.root.join("spec/fixtures/files/valid_photo.jpg")))
      )

      post shelter_pet_photos_path(pet), params: { url: "https://example.com/pet.jpg" }

      expect(response).to redirect_to(shelter_pet_path(pet))
      expect(pet.reload.photos).to be_attached
    end

    it "returns unprocessable when nothing can attach" do
      gif = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/valid_photo.gif"), "image/gif")

      post shelter_pet_photos_path(pet), params: { files: [ gif ] }, headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(pet.reload.photos).not_to be_attached
    end
  end

  describe "POST /shelter/pets/:id/photos/:blob_id/set_primary" do
    let(:pet) { create(:pet, shelter: shelter) }

    before do
      2.times do
        photo = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/valid_photo.jpg"), "image/jpeg")
        Pets::PhotoManager.attach_many(pet: pet, files: [ photo ])
      end
    end

    it "sets the target photo as primary" do
      target = pet.reload.photos.second

      post set_primary_shelter_pet_photo_path(pet, target.blob_id)

      expect(pet.reload.primary_photo.blob_id).to eq(target.blob_id)
    end
  end

  describe "POST /shelter/pets/:id/photos/:blob_id/move" do
    let(:pet) { create(:pet, shelter: shelter) }

    before do
      2.times do
        photo = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/valid_photo.jpg"), "image/jpeg")
        Pets::PhotoManager.attach_many(pet: pet, files: [ photo ])
      end
    end

    it "moves a photo down in the order" do
      first = pet.reload.photos.first
      second = pet.reload.photos.second

      post move_shelter_pet_photo_path(pet, first.blob_id), params: { direction: "down" }

      expect(pet.reload.primary_photo.blob_id).to eq(second.blob_id)
    end
  end
end
