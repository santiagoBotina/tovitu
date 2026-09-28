require "rails_helper"

RSpec.describe Adoptions::TranslatePolicies do
  let(:shelter) { create(:shelter) }

  describe "#call" do
    it "applies translated rules to policies as disabled, awaiting shelter review" do
      allow(Ai::Provider).to receive(:call)
        .and_return(default_policy_translation_response.to_json)
      policy = create(:shelter_evaluation_policy, shelter: shelter, status: "draft",
                      content: "Applicants must be at least 21 years old")

      result = described_class.call(shelter: shelter, policies: [ policy ])

      expect(result).to be_success
      policy.reload
      expect(policy).to be_translated
      expect(policy.rules.length).to eq(1)
      expect(policy.rules.first.rule_type).to eq("adopter_age_min")
      expect(policy.rules.first.severity).to eq("red")
      expect(policy.rules.first).not_to be_enabled
    end

    it "marks untranslatable policies as not_evaluated and keeps the raw text" do
      allow(Ai::Provider).to receive(:call)
        .and_return(default_policy_translation_response.to_json)
      policy = create(:shelter_evaluation_policy, shelter: shelter, status: "draft",
                      content: "No small children in the home")

      described_class.call(shelter: shelter, policies: [ policy ])

      policy.reload
      expect(policy).to be_not_evaluated
      expect(policy.rules).to be_empty
      expect(policy.content).to eq("No small children in the home")
      expect(policy.reason).to eq("unsupported_data")
    end

    it "does not delete the policy or its text when the provider fails" do
      allow(Ai::Provider).to receive(:call).and_raise(Ai::ProviderError, "boom")
      policy = create(:shelter_evaluation_policy, shelter: shelter, status: "draft",
                      content: "Some requirement")

      result = described_class.call(shelter: shelter, policies: [ policy ])

      expect(result).to be_failure
      expect(policy.reload.content).to eq("Some requirement")
      expect(ShelterEvaluationPolicy.find_by(id: policy.id)).to be_present
    end

    it "retries the translation up to MAX_ATTEMPTS before giving up" do
      allow(Ai::TranslatePolicy).to receive(:call).and_return(Result.failure([ "boom" ]))
      policy = create(:shelter_evaluation_policy, shelter: shelter, status: "draft",
                      content: "Some requirement")

      result = described_class.call(shelter: shelter, policies: [ policy ])

      expect(result).to be_failure
      expect(Ai::TranslatePolicy).to have_received(:call).exactly(described_class::MAX_ATTEMPTS).times
    end

    it "succeeds on a later attempt after transient failures (automatic retry)" do
      attempts = 0
      allow(Ai::TranslatePolicy).to receive(:call) do |policies:|
        attempts += 1
        if attempts <= 2
          Result.failure([ "transient" ])
        else
          Result.success([ { statement: policies.first, status: "translated",
                             rules: [ { rule_type: "adopter_age_min", params: { "years" => 21 }, severity: "red" } ],
                             reason: nil } ])
        end
      end
      policy = create(:shelter_evaluation_policy, shelter: shelter, status: "draft",
                      content: "Applicants must be at least 21 years old")

      result = described_class.call(shelter: shelter, policies: [ policy ])

      expect(result).to be_success
      expect(policy.reload).to be_translated
      expect(policy.rules.first.rule_type).to eq("adopter_age_min")
    end
  end
end
