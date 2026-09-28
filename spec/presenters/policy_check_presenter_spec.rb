require "rails_helper"

RSpec.describe PolicyCheckPresenter do
  let(:shelter) { create(:shelter) }
  let(:adopter) { create(:user, :verified, :onboarding_completed) }
  let(:request) { create(:adoption_request, adopter: adopter, shelter: shelter) }

  def build_evaluation(verdict:, summary:, rules:)
    create(:adoption_request_evaluation, adoption_request: request,
           verdict: verdict, summary: summary, rules: rules)
  end

  describe "state" do
    it "is ready when an evaluation exists" do
      build_evaluation(verdict: "pre_accept", summary: {}, rules: [])
      expect(described_class.new(request: request)).to be_ready
    end

    it "is evaluating for a fresh request with no evaluation" do
      presenter = described_class.new(request: request)
      expect(presenter.evaluating?).to be true
    end

    it "is empty for an old request with no evaluation" do
      request.update_column(:created_at, 2.hours.ago)
      presenter = described_class.new(request: request)
      expect(presenter.empty?).to be true
    end
  end

  describe "#summary" do
    it "resolves the stored summary key and params" do
      build_evaluation(verdict: "needs_review",
        summary: { "key" => "adoptions.evaluation.summaries.needs_review",
                   "params" => { "failed_count" => 1, "unverifiable_count" => 2 } },
        rules: [])
      presenter = described_class.new(request: request)
      expect(presenter.summary).to include("1 rule(s) didn't pass")
    end
  end

  describe "#rules" do
    it "localizes pet-experience evidence from the onboarding option keys" do
      rules = [ {
        "rule" => "pet_experience_min", "severity" => "yellow", "source" => "shelter",
        "passed" => false, "unevaluable" => false,
        "evidence" => { "key" => "adoptions.evaluation.evidence.pet_experience",
                        "params" => { "level" => "some_experience" } },
        "policy_text" => "We prefer experienced adopters",
        "params" => { "level" => "some_experience" },
        "label_key" => "adoptions.evaluation.rules.pet_experience_min.label"
      } ]
      build_evaluation(verdict: "needs_review", summary: {}, rules: rules)

      rule = described_class.new(request: request).rules.first
      expect(rule[:state]).to eq("failed")
      expect(rule[:source_label]).to eq(I18n.t("adoptions.evaluation.sources.shelter"))
      expect(rule[:evidence]).to include(I18n.t("onboarding.individual.questions.q4.options.some_experience"))
      expect(rule[:policy_text]).to eq("We prefer experienced adopters")
    end

    it "labels unevaluable rules as 'couldn't verify'" do
      rules = [ {
        "rule" => "adopter_age_min", "severity" => "red", "source" => "system",
        "passed" => nil, "unevaluable" => true,
        "evidence" => { "key" => "adoptions.evaluation.evidence.adopter_age_missing" },
        "policy_text" => nil, "params" => { "years" => 18 },
        "label_key" => "adoptions.evaluation.rules.adopter_age_min.label"
      } ]
      build_evaluation(verdict: "needs_review", summary: {}, rules: rules)

      rule = described_class.new(request: request).rules.first
      expect(rule[:state]).to eq("unevaluable")
      expect(rule[:state_label]).to eq(I18n.t("adoptions.evaluation.states.unevaluable"))
    end
  end

  describe "verdict presentation" do
    it "returns the localized verdict label and danger badge for high concern" do
      build_evaluation(verdict: "high_concern", summary: {}, rules: [])
      presenter = described_class.new(request: request)
      expect(presenter.verdict_label).to eq(I18n.t("adoptions.evaluation.verdicts.high_concern"))
      expect(presenter.verdict_badge_classes).to include("bg-danger/10")
      expect(presenter.verdict_dot_classes).to include("bg-danger")
    end
  end
end
