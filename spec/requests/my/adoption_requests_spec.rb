require "rails_helper"

RSpec.describe "My AdoptionRequests" do
  let(:publisher) { create(:user, :verified, :onboarding_completed) }
  let(:adopter) { create(:user, :verified, :onboarding_completed) }

  before do
    post session_path, params: { session: { email: publisher.email, password: "password123" } }
  end

  describe "GET /my/adoption_requests" do
    it "uses the clarified title for individual publishers" do
      get my_adoption_requests_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("my.adoption_requests.index.title"))
      expect(response.body).not_to include("Incoming Requests")
    end

    it "shows an explanatory empty state for a publisher with no requests" do
      get my_adoption_requests_path

      expect(response.body).to include(I18n.t("my.adoption_requests.index.empty_title"))
      expect(response.body).to include(I18n.t("my.adoption_requests.index.empty_body"))
    end
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

    context "when insights are ready" do
      before do
        AdopterInsight.create!(
          adopter: adopter,
          data: {
            "archetype" => "homebody_companion",
            "commitment_signals" => [],
            "confidence" => "high",
            "provenance" => { "based_on" => "onboarding answers", "activity_up_to" => Date.current.iso8601 }
          },
          generated_at: Time.current
        )
        request.update!(pet_fit_data: {
          "fit_indicators" => {
            "energy" => { "status" => "strong_fit", "evidence" => "Calm home routine." },
            "time" => { "status" => "unknown", "evidence" => "" },
            "experience" => { "status" => "unknown", "evidence" => "" },
            "home_space" => { "status" => "unknown", "evidence" => "" },
            "household" => { "status" => "unknown", "evidence" => "" }
          },
          "summary" => "A great companion match.",
          "verification_questions" => [ "Is anyone home during the day?" ],
          "confidence" => "high"
        })
      end

      it "renders the redesigned visual zones for the individual publisher" do
        get my_adoption_request_path(request)
        expect(response.body).to include("data-testid=\"insight-archetype\"")
        expect(response.body).to include("data-testid=\"insight-fit-factors\"")
        expect(response.body).to include("data-testid=\"insight-checkins\"")
      end
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
