require "rails_helper"

RSpec.describe "Landing page" do
  describe "GET /" do
    it "renders the marketing page for unauthenticated visitors" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("landing.index.title"))
    end

    it "includes the hero search form wired to the pets index" do
      get root_path
      expect(response.body).to include("name=\"query\"")
      expect(response.body).to include("action=\"#{pets_path}\"")
    end

    it "offers species quick-pick links to the pets index" do
      get root_path
      expect(response.body).to include(pets_path(species: "dog"))
      expect(response.body).to include(pets_path(species: "cat"))
    end

    it "renders featured pets from real adoptable data" do
      shelter = create(:shelter)
      pet = create(:pet, shelter: shelter, name: "Fido")

      get root_path

      expect(response.body).to include("Fido")
      expect(response.body).to include(pet_path(pet, back_to: root_path))
    end

    it "does not feature pets that are not available" do
      create(:pet, status: "on_hold", name: "HeldPet")
      create(:pet, status: "adopted", name: "AdoptedPet", adopted_at: 1.day.ago)

      get root_path

      expect(response.body).not_to include("HeldPet")
      expect(response.body).not_to include("AdoptedPet")
    end

    it "renders the conversion-focused sections with i18n copy" do
      get root_path

      # t() output is HTML-escaped by ERB, so compare against the escaped copy.
      expect(response.body).to include(CGI.escapeHTML(I18n.t("landing.index.matching.title")))
      expect(response.body).to include(I18n.t("landing.index.process.title"))
      expect(response.body).to include(I18n.t("landing.index.benefits.title"))
    end

    it "keeps the existing shelter and CTA sections intact" do
      get root_path

      expect(response.body).to include(I18n.t("landing.index.how_it_works.title"))
      expect(response.body).to include(I18n.t("landing.index.for_shelters.title"))
      expect(response.body).to include(I18n.t("landing.index.cta.title"))
      expect(response.body).to include(I18n.t("landing.index.shelter_cta"))
    end

    it "shows the signed-out navbar with a saved-pets prompt trigger" do
      get root_path

      expect(response.body).to include(I18n.t("shared.navbar.sign_in"))
      expect(response.body).to include(I18n.t("shared.interests.aria_view_saved"))
      expect(response.body).to include(I18n.t("shared.interests.prompt_title"))
    end

    it "renders the resume-exploration section in the homepage markup" do
      get root_path

      expect(response.body).to include("data-controller=\"exploration-memory\"")
      expect(response.body).to include(I18n.t("landing.index.resume.title"))
    end

    it "redirects signed-in users away from the marketing page" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }

      get root_path

      expect(response).to redirect_to(user_dashboard_path)
    end
  end
end
