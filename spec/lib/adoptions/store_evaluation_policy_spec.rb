require "rails_helper"

RSpec.describe Adoptions::StoreEvaluationPolicy do
  let(:shelter) { create(:shelter) }

  describe "#call" do
    it "creates a policy from a natural-language statement" do
      result = described_class.call(shelter: shelter, content: "Applicants must have a fenced yard")

      expect(result).to be_success
      expect(result.data).to be_a(ShelterEvaluationPolicy)
      expect(result.data.content).to eq("Applicants must have a fenced yard")
      expect(result.data).to be_draft
    end

    it "reuses an existing policy with the same content" do
      policy = create(:shelter_evaluation_policy, shelter: shelter, status: "translated",
                      content: "Applicants must have a fenced yard")

      result = described_class.call(shelter: shelter, content: policy.content)

      expect(result.data.id).to eq(policy.id)
      expect(result.data).to be_translated
    end

    it "returns failure for a blank statement" do
      result = described_class.call(shelter: shelter, content: "   ")

      expect(result).to be_failure
    end
  end
end
