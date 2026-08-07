require "rails_helper"

RSpec.describe Ai::Adopter::InsightAnalyzer do
  include AiProviderStub

  subject(:service) { described_class.call(adopter: adopter, signals: signals) }

  let(:adopter) { create(:user, :verified, :onboarding_completed) }
  let(:profile) do
    create(:individual_profile,
      user: adopter,
      activity_level: "active",
      personality: "adventurous_energetic",
      adoption_priority: "I want an adventure buddy.")
  end
  let(:signals) { Ai::Adopter::SignalCollector.call(adopter: adopter) }

  before do
    profile
    allow(Ai::Provider).to receive(:call).and_return(default_adopter_insight_response.to_json)
  end

  describe "#call" do
    context "when AI returns valid JSON" do
      it "returns a successful Result" do
        expect(service).to be_success
      end

      it "normalizes the archetype to a valid key" do
        expect(service.data[:archetype]).to eq("active_outdoors_partner")
      end

      it "keeps the self-reported personality alongside the archetype" do
        expect(service.data[:self_reported_personality]).to eq("adventurous_energetic")
      end

      it "normalizes commitment signals" do
        signals_data = service.data[:commitment_signals]
        expect(signals_data).to be_an(Array)
        expect(signals_data.first).to include(
          :label, :observation, :kind
        )
        expect(signals_data.first[:kind]).to eq("positive")
      end

      it "normalizes confidence" do
        expect(service.data[:confidence]).to eq("medium")
      end

      it "builds provenance from the actual evidence sources" do
        provenance = service.data[:provenance]
        expect(provenance[:sources]).to include("onboarding answers")
        expect(provenance[:activity_up_to]).to eq(Date.current.iso8601)
        expect(provenance[:based_on]).to eq("onboarding answers, 2 saved pets, 1 request")
      end
    end

    context "when the response has an unknown archetype" do
      before do
        allow(Ai::Provider).to receive(:call).and_return(
          default_adopter_insight_response.merge("archetype" => "totally_made_up").to_json
        )
      end

      it "drops the invalid archetype instead of trusting the model" do
        expect(service.data[:archetype]).to be_nil
      end
    end

    context "when the archetype value is not a string (malformed AI output)" do
      before do
        allow(Ai::Provider).to receive(:call).and_return(
          default_adopter_insight_response.merge("archetype" => 123).to_json
        )
      end

      it "does not crash and treats the archetype as unknown" do
        expect { service }.not_to raise_error
        expect(service).to be_success
        expect(service.data[:archetype]).to be_nil
      end
    end

    context "when the response is not a JSON object" do
      before do
        allow(Ai::Provider).to receive(:call).and_return("[1,2,3]")
      end

      it "returns a failed Result instead of crashing" do
        expect { service }.not_to raise_error
        expect(service).to be_failure
        expect(service.errors).to include(/Unexpected AI response shape/)
      end
    end

    context "when commitment signals are malformed" do
      before do
        allow(Ai::Provider).to receive(:call).and_return(
          default_adopter_insight_response.merge(
            "commitment_signals" => [
              { "observation" => "Kept in touch with the shelter." },
              { "label" => "empty", "observation" => "", "kind" => "positive" },
              "not a hash"
            ]
          ).to_json
        )
      end

      it "drops signals without observations" do
        expect(service.data[:commitment_signals].size).to eq(1)
      end
    end

    context "when AI provider fails" do
      before do
        allow(Ai::Provider).to receive(:call).and_raise(Ai::ProviderError, "API error")
      end

      it "returns a failed Result" do
        expect(service).to be_failure
      end
    end

    context "when AI returns invalid JSON" do
      before do
        allow(Ai::Provider).to receive(:call).and_return("not json")
      end

      it "returns a failed Result" do
        expect(service).to be_failure
      end
    end

    context "PII safety" do
      it "builds the prompt from evidence that never contains the adopter's name or email" do
        captured = nil
        allow(Ai::PromptBuilder).to receive(:call).and_wrap_original do |original, **kwargs|
          captured = kwargs[:variables]
          original.call(**kwargs)
        end

        service

        prompt_evidence = captured[:adopter_evidence].to_s
        expect(prompt_evidence).not_to include(adopter.name)
        expect(prompt_evidence).not_to include(adopter.email)
      end
    end
  end
end
