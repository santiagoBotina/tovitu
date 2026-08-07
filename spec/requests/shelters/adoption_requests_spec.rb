require "rails_helper"

RSpec.describe "Shelter AdoptionRequests" do
  let(:shelter) { create(:shelter) }
  let(:user) { create(:user, :verified, :shelter_admin, shelter: shelter) }

  before do
    post session_path, params: { session: { email: user.email, password: "password123" } }
  end

  describe "GET /shelter/adoption_requests/:id" do
    let(:adopter) { create(:user, :verified, :onboarding_completed) }
    let(:pet) { create(:pet, shelter: shelter) }
    let!(:request) do
      create(:adoption_request, pet: pet, adopter: adopter, shelter: shelter)
    end

    context "when the adopter has a completed profile" do
      let!(:profile) do
        create(:individual_profile,
          user: adopter,
          activity_level: "active",
          ideal_companion: "playful_companion",
          pet_experience: "years_of_experience",
          daily_time_available: "2_to_4h",
          personality: "friendly_social",
          adoption_priority: "Looking for an active dog to join me on hikes.",
          adoption_goals: [ "daily_companion", "more_activity" ],
          weekend_activity: [ "going_for_walks", "outdoor_adventures" ])
      end

      it "renders the request with the adopter's name and contact details" do
        get shelter_adoption_request_path(request)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(adopter.name)
        expect(response.body).to include(adopter.email)
      end

      it "renders the adopter profile traits from the onboarding answers" do
        get shelter_adoption_request_path(request)
        expect(response.body).to include(I18n.t("onboarding.individual.questions.q7.options.friendly_social"))
        expect(response.body).to include(I18n.t("onboarding.individual.questions.q2.options.active"))
        expect(response.body).to include(I18n.t("onboarding.individual.questions.q4.options.years_of_experience"))
        expect(response.body).to include(I18n.t("onboarding.individual.questions.q6.options.2_to_4h"))
        expect(response.body).to include(I18n.t("onboarding.individual.questions.q3.options.playful_companion"))
      end

      it "renders the adoption priority quote and goal chips" do
        get shelter_adoption_request_path(request)
        expect(response.body).to include(profile.adoption_priority)
        expect(response.body).to include(I18n.t("onboarding.individual.questions.q5.options.daily_companion"))
        expect(response.body).to include(I18n.t("onboarding.individual.questions.q1.options.going_for_walks"))
      end
    end

    context "when the adopter has no profile" do
      it "shows a friendly empty state instead of crashing" do
        get shelter_adoption_request_path(request)
        expect(response).to have_http_status(:ok)
        # Apostrophes are HTML-escaped (&#39;) in the rendered body, so match a
        # safe fragment of the translated message.
        expect(response.body).to include("completed their profile yet")
      end
    end

    it "links to the pet profile with a back_to param so the pet page can return here" do
      get shelter_adoption_request_path(request)
      expect(response.body).to include(
        %(href="#{shelter_pet_path(request.pet, back_to: shelter_adoption_request_path(request))}")
      )
    end

    context "with additional answers" do
      let!(:request) do
        create(:adoption_request, :with_additional_answers, pet: pet, adopter: adopter, shelter: shelter)
      end

      it "renders every answered question with its label" do
        get shelter_adoption_request_path(request)
        # Apostrophes are HTML-escaped (&#39;) in the rendered body.
        expect(response.body).to include("always wanted a dog like this")
        expect(response.body).to include("I live in a house with a fenced yard.")
        expect(response.body).to include("I have a cat who is friendly with dogs.")
        expect(response.body).to include("I work from home.")
        expect(response.body).to include(I18n.t("adoption_requests.additional_questions.interest_reason", pet_name: pet.name))
      end
    end

    context "without additional answers" do
      it "shows the empty answers message" do
        get shelter_adoption_request_path(request)
        expect(response.body).to include(I18n.t("shelter.adoption_requests.show.answers_empty"))
      end
    end

    context "when the request is pending and can be reviewed" do
      it "renders all decision actions" do
        get shelter_adoption_request_path(request)
        expect(response.body).to include(I18n.t("shelter.adoption_requests.show.mark_validation"))
        expect(response.body).to include(I18n.t("shelter.adoption_requests.show.accept"))
        expect(response.body).to include(I18n.t("shelter.adoption_requests.show.decline"))
      end

      it "does not render the in-validation action when already in validation" do
        request.update!(status: :in_validation)
        get shelter_adoption_request_path(request)
        expect(response.body).not_to include(I18n.t("shelter.adoption_requests.show.mark_validation"))
        expect(response.body).to include(I18n.t("shelter.adoption_requests.show.accept"))
      end
    end

    context "when the request is no longer reviewable" do
      it "does not render the decision actions" do
        request.update!(status: :accepted)
        get shelter_adoption_request_path(request)
        expect(response.body).not_to include(I18n.t("shelter.adoption_requests.show.accept"))
        expect(response.body).not_to include(I18n.t("shelter.adoption_requests.show.decline"))
      end
    end

    it "prevents access to other shelters' requests" do
      other_request = create(:adoption_request)
      get shelter_adoption_request_path(other_request)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "Adopter Insight Card" do
    let(:adopter) { create(:user, :verified, :onboarding_completed) }
    let(:pet) { create(:pet, shelter: shelter) }
    let!(:request) do
      create(:adoption_request, pet: pet, adopter: adopter, shelter: shelter)
    end

    it "renders the Adopter Insight card on the request review page" do
      get shelter_adoption_request_path(request)
      expect(response.body).to include("adopter-insight-card")
      expect(response.body).to include(I18n.t("ai.adopter_insight.card.title"))
    end

    context "when insights are ready" do
      before do
        AdopterInsight.create!(
          adopter: adopter,
          data: {
            "archetype" => "active_outdoors_partner",
            "self_reported_personality" => "adventurous_energetic",
            "archetype_diverges" => false,
            "commitment_signals" => [
              { "label" => "follow_through", "observation" => "Applied to 1 pet and followed through.", "kind" => "positive" }
            ],
            "confidence" => "medium",
            "provenance" => { "sources" => [ "onboarding answers" ], "based_on" => "onboarding answers", "activity_up_to" => Date.current.iso8601 }
          },
          generated_at: Time.current
        )
        request.update!(pet_fit_data: {
          "fit_indicators" => {
            "energy" => { "status" => "strong_fit", "evidence" => "Active lifestyle." },
            "time" => { "status" => "unknown", "evidence" => "" },
            "experience" => { "status" => "unknown", "evidence" => "" },
            "home_space" => { "status" => "strong_fit", "evidence" => "Fenced yard." },
            "household" => { "status" => "unknown", "evidence" => "" }
          },
          "summary" => "A strong match for an active home.",
          "verification_questions" => [ "Have you owned a dog before?" ],
          "confidence" => "medium"
        })
      end

      it "renders the archetype badge, fit indicators, commitment signals, and disclaimer" do
        get shelter_adoption_request_path(request)
        expect(response.body).to include("Active Outdoors Partner")
        expect(response.body).to include(I18n.t("ai.adopter_insight.card.fit_title"))
        expect(response.body).to include("Applied to 1 pet and followed through.")
        expect(response.body).to include(I18n.t("ai.adopter_insight.card.disclaimer"))
        expect(response.body).to include(I18n.t("ai.adopter_insight.card.confidence_label"))
      end

      it "renders a not-enough-activity state instead of fabricating unknown dimensions" do
        get shelter_adoption_request_path(request)
        expect(response.body).to include(I18n.t("ai.adopter_insight.card.not_enough_activity"))
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

      it "enqueues an async refresh on review" do
        expect {
          get shelter_adoption_request_path(request)
        }.to have_enqueued_job(Ai::GenerateAdopterInsightJob).with(request_id: request.id)
      end

      it "renders the updating badge instead of silently showing outdated evidence" do
        get shelter_adoption_request_path(request)
        expect(response.body).to include(I18n.t("ai.adopter_insight.card.stale_badge"))
      end
    end

    context "when the pet-fit summary is current" do
      before do
        AdopterInsight.create!(
          adopter: adopter,
          data: { "archetype" => "family_builder", "confidence" => "medium" },
          signal_fingerprint: "same",
          generated_at: Time.current
        )
        request.update!(
          pet_fit_data: { "fit_indicators" => {}, "confidence" => "low", "summary" => "Current.", "verification_questions" => [] },
          pet_fit_signal_fingerprint: "same",
          pet_fit_fingerprint: "y"
        )
      end

      it "does not enqueue a refresh" do
        expect {
          get shelter_adoption_request_path(request)
        }.not_to have_enqueued_job(Ai::GenerateAdopterInsightJob)
      end
    end
  end
end
