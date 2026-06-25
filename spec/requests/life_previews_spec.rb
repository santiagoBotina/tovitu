require "rails_helper"

RSpec.describe "LifePreviews" do
  let(:shelter) { create(:shelter) }
  let(:pet) { create(:pet, shelter: shelter) }

  describe "GET /pets/:pet_id/life_preview" do
    context "when pet has cached preview data" do
      let(:pet) { create(:pet, :with_life_preview, shelter: shelter) }

      it "renders the life preview partial" do
        get pet_life_preview_path(pet_id: pet.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("turbo-frame")
        expect(response.body).to include("life_preview")
        expect(response.body).to include("Daily Routine")
      end

      it "includes plan data in the rendered HTML" do
        get pet_life_preview_path(pet_id: pet.id)

        expect(response.body).to include("Week 0")
        expect(response.body).to include("Prepare supplies")
      end

      it "includes tips data in the rendered HTML" do
        get pet_life_preview_path(pet_id: pet.id)

        expect(response.body).to include("Home preparation")
        expect(response.body).to include("Food bowls")
      end
    end

    context "when pet has no cached preview" do
      it "renders the loading state" do
        get pet_life_preview_path(pet_id: pet.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("life-preview-loading")
        expect(response.body).to include("turbo-frame")
      end

      it "enqueues a generation job" do
        expect {
          get pet_life_preview_path(pet_id: pet.id)
        }.to have_enqueued_job(Ai::GenerateLifePreviewJob).with(pet.id)
      end
    end

    context "when pet has stale preview" do
      let(:pet) { create(:pet, :with_life_preview, shelter: shelter) }

      before do
        pet.update!(life_preview_version: 1)
      end

      it "renders the loading state" do
        get pet_life_preview_path(pet_id: pet.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("life-preview-loading")
      end

      it "enqueues a regeneration job" do
        expect {
          get pet_life_preview_path(pet_id: pet.id)
        }.to have_enqueued_job(Ai::GenerateLifePreviewJob).with(pet.id)
      end
    end

    context "when pet does not exist" do
      it "returns 404" do
        get pet_life_preview_path(pet_id: 99999)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
