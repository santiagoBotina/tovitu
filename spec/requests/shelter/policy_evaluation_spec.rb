require "rails_helper"

# Request-level coverage for the advisory "Policy check" evaluation
# (REQ-49-8, REQ-49-9, REQ-49-10, REQ-49-14) plus the responsible-party-only
# authorization boundary (REQ-49-15).
RSpec.describe "Adoption policy evaluation (request surfaces)", type: :request do
  let(:shelter) { create(:shelter) }
  let(:staff) { create(:user, :verified, :shelter_admin, shelter: shelter) }
  let(:pet) { create(:pet, shelter: shelter) }
  let(:adopter) do
    create(:user, :verified, :onboarding_completed,
           created_at: 30.days.ago, onboarding_completed_at: 30.days.ago)
  end
  let!(:profile) do
    create(:individual_profile, user: adopter, pet_experience: "some_experience",
      daily_time_available: "2_to_4h", personality: "calm_thoughtful",
      activity_level: "active", adoption_priority: "companion",
      date_of_birth: 30.years.ago.to_date, home_environment: "house_with_fenced_yard",
      other_pets: "no_other_pets")
  end
  let(:request) { create(:adoption_request, pet: pet, adopter: adopter, shelter: shelter) }

  def sign_in(user, locale: :en)
    post session_path(locale: locale), params: { session: { email: user.email, password: "password123" } }
  end

  describe "evaluation enqueued on request creation (REQ-49-1)" do
    it "enqueues the evaluation job on submit" do
      expect {
        Adoptions::SubmitRequest.call(adopter: adopter, pet: pet)
      }.to have_enqueued_job(Adoptions::EvaluateRequestJob)
    end

    it "does not run the evaluation synchronously during submission (adopter confirmation unaffected)" do
      expect(Adoptions::EvaluateRequest).not_to receive(:call)
      Adoptions::SubmitRequest.call(adopter: adopter, pet: pet)
    end
  end

  describe "shelter detail page" do
    before do
      sign_in staff
      Adoptions::EvaluateRequest.call(request: request)
    end

    it "renders the policy check section with a verdict badge and summary" do
      get shelter_adoption_request_path(request)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("adoptions.evaluation.card.title"))
      expect(response.body).to include(I18n.t("adoptions.evaluation.verdicts.pre_accept"))
      expect(response.body).to include("This request passed the policy check")
    end

    it "renders the rule-by-rule breakdown with evidence and source" do
      get shelter_adoption_request_path(request)

      expect(response.body).to include(I18n.t("adoptions.evaluation.rules.email_verified.label"))
      expect(response.body).to include(I18n.t("adoptions.evaluation.evidence.email_verified"))
      expect(response.body).to include(I18n.t("adoptions.evaluation.sources.system"))
    end

    it "renders the re-run action for authorized staff" do
      get shelter_adoption_request_path(request)

      expect(response.body).to include(I18n.t("adoptions.evaluation.card.re_run"))
      expect(response.body).to include(re_evaluate_shelter_adoption_request_path(request))
    end

    it "never changes the request status after evaluation" do
      expect(request.reload.status).to eq("pending")
    end
  end

  describe "re-run evaluation (REQ-49-14)" do
    it "recomputes against current signals and replaces the snapshot" do
      sign_in staff
      Adoptions::EvaluateRequest.call(request: request)
      adopter.update!(created_at: 1.day.ago)

      expect {
        post re_evaluate_shelter_adoption_request_path(request)
      }.not_to change { request.reload.status }

      expect(response).to redirect_to(shelter_adoption_request_path(request))
      snapshot = request.reload.policy_evaluation
      expect(snapshot).to be_high_concern
    end

    it "does not allow a non-member to re-run" do
      outsider = create(:user, :verified, :shelter_admin, shelter: create(:shelter))
      sign_in outsider

      post re_evaluate_shelter_adoption_request_path(request)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "shelter request list chip (REQ-49-10)" do
    it "renders a verdict chip next to each request" do
      Adoptions::EvaluateRequest.call(request: request)
      sign_in staff

      get shelter_adoption_requests_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("adoptions.evaluation.verdicts.pre_accept"))
    end
  end

  describe "individual publisher detail page (REQ-49-9)" do
    let(:publisher) { create(:user, :verified, :onboarding_completed) }
    let(:publisher_pet) { create(:pet, :individual_listed, publisher: publisher) }
    let(:publisher_request) do
      create(:adoption_request, pet: publisher_pet, adopter: adopter, shelter: nil)
    end

    before do
      Adoptions::EvaluateRequest.call(request: publisher_request)
      sign_in publisher
    end

    it "renders the same policy check section (system rules only)" do
      get my_adoption_request_path(publisher_request)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("adoptions.evaluation.card.title"))
      expect(response.body).to include(I18n.t("adoptions.evaluation.verdicts.pre_accept"))
    end

    it "renders the re-run action for the publisher" do
      get my_adoption_request_path(publisher_request)

      expect(response.body).to include(re_evaluate_my_adoption_request_path(publisher_request))
    end
  end

  describe "adopter never sees the breakdown (REQ-49-15)" do
    it "does not render the policy check section on the adopter's own request page" do
      sign_in adopter

      get adoption_request_path(request)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(I18n.t("adoptions.evaluation.card.title"))
      expect(response.body).not_to include(I18n.t("adoptions.evaluation.rules.email_verified.label"))
    end
  end

  describe "localization (AC-49-17)" do
    it "renders the policy check card in Spanish" do
      sign_in staff, locale: :es
      Adoptions::EvaluateRequest.call(request: request)

      get shelter_adoption_request_path(request, locale: :es)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("adoptions.evaluation.card.title", locale: :es))
      expect(response.body).to include(I18n.t("adoptions.evaluation.verdicts.pre_accept", locale: :es))
    end
  end

  describe "evaluating / empty states" do
    it "renders a neutral empty state when no evaluation exists yet and the request is old" do
      sign_in staff
      request.update_column(:created_at, 2.hours.ago)

      get shelter_adoption_request_path(request)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("adoptions.evaluation.card.empty_state"))
    end

    it "renders the non-blocking evaluating state for a fresh request" do
      sign_in staff
      request.update_column(:created_at, Time.current)

      get shelter_adoption_request_path(request)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("adoptions.evaluation.card.evaluating"))
    end
  end
end
