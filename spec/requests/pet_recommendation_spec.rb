require "rails_helper"

RSpec.describe "Pet Recommendation" do
  let(:shelter) { create(:shelter, name: "Happy Paws Rescue") }
  let(:pet) { create(:pet, shelter: shelter) }

  describe "GET /pets/:id" do
    context "when a recommendation is present" do
      before { pet.update!(recommendation: "Luna would thrive in a calm, patient home with an experienced owner.") }

      it "renders the shelter-recommendation section with clear framing" do
        get pet_path(pet)

        expect(response.body).to include(CGI.escapeHTML(I18n.t("pets.show.recommendation_shelter_title", name: pet.name)))
        expect(response.body).to include(CGI.escapeHTML(I18n.t("pets.show.recommendation_written_by", author: shelter.name)))
        expect(response.body).to include("Luna would thrive in a calm, patient home")
      end

      it "does NOT label the recommendation as AI-generated" do
        get pet_path(pet)
        # The AI Life Preview carries the 🤖 disclaimer; the shelter
        # recommendation must not reuse it (visual differentiation).
        expect(response.body).not_to include(I18n.t("pets.show.life_preview_disclaimer"))
      end
    end

    context "when no recommendation is provided" do
      it "does not render the recommendation section" do
        get pet_path(pet)

        expect(response.body).not_to include(I18n.t("pets.show.recommendation_shelter_title", name: pet.name).gsub(" ", ""))
        expect(response.body).not_to include("What the shelter says about")
      end
    end

    context "for an individual-listed pet" do
      it "frames the recommendation with the publisher's name" do
        publisher = create(:user, :verified, :onboarding_completed, name: "Maria Gomez")
        pet = create(:pet, :individual_listed, publisher: publisher, recommendation: "He is the sweetest boy you will ever meet.")

        get pet_path(pet)

        expect(response.body).to include(CGI.escapeHTML(I18n.t("pets.show.recommendation_individual_title", name: pet.name, publisher: publisher.name)))
        expect(response.body).to include(CGI.escapeHTML(I18n.t("pets.show.recommendation_written_by", author: publisher.name)))
      end
    end

    it "neutralizes malicious stored payloads on render (defense in depth)" do
      # Bypass write-time sanitization to prove the render path escapes too.
      pet.update_columns(recommendation: '<script>alert("xss")</script><img src=x onerror=alert(1)>Luna')

      get pet_path(pet)

      expect(response.body).not_to include("<script>alert")
      expect(response.body).not_to include("onerror")
      expect(response.body).to include("Luna")
    end
  end

  describe "shelter pet form (POST /shelter/pets)" do
    let(:shelter_admin) { create(:user, :verified, :shelter_admin, shelter: shelter) }

    before do
      post session_path, params: { session: { email: shelter_admin.email, password: "password123" } }
    end

    it "stores the recommendation sanitized to plain text" do
      file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/valid_photo.jpg"), "image/jpeg")

      post shelter_pets_path, params: {
        pet: {
          name: "Luna",
          species: "dog",
          breed: "Mixed",
          age_category: "adult",
          sex: "female",
          recommendation: '<script>alert(1)</script>A sweet calm dog <b>for</b> a quiet home',
          photos: [ file ]
        }
      }

      created = Pet.last
      expect(created.recommendation).to eq("A sweet calm dog for a quiet home")
      expect(created.recommendation).not_to include("<script")
    end

    it "rejects profanity with a friendly validation error" do
      file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/valid_photo.jpg"), "image/jpeg")

      post shelter_pets_path, params: {
        pet: {
          name: "Luna",
          species: "dog",
          breed: "Mixed",
          age_category: "adult",
          sex: "female",
          recommendation: "This pet is complete shit",
          photos: [ file ]
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Pet.count).to eq(0)
      expect(response.body).to include(CGI.escapeHTML(I18n.t("pets.errors.recommendation_inappropriate")))
    end
  end

  describe "individual publisher form (POST /my/pets)" do
    let(:publisher) { create(:user, :verified, :onboarding_completed) }

    before do
      post session_path, params: { session: { email: publisher.email, password: "password123" } }
    end

    it "stores the recommendation sanitized to plain text" do
      file = Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/valid_photo.jpg"), "image/jpeg")

      post my_pets_path, params: {
        pet: {
          name: "Rocky",
          species: "dog",
          breed: "Mixed",
          age_category: "young",
          sex: "male",
          status: "available",
          recommendation: '<img src=x onerror="alert(1)">A loyal little friend',
          photos: [ file ]
        }
      }

      expect(response).to redirect_to(my_pet_path(Pet.last))
      expect(Pet.last.recommendation).to eq("A loyal little friend")
      expect(Pet.last.recommendation).not_to include("onerror")
    end
  end
end
