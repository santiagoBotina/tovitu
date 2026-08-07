require "rails_helper"

RSpec.describe "My AdoptionRequests" do
  let(:publisher) { create(:user, :verified, :onboarding_completed) }
  let(:adopter) { create(:user, :verified, :onboarding_completed) }

  before do
    post session_path, params: { session: { email: publisher.email, password: "password123" } }
  end

  describe "GET /my/adoption_requests/:id" do
    let(:pet) { create(:pet, :individual_listed, publisher: publisher) }
    let!(:request) { create(:adoption_request, pet: pet, adopter: adopter, shelter: nil) }

    it "renders the request review page for the individual publisher" do
      get my_adoption_request_path(request)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(adopter.name)
    end

    it "renders the shared Adopter Insight card" do
      get my_adoption_request_path(request)
      expect(response.body).to include("adopter-insight-card")
      expect(response.body).to include(I18n.t("ai.adopter_insight.card.title"))
    end

    it "prevents access to other publishers' requests" do
      other = create(:pet, :individual_listed)
      other_request = create(:adoption_request, pet: other, adopter: adopter, shelter: nil)
      get my_adoption_request_path(other_request)
      expect(response).to have_http_status(:not_found)
    end

    context "when the pet-fit summary is stale" do
      before do
        AdopterInsight.create!(
          adopter: adopter,
          data: { "archetype" => "family_builder", "confidence" => "medium" },
          signal_fingerprint: "new-signals",
          generated_at: Time.current
        )
        request.update!(
          pet_fit_data: { "fit_indicators" => {}, "confidence" => "low", "summary" => "Old.", "verification_questions" => [] },
          pet_fit_signal_fingerprint: "old-signals",
          pet_fit_fingerprint: "x"
        )
      end

      it "enqueues an async refresh and renders the updating badge" do
        expect {
          get my_adoption_request_path(request)
        }.to have_enqueued_job(Ai::GenerateAdopterInsightJob).with(request_id: request.id)
        expect(response.body).to include(I18n.t("ai.adopter_insight.card.stale_badge"))
      end
    end
  end
end
