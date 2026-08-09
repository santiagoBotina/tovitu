require "rails_helper"

RSpec.describe "Saved pets" do
  describe "GET /saved_pets" do
    it "renders server-backed saved pets for a signed-in individual" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }

      pet = create(:pet)
      create(:saved_pet, user: user, pet: pet)

      get saved_pets_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(pet.name)
      expect(response.body).to include(%(id="save-button-#{pet.id}"))
    end

    it "renders the empty state for a signed-out visitor without saved pets" do
      get saved_pets_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("saved_pets.index.empty_title"))
    end
  end

  describe "POST /saved_pets/import" do
    it "imports available localStorage interests into a signed-in individual's account" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }

      pet1 = create(:pet)
      pet2 = create(:pet, status: "on_hold")

      expect do
        post import_saved_pets_path,
             params: { pet_ids: "#{pet1.id},#{pet2.id}" },
             headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }
      end.to change(SavedPet, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(user.saved_pets.pluck(:pet_id)).to include(pet1.id)
      expect(user.saved_pets.pluck(:pet_id)).not_to include(pet2.id)
    end

    it "imports only available pets and is idempotent" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }

      pet = create(:pet)
      create(:saved_pet, user: user, pet: pet)

      expect do
        post import_saved_pets_path, params: { pet_ids: pet.id.to_s }
      end.not_to change(SavedPet, :count)
    end

    it "accepts array-style pet_ids params" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }

      pet1 = create(:pet)
      pet2 = create(:pet)

      post import_saved_pets_path, params: { pet_ids: [ pet1.id.to_s, pet2.id.to_s ] }

      expect(user.saved_pets.pluck(:pet_id)).to contain_exactly(pet1.id, pet2.id)
    end

    it "silently ignores non-numeric pet_ids" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }

      expect do
        post import_saved_pets_path, params: { pet_ids: "abc,1e5,;DROP TABLE pets;--" }
      end.not_to change(SavedPet, :count)
    end

    it "redirects unauthenticated visitors to the login page" do
      post import_saved_pets_path

      expect(response).to redirect_to(new_session_path)
    end

    it "rejects non-individual accounts" do
      shelter_admin = create(:user, :verified, :onboarding_completed, :shelter_admin)
      shelter = create(:shelter)
      shelter_admin.update!(shelter: shelter)
      post session_path, params: { session: { email: shelter_admin.email, password: "password123" } }

      pet = create(:pet)
      post import_saved_pets_path, params: { pet_ids: pet.id.to_s }

      expect(response).to redirect_to(saved_pets_path)
      expect(shelter_admin.saved_pets).to be_empty
    end
  end
end
