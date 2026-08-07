require "rails_helper"

RSpec.describe "Pets" do
  let(:shelter) { create(:shelter) }
  let(:pet) { create(:pet, shelter: shelter) }

  describe "GET /pets/:id" do
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
  end
end
