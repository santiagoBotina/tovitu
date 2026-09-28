require "rails_helper"

# Shelter "Automatic evaluation" settings (REQ-49-11): natural-language policy
# input, proposed-rule review, not-auto-evaluated list, system-rule visibility,
# and owner/administrator authorization (REQ-49-15).
RSpec.describe "Shelter evaluation policies settings", type: :request do
  let(:shelter) { create(:shelter) }
  let(:owner) { create(:user, :verified, :shelter_admin, shelter: shelter) }

  def sign_in(user)
    post session_path(locale: :en), params: { session: { email: user.email, password: "password123" } }
  end

  describe "GET /shelters/:id/policies" do
    it "renders the automatic evaluation area with read-only system rules for an owner" do
      sign_in owner

      get shelter_policies_path(shelter_id: shelter)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("adoptions.evaluation.settings.title"))
      expect(response.body).to include(I18n.t("adoptions.evaluation.settings.system_rules_title"))
      expect(response.body).to include(I18n.t("adoptions.evaluation.rules.account_age_min.label"))
    end

    it "renders the empty state when there are no policies yet" do
      sign_in owner

      get shelter_policies_path(shelter_id: shelter)

      expect(response.body).to include(I18n.t("adoptions.evaluation.settings.no_policies_title"))
    end

    it "renders proposed rules, the not-auto-evaluated list, and the failed list" do
      translated = create(:shelter_evaluation_policy, shelter: shelter, status: "translated",
                        content: "We require a fenced yard")
      create(:shelter_evaluation_rule, policy: translated,
             rule_type: "home_fenced_yard_required", severity: "red", enabled: false)
      create(:shelter_evaluation_policy, shelter: shelter, status: "not_evaluated",
             content: "No small children in the home", reason: "unsupported_data")
      create(:shelter_evaluation_policy, shelter: shelter, status: "failed",
             content: "A policy that failed to translate")

      sign_in owner

      get shelter_policies_path(shelter_id: shelter)

      expect(response.body).to include(I18n.t("adoptions.evaluation.settings.translated_title"))
      expect(response.body).to include("We require a fenced yard")
      expect(response.body).to include(I18n.t("adoptions.evaluation.settings.not_evaluated_title"))
      expect(response.body).to include("No small children in the home")
      expect(response.body).to include(CGI.escapeHTML(I18n.t("adoptions.evaluation.settings.reasons.unsupported_data")))
      expect(response.body).to include(I18n.t("adoptions.evaluation.settings.failed_title"))
      expect(response.body).to include("A policy that failed to translate")
    end

    it "renders the not-auto-evaluated reason in Spanish for a Spanish locale" do
      create(:shelter_evaluation_policy, shelter: shelter, status: "not_evaluated",
             content: "Los solicitantes deben vivir en Cali", reason: "unsupported_data")
      sign_in owner

      get shelter_policies_path(shelter_id: shelter, locale: :es)

      expect(response.body).to include(CGI.escapeHTML(I18n.t("adoptions.evaluation.settings.reasons.unsupported_data", locale: :es)))
      expect(response.body).not_to include(I18n.t("adoptions.evaluation.settings.reasons.unsupported_data", locale: :en))
    end
  end

  describe "POST /shelters/:id/policies/add_policy" do
    it "creates policies and translates them into disabled proposed rules" do
      allow(Ai::Provider).to receive(:call).and_return(default_policy_translation_response.to_json)
      sign_in owner

      post add_policy_shelter_policies_path(shelter_id: shelter),
           params: { policy_content: "Applicants must be at least 21 years old\nNo small children in the home" }

      expect(response).to redirect_to(shelter_policies_path(shelter_id: shelter))
      expect(shelter.evaluation_policies.count).to eq(2)
      translated = shelter.evaluation_policies.translated.first
      expect(translated.rules.first.rule_type).to eq("adopter_age_min")
      expect(translated.rules.first).not_to be_enabled
      expect(shelter.evaluation_policies.not_evaluated.first.content).to eq("No small children in the home")
    end

    it "never blocks policy saving when the provider fails (raw text kept, marked failed)" do
      allow(Ai::Provider).to receive(:call).and_raise(Ai::ProviderError, "boom")
      sign_in owner

      post add_policy_shelter_policies_path(shelter_id: shelter),
           params: { policy_content: "We require a fenced yard" }

      expect(response).to redirect_to(shelter_policies_path(shelter_id: shelter))
      policy = shelter.evaluation_policies.first
      expect(policy.content).to eq("We require a fenced yard")
      expect(policy).to be_failed
    end

    it "rejects a blank policy" do
      sign_in owner

      post add_policy_shelter_policies_path(shelter_id: shelter), params: { policy_content: "   " }

      expect(response).to redirect_to(shelter_policies_path(shelter_id: shelter))
      expect(shelter.evaluation_policies.count).to eq(0)
    end

    it "does not allow a staff member to add policies" do
      staff = create(:user, :verified, :shelter_staff_member, shelter: shelter)
      sign_in staff

      post add_policy_shelter_policies_path(shelter_id: shelter),
           params: { policy_content: "Something" }

      expect(response).to redirect_to(root_path)
      expect(shelter.evaluation_policies.count).to eq(0)
    end
  end

  describe "PATCH /shelters/:id/evaluation_rules/:id" do
    let(:policy) { create(:shelter_evaluation_policy, shelter: shelter, status: "translated") }
    let!(:rule) do
      create(:shelter_evaluation_rule, policy: policy, rule_type: "adopter_age_min",
             params: { "years" => 21 }, severity: "red", enabled: false)
    end

    it "enables a rule and updates its severity and parameters" do
      sign_in owner

      patch shelter_evaluation_rule_path(shelter, rule),
            params: { rule: { enabled: "true", severity: "yellow", params: { years: "25" } } }

      expect(response).to redirect_to(shelter_policies_path(shelter_id: shelter))
      rule.reload
      expect(rule).to be_enabled
      expect(rule.severity).to eq("yellow")
      expect(rule.params).to eq({ "years" => 25 })
    end

    it "does not allow a staff member to edit rules" do
      staff = create(:user, :verified, :shelter_staff_member, shelter: shelter)
      sign_in staff

      patch shelter_evaluation_rule_path(shelter, rule), params: { rule: { enabled: "true" } }

      expect(response).to redirect_to(root_path)
      expect(rule.reload).not_to be_enabled
    end
  end

  describe "DELETE /shelters/:id/evaluation_rules/:id" do
    let(:policy) { create(:shelter_evaluation_policy, shelter: shelter, status: "translated") }
    let!(:rule) { create(:shelter_evaluation_rule, policy: policy) }

    it "removes a rule" do
      sign_in owner

      expect {
        delete shelter_evaluation_rule_path(shelter, rule)
      }.to change(ShelterEvaluationRule, :count).by(-1)

      expect(response).to redirect_to(shelter_policies_path(shelter_id: shelter))
    end
  end

  describe "POST /shelters/:id/policies/translate" do
    it "re-translates draft and failed policies" do
      allow(Ai::Provider).to receive(:call).and_return(default_policy_translation_response.to_json)
      failed = create(:shelter_evaluation_policy, shelter: shelter, status: "failed",
                      content: "Applicants must be at least 21 years old")
      sign_in owner

      post translate_shelter_policies_path(shelter_id: shelter)

      expect(response).to redirect_to(shelter_policies_path(shelter_id: shelter))
      failed.reload
      expect(failed).to be_translated
      expect(failed.rules.first.rule_type).to eq("adopter_age_min")
    end
  end
end
