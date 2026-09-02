require "rails_helper"

RSpec.describe "Page header back navigation", type: :request do
  let(:user) { create(:user, :verified, :onboarding_completed) }

  BACK_CHEVRON = "M15 19l-7-7 7-7"

  def sign_in_as(u)
    post session_path, params: { session: { email: u.email, password: "password123" } }
  end

  describe "shared section header with back link" do
    it "renders back link, title, and description in documented order on my/pets/edit" do
      pet = create(:pet, :individual_listed, publisher: user)
      sign_in_as(user)

      get edit_my_pet_path(pet)

      expect(response).to have_http_status(:ok)
      body = response.body
      title = I18n.t("my.pets.edit.title", name: pet.name)
      expect(body).to include(%(href="#{my_pet_path(pet)}"))
      expect(body).to include(BACK_CHEVRON)
      expect(body).to include(title)
      # Apostrophes are HTML-escaped (&#39;) in the rendered body, so match a safe fragment.
      expect(body).to include("Update this pet")
      # Back link renders above the title (navbar → back link → title → content).
      expect(body.index(BACK_CHEVRON)).to be < body.index(title)
      # Header keeps the top margin that clears the sticky navbar.
      expect(body).to include('<header class="mt-6 mb-6">')
    end

    it "preserves bento-enter animation classes on the shelter policies header" do
      shelter = create(:shelter)
      admin = create(:user, :verified, :shelter_admin, :onboarding_completed, shelter: shelter)
      sign_in_as(admin)

      get edit_shelter_policies_path(shelter_id: shelter)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include(%(href="#{shelter_dashboard_path(shelter_id: shelter)}"))
      expect(body).to include(BACK_CHEVRON)
      expect(body).to include('<header class="mt-6 mb-6 bento-enter bento-enter-d1">')
    end
  end

  describe "entry-point pages" do
    it "does not render a back link on my/pets index" do
      sign_in_as(user)
      get my_pets_path
      expect(response.body).not_to include(BACK_CHEVRON)
    end

    it "does not render a back link on adoption requests index" do
      sign_in_as(user)
      get adoption_requests_path
      expect(response.body).not_to include(BACK_CHEVRON)
    end

    it "does not render a back link on my adoption requests index" do
      sign_in_as(user)
      get my_adoption_requests_path
      expect(response.body).not_to include(BACK_CHEVRON)
    end

    it "does not render a back link on the shelter dashboard" do
      shelter = create(:shelter)
      admin = create(:user, :verified, :shelter_admin, :onboarding_completed, shelter: shelter)
      sign_in_as(admin)
      get shelter_dashboard_path(shelter)
      expect(response.body).not_to include(BACK_CHEVRON)
    end
  end

  describe "safe_back_path wiring on my/pets/show" do
    let(:pet) { create(:pet, :individual_listed, publisher: user) }

    before { sign_in_as(user) }

    it "renders my/pets/show with the PetPresenter (no 500 on GET)" do
      get my_pet_path(pet)

      expect(response).to have_http_status(:ok)
      # Presenter-derived content proves the view-level PetPresenter wrap works.
      expect(response.body).to include(pet.name)
      expect(response.body).to include(I18n.t("pets.species.dog"))
    end

    it "navigates to a valid back_to param" do
      get my_pet_path(pet, back_to: "/en/adoption_requests/1")
      expect(response.body).to include(%(href="/en/adoption_requests/1"))
    end

    it "honors locale-prefixed back_to values for both locales" do
      get my_pet_path(pet, back_to: "/es/adoption_requests/1")
      expect(response.body).to include(%(href="/es/adoption_requests/1"))
    end

    it "falls back to the listing on direct load" do
      get my_pet_path(pet)
      expect(response.body).to include(%(href="#{my_pets_path}"))
    end

    it "falls back to the listing for external back_to values" do
      get my_pet_path(pet, back_to: "https://evil.com")
      expect(response.body).to include(%(href="#{my_pets_path}"))
    end

    it "falls back to the listing for protocol-relative back_to values" do
      get my_pet_path(pet, back_to: "//evil.com")
      expect(response.body).to include(%(href="#{my_pets_path}"))
    end
  end

  describe "back links rendered outside the shared section header" do
    it "keeps an explicit top margin on shelter/pets/show" do
      shelter = create(:shelter)
      admin = create(:user, :verified, :shelter_admin, :onboarding_completed, shelter: shelter)
      pet = create(:pet, shelter: shelter)
      sign_in_as(admin)

      get shelter_pet_path(pet)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include(%(href="#{shelter_pets_path}"))
      expect(body).to include('class="mt-6 mb-6 bento-enter bento-enter-d1"')
    end

    it "keeps an explicit top margin on shelter/pets/media" do
      shelter = create(:shelter)
      admin = create(:user, :verified, :shelter_admin, :onboarding_completed, shelter: shelter)
      pet = create(:pet, shelter: shelter)
      sign_in_as(admin)

      get media_shelter_pet_path(pet)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include(%(href="#{shelter_pet_path(pet)}"))
      expect(body).to include('class="mt-6 mb-6 bento-enter bento-enter-d1"')
    end

    it "keeps an explicit top margin on the public pets/show" do
      pet = create(:pet, :individual_listed)

      get pet_path(pet)

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include(%(href="#{pets_path}"))
      expect(body).to include('class="mt-6 mb-6 bento-enter bento-enter-d1"')
    end
  end
end
