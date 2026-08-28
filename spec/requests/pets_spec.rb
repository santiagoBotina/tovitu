require "rails_helper"

RSpec.describe "Pets" do
  let(:shelter) { create(:shelter) }
  let(:pet) { create(:pet, shelter: shelter) }

  describe "GET /pets" do
    it "allows unauthenticated visitors to browse the pets index" do
      get pets_path
      expect(response).to have_http_status(:ok)
    end

    it "filters results by query" do
      create(:pet, name: "Beagle Buddy")
      create(:pet, name: "Whiskers")

      get pets_path, params: { query: "Beagle" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Beagle Buddy")
      expect(response.body).not_to include("Whiskers")
    end

    it "includes the exploration memory controller on the filter form" do
      get pets_path

      expect(response.body).to include("data-controller=\"exploration-memory\"")
      expect(response.body).to include("data-exploration-memory-mode-value=\"save\"")
      expect(response.body).to include("data-exploration-memory-signed-in-value=\"false\"")
    end

    it "uses the localStorage interest button for signed-out visitors" do
      pet # materialize before the request so the card renders
      get pets_path

      expect(response.body).to include("data-controller=\"pet-interest\"")
      expect(response.body).to include("data-pet-interest-id-value=\"#{pet.id}\"")
      expect(response.body).not_to include(pet_save_path(pet_id: pet.id))
    end

    it "uses the server-backed save button for signed-in visitors" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }
      pet # materialize before the request so the card renders

      get pets_path

      expect(response.body).to include(%(id="save-button-#{pet.id}"))
      expect(response.body).to include(pet_save_path(pet_id: pet.id))
      expect(response.body).not_to include("data-controller=\"pet-interest\"")
      # Exploration memory is gated off for signed-in users.
      expect(response.body).to include("data-exploration-memory-signed-in-value=\"true\"")
    end

    it "renders the age badge with the English age unit" do
      pet_with_birth = create(:pet, shelter: shelter, age_category: "adult", birth_date: 5.years.ago)
      get pets_path(locale: :en)

      expect(response.body).to include("Adult (5 years)")
    end

    it "renders the age badge with the Spanish age unit" do
      pet_with_birth = create(:pet, shelter: shelter, age_category: "adult", birth_date: 5.years.ago)
      get pets_path(locale: :es)

      expect(response.body).to include("Adulto (5 años)")
      expect(response.body).not_to include("years")
    end

    it "renders the age badge without a birth date using only the localized category" do
      pet_without_birth = create(:pet, shelter: shelter, age_category: "senior", birth_date: nil)
      get pets_path(locale: :es)

      expect(response.body).to include(I18n.t("pets.age_categories.senior", locale: :es))
    end
  end

  describe "GET /pets/:id" do
    it "allows unauthenticated visitors to view an available pet profile" do
      get pet_path(pet)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(pet.name)
      expect(response.body).to include(I18n.t("pets.show.apply_to_adopt"))
    end

    it "links back to the homepage when arriving from a featured pet card" do
      get pet_path(pet, back_to: root_path)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(href="#{root_path}"))
      expect(response.body).to include(CGI.escapeHTML(I18n.t("shared.back_to_home")))
      expect(response.body).not_to include(%(href="#{pets_path}"))
    end

    it "links back to the pets listing by default" do
      get pet_path(pet)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(href="#{pets_path}"))
      expect(response.body).to include(I18n.t("pets.show.back_to_pets"))
    end

    it "links back to the provided back_to path when arriving from an adoption request" do
      request_path = adoption_request_path(id: 123)
      get pet_path(pet, back_to: request_path)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(href="#{request_path}"))
      expect(response.body).not_to include(%(href="#{pets_path}"))
    end

    it "falls back to the pets listing for an unsafe back_to value" do
      get pet_path(pet, back_to: "https://evil.com")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(href="#{pets_path}"))
      expect(response.body).not_to include("evil.com")
    end

    it "renders the labeled save button for signed-out visitors" do
      get pet_path(pet)

      expect(response.body).to include(%(id="save-button-#{pet.id}-label"))
      expect(response.body).to include("data-controller=\"pet-interest\"")
      expect(response.body).to include(CGI.escapeHTML(I18n.t("pets.show.save_to_favorites")))
      expect(response.body).not_to include(pet_save_path(pet_id: pet.id))
    end

    it "renders both save controls for signed-in visitors" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }

      get pet_path(pet)

      expect(response.body).to include(%(id="save-button-#{pet.id}"))
      expect(response.body).to include(%(id="save-button-#{pet.id}-label"))
      expect(response.body).to include(pet_save_path(pet_id: pet.id))
      expect(response.body).to include(CGI.escapeHTML(I18n.t("pets.show.save_to_favorites")))
    end

    it "renders the age badge on the pet profile in English" do
      pet_with_birth = create(:pet, shelter: shelter, age_category: "adult", birth_date: 5.years.ago)
      get pet_path(pet_with_birth, locale: :en)

      expect(response.body).to include("Adult (5 years)")
    end

    it "renders the age badge on the pet profile in Spanish" do
      pet_with_birth = create(:pet, shelter: shelter, age_category: "adult", birth_date: 5.years.ago)
      get pet_path(pet_with_birth, locale: :es)

      expect(response.body).to include("Adulto (5 años)")
      expect(response.body).not_to include("years")
    end
  end
end
