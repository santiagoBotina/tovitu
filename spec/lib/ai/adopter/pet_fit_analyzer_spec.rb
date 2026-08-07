require "rails_helper"

RSpec.describe Ai::Adopter::PetFitAnalyzer do
  include AiProviderStub

  subject(:service) do
    described_class.call(request: request, signals: signals, insight: insight_data)
  end

  let(:shelter) { create(:shelter) }
  let(:pet) do
    create(:pet,
      shelter: shelter,
      species: "dog",
      size: "large",
      personality_traits: [ "Energetic", "Friendly" ],
      good_with_children: true,
      description: "Loves long hikes and belly rubs.")
  end
  let(:adopter) { create(:user, :verified, :onboarding_completed) }
  let(:request) do
    create(:adoption_request,
      adopter: adopter,
      pet: pet,
      shelter: shelter,
      additional_answers: {
        interest_reason: "I hike every weekend!",
        home_description: "A house with a fenced yard."
      })
  end
  let(:signals) { Ai::Adopter::SignalCollector.call(adopter: adopter) }
  let(:insight_data) { default_adopter_insight_response }

  before do
    allow(Ai::Provider).to receive(:call).and_return(default_pet_fit_response.to_json)
  end

  describe "#call" do
    context "when AI returns valid JSON" do
      it "returns a successful Result" do
        expect(service).to be_success
      end

      it "normalizes all five fit dimensions" do
        indicators = service.data[:fit_indicators]
        expect(indicators.keys).to match_array(%w[energy time experience home_space household])
        expect(indicators["energy"]).to eq(status: "strong_fit", evidence: "They report an active lifestyle and save high-energy dogs.")
      end

      it "defaults missing dimensions to unknown" do
        allow(Ai::Provider).to receive(:call).and_return(
          default_pet_fit_response.merge("fit_indicators" => { "energy" => { "status" => "strong_fit" } }).to_json
        )
        indicators = service.data[:fit_indicators]
        expect(indicators["time"][:status]).to eq("unknown")
        expect(indicators["household"][:status]).to eq("unknown")
      end

      it "normalizes verification questions" do
        expect(service.data[:verification_questions]).to eq(
          [ "Have you owned a dog before?", "Who is home during the day?" ]
        )
      end

      it "normalizes confidence" do
        expect(service.data[:confidence]).to eq("medium")
      end
    end

    context "when the model returns an invalid status" do
      before do
        response = default_pet_fit_response
        response["fit_indicators"]["energy"]["status"] = "perfect"
        allow(Ai::Provider).to receive(:call).and_return(response.to_json)
      end

      it "coerces it to unknown" do
        expect(service.data[:fit_indicators]["energy"][:status]).to eq("unknown")
      end
    end

    context "PII safety" do
      it "redacts emails and phones from request answers before the prompt" do
        request.update!(additional_answers: {
          something_else: "Call me at 555-987-6543 or email me@here.com"
        })

        captured = nil
        allow(Ai::PromptBuilder).to receive(:call).and_wrap_original do |original, **kwargs|
          captured = kwargs[:variables]
          original.call(**kwargs)
        end

        service

        answers_json = captured[:request_answers].to_s
        expect(answers_json).not_to include("555-987-6543")
        expect(answers_json).not_to include("me@here.com")
        expect(answers_json).to include("[email]")
      end

      it "never includes the adopter's name or email in the prompt variables" do
        captured = nil
        allow(Ai::PromptBuilder).to receive(:call).and_wrap_original do |original, **kwargs|
          captured = kwargs[:variables]
          original.call(**kwargs)
        end

        service

        combined = captured.values.join
        expect(combined).not_to include(adopter.name)
        expect(combined).not_to include(adopter.email)
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

    context "when verification questions contain non-string values" do
      before do
        response = default_pet_fit_response.merge(
          "verification_questions" => [ "Have you owned a dog?", { "bad" => "shape" }, 123 ]
        )
        allow(Ai::Provider).to receive(:call).and_return(response.to_json)
      end

      it "keeps only string questions" do
        expect(service).to be_success
        expect(service.data[:verification_questions]).to eq([ "Have you owned a dog?" ])
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
  end
end
