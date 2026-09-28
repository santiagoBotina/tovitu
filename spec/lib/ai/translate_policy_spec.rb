require "rails_helper"

RSpec.describe Ai::TranslatePolicy do
  describe "#call" do
    it "translates policies into structured rules from the vocabulary" do
      allow(Ai::Provider).to receive(:call)
        .and_return(default_policy_translation_response.to_json)

      result = described_class.call(policies: [
        "Applicants must be at least 21 years old",
        "We prefer adopters with a fenced yard",
        "No small children in the home"
      ])

      expect(result).to be_success
      translated = result.data.select { |item| item[:status] == "translated" }
      expect(translated.length).to eq(2)
      expect(translated.first[:rules].first[:rule_type]).to eq("adopter_age_min")
      expect(translated.first[:rules].first[:params]).to eq({ "years" => 21 })
      expect(translated.first[:rules].first[:severity]).to eq("red")
    end

    it "marks untranslatable statements as not_evaluated with a localized reason" do
      payload = [
        { "statement" => "No small children in the home", "status" => "not_evaluated",
          "rules" => [], "reason" => "unsupported_data" }
      ]
      allow(Ai::Provider).to receive(:call).and_return(payload.to_json)

      result = described_class.call(policies: [ "No small children in the home" ])

      expect(result).to be_success
      item = result.data.first
      expect(item[:status]).to eq("not_evaluated")
      expect(item[:rules]).to be_empty
      expect(item[:reason]).to eq("unsupported_data")
    end

    it "defaults to unsupported_data when the reason is unknown" do
      payload = [
        { "statement" => "Something odd", "status" => "not_evaluated",
          "rules" => [], "reason" => "bogus_reason" }
      ]
      allow(Ai::Provider).to receive(:call).and_return(payload.to_json)

      result = described_class.call(policies: [ "Something odd" ])

      expect(result.data.first[:reason]).to eq("unsupported_data")
    end

    it "treats an unknown rule type as not_evaluated (honesty, never fabricate)" do
      payload = [
        { "statement" => "We require a unicorn", "status" => "translated",
          "rules" => [ { "rule_type" => "unicorn_required", "params" => {}, "severity" => "red" } ] }
      ]
      allow(Ai::Provider).to receive(:call).and_return(payload.to_json)

      result = described_class.call(policies: [ "We require a unicorn" ])

      item = result.data.first
      expect(item[:status]).to eq("not_evaluated")
      expect(item[:rules]).to be_empty
    end

    it "normalizes invalid params and severities against the catalog" do
      payload = [
        { "statement" => "At least 21", "status" => "translated",
          "rules" => [ { "rule_type" => "adopter_age_min",
                         "params" => { "years" => "abc", "bogus" => 1 },
                         "severity" => "purple" } ] }
      ]
      allow(Ai::Provider).to receive(:call).and_return(payload.to_json)

      result = described_class.call(policies: [ "At least 21" ])

      rule = result.data.first[:rules].first
      expect(rule[:params]).to eq({})
      expect(rule[:severity]).to eq("yellow")
    end

    it "returns a failure result when the response is not an object or array" do
      allow(Ai::Provider).to receive(:call).and_return({ "foo" => 1 }.to_json)

      result = described_class.call(policies: [ "Something" ])

      expect(result).to be_failure
    end

    it "returns a failure result on provider error" do
      allow(Ai::Provider).to receive(:call).and_raise(Ai::ProviderError, "boom")

      result = described_class.call(policies: [ "Something" ])

      expect(result).to be_failure
    end

    it "returns a failure result on unparseable JSON" do
      allow(Ai::Provider).to receive(:call).and_return("not json")

      result = described_class.call(policies: [ "Something" ])

      expect(result).to be_failure
    end

    it "returns an empty success when there are no policies" do
      result = described_class.call(policies: [])

      expect(result).to be_success
      expect(result.data).to eq([])
    end
  end
end
