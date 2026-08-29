require "rails_helper"

RSpec.describe "Individual Dashboard (Gamification)" do
  let(:user) { create(:user, :verified) }

  before do
    post session_path, params: { session: { email: user.email, password: "password123" } }
  end

  describe "GET /dashboard" do
    it "renders the adoption journey readiness card with stages" do
      get user_dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("dashboard.index.readiness.title"))
      expect(response.body).to include(I18n.t("dashboard.index.readiness.stage.getting_started"))
    end

    it "renders the Your Journey milestone list" do
      get user_dashboard_path

      expect(response.body).to include(I18n.t("dashboard.index.journey.title"))
      expect(response.body).to include(I18n.t("dashboard.index.journey.milestone.profile_starter"))
      expect(response.body).to include(I18n.t("dashboard.index.journey.milestone.first_saved_pet"))
    end

    it "shows the onboarding nudge with what's missing for an incomplete profile" do
      get user_dashboard_path

      expect(response.body).to include(I18n.t("dashboard.index.onboarding.missing.complete_profile"))
    end

    it "does not render a fabricated match score" do
      get user_dashboard_path

      expect(response.body).not_to match(/\d+% Match/)
    end

    it "renders the journey explanation for a fresh user" do
      get user_dashboard_path

      expect(response.body).to include(CGI.escapeHTML(I18n.t("dashboard.index.journey_card.explanation.fresh")))
    end

    it "renders the achieved-milestones summary" do
      get user_dashboard_path

      expect(response.body).to include(CGI.escapeHTML(I18n.t("dashboard.index.journey_card.achieved", done: 0, total: 5)))
    end

    it "renders the complete-profile CTA for a fresh user" do
      get user_dashboard_path

      expect(response.body).to include(CGI.escapeHTML(I18n.t("dashboard.index.journey_card.cta.complete_profile")))
      expect(response.body).to include(profile_onboarding_path)
    end

    it "renders the accompaniment line" do
      get user_dashboard_path

      expect(response.body).to include(CGI.escapeHTML(I18n.t("dashboard.index.journey_card.accompaniment")))
    end

    it "does not introduce points, levels, or leaderboards" do
      get user_dashboard_path

      expect(response.body).not_to include("Leaderboard")
      expect(response.body).not_to match(/>\s*(Points?|Levels?)\s*</)
      expect(response.body).not_to include(I18n.t("dashboard.index.journey_card.cta.see_requests"))
    end

    it "renders the browse pets CTA without a translation-missing marker" do
      get user_dashboard_path

      # Regression: the CTA lives inside the section_header block, which is
      # captured with `capture { yield }` — lazy keys inside the block used to
      # resolve against shared/section_header and show "translation missing".
      expect(response.body).to include(I18n.t("dashboard.index.welcome.cta_browse"))
      expect(response.body).not_to include("translation missing")
    end

    context "when onboarding is complete" do
      let(:user) { create(:user, :verified, :onboarding_completed) }

      it "does not render the onboarding nudge" do
        get user_dashboard_path

        expect(response.body).not_to include(I18n.t("dashboard.index.onboarding.missing.complete_profile"))
      end

      it "renders the next step to save a pet" do
        get user_dashboard_path

        expect(response.body).to include(I18n.t("dashboard.index.readiness.next_step.next_save_pet"))
      end

      it "renders the mid-journey explanation once a pet is saved" do
        create(:saved_pet, user: user)
        get user_dashboard_path

        expect(response.body).to include(CGI.escapeHTML(I18n.t("dashboard.index.journey_card.explanation.mid_journey")))
        expect(response.body).to include(CGI.escapeHTML(I18n.t("dashboard.index.journey_card.cta.browse_pets")))
        expect(response.body).to include(pets_path)
      end
    end

    context "when the user has an active adoption request" do
      let(:user) { create(:user, :verified, :onboarding_completed) }

      it "renders the active_applicant explanation and see-requests CTA" do
        create(:adoption_request, adopter: user, status: :pending)
        get user_dashboard_path

        expect(response.body).to include(CGI.escapeHTML(I18n.t("dashboard.index.journey_card.explanation.active_applicant")))
        expect(response.body).to include(CGI.escapeHTML(I18n.t("dashboard.index.journey_card.cta.see_requests")))
        expect(response.body).to include(adoption_requests_path)
      end
    end
  end

  describe "requests-for-my-pets naming (REQ-13)" do
    it "uses the clarified sidebar label instead of Incoming Requests" do
      get user_dashboard_path

      expect(response.body).to include(I18n.t("shared.sidebar.incoming_requests"))
      expect(response.body).not_to include("Incoming Requests")
    end

    it "uses the clarified dashboard card title for publishers" do
      get user_dashboard_path

      expect(response.body).to include(CGI.escapeHTML(I18n.t("dashboard.index.incoming_requests")))
    end
  end

  describe "sidebar journey label" do
    it "is data-driven, not the hardcoded Animal Ally" do
      get user_dashboard_path

      expect(response.body).not_to include("Animal Ally")
      expect(response.body).to include(I18n.t("shared.sidebar.journey_label.label_getting_started"))
    end

    it "reflects the ready-to-adopt stage for an active applicant" do
      user.update!(onboarding_completed_at: Time.current)
      create(:adoption_request, adopter: user, status: :pending)

      get user_dashboard_path

      expect(response.body).to include(I18n.t("shared.sidebar.journey_label.label_ready_to_adopt"))
    end
  end

  describe "milestone feedback on completed actions" do
    it "flashes a milestone-unlocked notice when a user saves their first pet" do
      pet = create(:pet)

      post pet_save_path(pet_id: pet.id)

      expect(flash[:notice]).to eq(I18n.t("gamification.milestone_unlocked.first_saved_pet"))
    end

    it "does not flash the milestone notice on a second saved pet" do
      pet = create(:pet)
      create(:saved_pet, user: user, pet: pet)

      other_pet = create(:pet)
      post pet_save_path(pet_id: other_pet.id)

      expect(flash[:notice]).not_to eq(I18n.t("gamification.milestone_unlocked.first_saved_pet"))
    end

    it "appends the milestone toast in the turbo_stream response on first save" do
      pet = create(:pet)

      post pet_save_path(pet_id: pet.id),
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include("flash-container")
      expect(response.body).to include(I18n.t("gamification.milestone_unlocked.first_saved_pet"))
    end

    it "renders the milestone toast with fixed floating positioning so it overlays the page" do
      pet = create(:pet)

      post pet_save_path(pet_id: pet.id),
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      # The toast must float top-right like shared/_flash, not render in
      # document flow at the top of the page.
      expect(response.body).to include("fixed top-16 right-4 z-40")
      expect(response.body).to include("role=\"alert\"")
      expect(response.body).to include(I18n.t("shared.toast.dismiss"))
    end

    it "does not append the milestone toast in the turbo_stream response on a second save" do
      pet = create(:pet)
      create(:saved_pet, user: user, pet: pet)

      other_pet = create(:pet)
      post pet_save_path(pet_id: other_pet.id),
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.body).not_to include(I18n.t("gamification.milestone_unlocked.first_saved_pet"))
    end
  end
end

RSpec.describe "Shelter Sidebar (Gamification label)" do
  it "reflects the live/active shelter status and never shows Animal Ally" do
    shelter = create(:shelter) # status defaults to active
    shelter_admin = create(:user, :verified, :shelter_admin, shelter: shelter)
    post session_path, params: { session: { email: shelter_admin.email, password: "password123" } }

    get shelter_dashboard_path(shelter_id: shelter.id)

    expect(response.body).not_to include("Animal Ally")
    expect(response.body).to include(CGI.escapeHTML(I18n.t("shared.sidebar.journey_label.shelter_live")))
  end

  it "reflects the setting-up shelter status while a shelter is inactive" do
    shelter = create(:shelter, :inactive)
    shelter_admin = create(:user, :verified, :shelter_admin, shelter: shelter)
    post session_path, params: { session: { email: shelter_admin.email, password: "password123" } }

    get shelter_dashboard_path(shelter_id: shelter.id)

    expect(response.body).to include(CGI.escapeHTML(I18n.t("shared.sidebar.journey_label.shelter_setup")))
  end
end
