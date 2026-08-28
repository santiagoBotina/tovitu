require "rails_helper"

RSpec.describe Ai::GenerateLifePreview do
  include AiProviderStub

  subject(:service) { described_class.call(pet: pet, personality_spec: personality_spec, adopter_tips: adopter_tips, locale: locale) }

  let(:shelter) { create(:shelter) }
  let(:pet) { create(:pet, shelter: shelter, personality_traits: [ "Friendly", "Energetic" ], description: "A lovely dog") }
  let(:personality_spec) { nil }
  let(:adopter_tips) { nil }
  let(:locale) { "en" }

  before do
    allow(Ai::Provider).to receive(:call).and_return(default_preview_response.to_json)
  end

  describe "#call" do
    context "when AI returns valid JSON" do
      it "returns a successful Result" do
        expect(service).to be_success
      end

      it "returns parsed preview data" do
        data = service.data
        expect(data).to have_key("plan")
        expect(data).to have_key("itinerary")
        expect(data).to have_key("tips")
      end

      it "includes week-by-week plan" do
        expect(service.data["plan"]).to be_an(Array)
        expect(service.data["plan"].first).to have_key("week")
        expect(service.data["plan"].first).to have_key("items")
      end

      it "includes itinerary sections" do
        expect(service.data["itinerary"]).to have_key("daily_routine")
        expect(service.data["itinerary"]).to have_key("feeding_guide")
        expect(service.data["itinerary"]).to have_key("exercise_needs")
        expect(service.data["itinerary"]).to have_key("grooming")
        expect(service.data["itinerary"]).to have_key("vet_schedule")
      end

      it "includes tips categories" do
        expect(service.data["tips"]).to have_key("home_preparation")
        expect(service.data["tips"]).to have_key("supplies")
        expect(service.data["tips"]).to have_key("family_preparation")
        expect(service.data["tips"]).to have_key("lifestyle_adjustments")
        expect(service.data["tips"]).to have_key("training_resources")
      end
    end

    context "locale handling" do
      it "passes the language name into the prompt variables for Spanish" do
        expect(Ai::PromptBuilder).to receive(:call).with(
          prompt_name: "life_preview",
          variables: hash_including(language: "Spanish")
        ).and_return("prompt")

        allow(Ai::Provider).to receive(:call).and_return(default_preview_response.to_json)
        described_class.call(pet: pet, locale: "es")
      end

      it "passes the language name into the prompt variables for English" do
        expect(Ai::PromptBuilder).to receive(:call).with(
          prompt_name: "life_preview",
          variables: hash_including(language: "English")
        ).and_return("prompt")

        allow(Ai::Provider).to receive(:call).and_return(default_preview_response.to_json)
        described_class.call(pet: pet, locale: "en")
      end

      it "interpolates the language into the system prompt" do
        captured = nil
        allow(Ai::Provider).to receive(:call) do |prompt:, system_prompt:|
          captured = system_prompt
          default_preview_response.to_json
        end

        described_class.call(pet: pet, locale: "es")

        expect(captured).to include("entirely in Spanish")
        expect(captured).to include("Never mix languages")
      end

      it "stores the locale in the returned data" do
        data = described_class.call(pet: pet, locale: "es").data
        expect(data["locale"]).to eq("es")
      end

      it "falls back to the default locale for unsupported values" do
        data = described_class.call(pet: pet, locale: "fr").data
        expect(data["locale"]).to eq(I18n.default_locale.to_s)
      end

      it "falls back to the active I18n locale when none is provided" do
        I18n.with_locale(:es) do
          data = described_class.call(pet: pet).data
          expect(data["locale"]).to eq("es")
        end
      end
    end

    context "when personality_spec is provided" do
      let(:personality_spec) { "Very shy around new people but warms up quickly. Loves squeaky toys." }

      it "includes the personality spec in the prompt variables" do
        expect(Ai::PromptBuilder).to receive(:call).with(
          prompt_name: "life_preview",
          variables: hash_including(personality_spec: personality_spec)
        ).and_return("prompt")

        allow(Ai::Provider).to receive(:call).and_return(default_preview_response.to_json)
        service
      end
    end

    context "when personality_spec is nil" do
      it "falls back to default message" do
        expect(Ai::PromptBuilder).to receive(:call).with(
          prompt_name: "life_preview",
          variables: hash_including(personality_spec: "Not provided by shelter.")
        ).and_return("prompt")

        allow(Ai::Provider).to receive(:call).and_return(default_preview_response.to_json)
        service
      end
    end

    context "when plan is a Hash instead of Array" do
      let(:hash_plan_response) do
        default_preview_response.merge(
          "plan" => {
            "Week 0 (Pre-Adoption)" => [ "Prepare supplies", "Pet-proof your home" ],
            "Week 1 (Arrival)" => [ "Decompression protocol", "Establish routine" ]
          }
        )
      end

      before do
        allow(Ai::Provider).to receive(:call).and_return(hash_plan_response.to_json)
      end

      it "normalizes plan to an array" do
        expect(service.data["plan"]).to be_an(Array)
        expect(service.data["plan"].first).to have_key("week")
        expect(service.data["plan"].first).to have_key("items")
      end

      it "converts hash keys to week values" do
        weeks = service.data["plan"].map { |w| w["week"] }
        expect(weeks).to include("Week 0 (Pre-Adoption)")
        expect(weeks).to include("Week 1 (Arrival)")
      end
    end

    context "when itinerary is missing keys" do
      let(:partial_itinerary_response) do
        default_preview_response.merge(
          "itinerary" => { "daily_routine" => "Morning walk" }
        )
      end

      before do
        allow(Ai::Provider).to receive(:call).and_return(partial_itinerary_response.to_json)
      end

      it "fills missing keys with empty strings" do
        expect(service.data["itinerary"]["feeding_guide"]).to eq("")
        expect(service.data["itinerary"]["exercise_needs"]).to eq("")
        expect(service.data["itinerary"]["daily_routine"]).to eq("Morning walk")
      end
    end

    context "when AI provider fails" do
      before do
        allow(Ai::Provider).to receive(:call).and_raise(Ai::ProviderError, "API error")
      end

      it "returns a failed Result" do
        expect(service).to be_failure
      end

      it "includes error message" do
        expect(service.errors).to include("API error")
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
  end
end
