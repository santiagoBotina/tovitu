require "rails_helper"

RSpec.describe Ai::ExtractSearchIntent do
  subject(:service) { described_class.call(phrase: phrase, locale: locale) }

  let(:locale) { "en" }
  let(:canned_response) do
    {
      "species" => [ "dog" ],
      "size" => [],
      "age_category" => [],
      "sex" => [],
      "temperament" => [ "calm" ],
      "living_situation" => [ "apartment" ],
      "energy_level" => [],
      "keywords" => [ "calm dog", "apartment" ],
      "understood" => [ "A calm dog", "Lives in an apartment" ],
      "valid" => true
    }
  end

  before do
    allow(Ai::Provider).to receive(:call).and_return(canned_response.to_json)
  end

  describe "#call" do
    context "with a dog phrase" do
      let(:phrase) { "I want a calm dog for my apartment" }
      let(:canned_response) do
        {
          "species" => [ "dog" ],
          "size" => [],
          "age_category" => [],
          "sex" => [],
          "temperament" => [ "calm" ],
          "living_situation" => [ "apartment" ],
          "energy_level" => [],
          "keywords" => [ "calm dog", "apartment" ],
          "understood" => [ "A calm dog", "Lives in an apartment" ],
          "valid" => true
        }
      end

      it "returns a successful Result" do
        expect(service).to be_success
      end

      it "extracts the species" do
        expect(service.data["species"]).to eq([ "dog" ])
      end

      it "extracts temperament and living situation" do
        expect(service.data["temperament"]).to include("calm")
        expect(service.data["living_situation"]).to include("apartment")
      end

      it "keeps full-phrase keywords" do
        expect(service.data["keywords"]).to include("calm dog")
      end

      it "is valid" do
        expect(service.data["valid"]).to be true
      end
    end

    context "with a rabbit phrase" do
      let(:phrase) { "I want a rabbit for a quiet home" }
      let(:canned_response) do
        {
          "species" => [ "rabbit" ],
          "size" => [],
          "age_category" => [],
          "sex" => [],
          "temperament" => [ "quiet" ],
          "living_situation" => [],
          "energy_level" => [],
          "keywords" => [ "rabbit", "quiet home" ],
          "understood" => [ "A rabbit", "For a quiet home" ],
          "valid" => true
        }
      end

      it "extracts rabbit species, never dog/cat" do
        expect(service.data["species"]).to eq([ "rabbit" ])
      end
    end

    context "with a mixed-language Spanish phrase" do
      let(:phrase) { "Quiero un perro tranquilo que pueda vivir en apartamento" }
      let(:locale) { "es" }
      let(:canned_response) do
        {
          "species" => [ "dog" ],
          "size" => [],
          "age_category" => [],
          "sex" => [],
          "temperament" => [ "tranquilo" ],
          "living_situation" => [ "apartamento" ],
          "energy_level" => [],
          "keywords" => [ "perro tranquilo", "apartamento" ],
          "understood" => [ "Un perro tranquilo", "Vive en un apartamento" ],
          "valid" => true
        }
      end

      it "passes the Spanish language name and phrase to the prompt" do
        expect(Ai::PromptBuilder).to receive(:call).with(
          prompt_name: "search_intent",
          variables: hash_including(language: "Spanish", phrase: phrase)
        ).and_return("prompt")

        service
      end

      it "extracts the intent" do
        expect(service.data["species"]).to eq([ "dog" ])
      end

      it "builds localized understood labels from the structured fields" do
        expect(service.data["understood"]).to eq([ "Perro", "tranquilo", "apartamento" ])
      end

      it "renders understood labels in the active locale even when the model returns English" do
        english_labels = canned_response.merge("understood" => [ "A calm dog", "Lives in an apartment" ])
        allow(Ai::Provider).to receive(:call).and_return(english_labels.to_json)

        expect(service.data["understood"]).to eq([ "Perro", "tranquilo", "apartamento" ])
        expect(service.data["understood"]).not_to include("A calm dog")
      end
    end

    context "with an empty phrase" do
      let(:phrase) { "" }

      it "returns a successful Result with valid false" do
        expect(service).to be_success
        expect(service.data["valid"]).to be false
      end

      it "returns empty arrays" do
        expect(service.data["species"]).to eq([])
        expect(service.data["keywords"]).to eq([])
        expect(service.data["understood"]).to eq([])
      end

      it "does not call the AI provider" do
        expect(Ai::Provider).not_to receive(:call)
        service
      end
    end

    context "with a whitespace-only phrase" do
      let(:phrase) { "   \n\t  " }

      it "returns a successful Result with valid false" do
        expect(service).to be_success
        expect(service.data["valid"]).to be false
      end

      it "does not call the AI provider" do
        expect(Ai::Provider).not_to receive(:call)
        service
      end
    end

    context "with a very long phrase" do
      let(:phrase) { "I want a calm dog " * 30 } # 540 chars

      it "truncates the phrase to the maximum length before sending it to the provider" do
        captured = nil
        allow(Ai::Provider).to receive(:call) do |prompt:, system_prompt:|
          captured = prompt
          canned_response.to_json
        end

        service

        sent_phrase = captured[/\*\*Phrase:\*\* (.+?)\n\nReturn/, 1]
        expect(sent_phrase).to end_with("…")
        expect(sent_phrase.length).to eq(Ai::ExtractSearchIntent::MAX_PHRASE_LENGTH + 1)
        expect(captured).not_to include("I want a calm dog " * 30)
      end

      it "still returns a successful Result" do
        expect(service).to be_success
      end
    end

    context "with PII in the phrase" do
      let(:phrase) { "I want a dog, call me at 555-123-4567 or email me@example.com" }

      it "strips emails and phone numbers before the phrase reaches the provider" do
        captured = nil
        allow(Ai::Provider).to receive(:call) do |prompt:, system_prompt:|
          captured = prompt
          canned_response.to_json
        end

        service

        expect(captured).not_to include("me@example.com")
        expect(captured).not_to include("555-123-4567")
        expect(captured).to include("[email]")
        expect(captured).to include("[phone]")
      end
    end

    context "with gibberish" do
      let(:phrase) { "asdf qwerty 12345" }
      let(:canned_response) do
        {
          "species" => [], "size" => [], "age_category" => [], "sex" => [],
          "temperament" => [], "living_situation" => [], "energy_level" => [],
          "keywords" => [], "understood" => [], "valid" => false
        }
      end

      it "returns valid false" do
        expect(service.data["valid"]).to be false
      end
    end

    context "when the model returns valid true but empty arrays" do
      let(:phrase) { "hello there" }
      let(:canned_response) do
        {
          "species" => [], "size" => [], "age_category" => [], "sex" => [],
          "temperament" => [], "living_situation" => [], "energy_level" => [],
          "keywords" => [], "understood" => [], "valid" => true
        }
      end

      it "treats the intent as invalid" do
        expect(service.data["valid"]).to be false
      end
    end

    context "when the model returns an out-of-set species" do
      let(:phrase) { "I want a ferret" }
      let(:canned_response) do
        {
          "species" => [ "ferret" ],
          "size" => [],
          "age_category" => [],
          "sex" => [],
          "temperament" => [],
          "living_situation" => [],
          "energy_level" => [],
          "keywords" => [ "ferret" ],
          "understood" => [ "A ferret" ],
          "valid" => true
        }
      end

      it "drops the out-of-set species instead of guessing dog/cat" do
        expect(service.data["species"]).to eq([])
      end
    end

    context "when the AI provider fails" do
      let(:phrase) { "a calm dog" }

      before do
        allow(Ai::Provider).to receive(:call).and_raise(Ai::ProviderError, "API error")
      end

      it "returns a failed Result" do
        expect(service).to be_failure
      end

      it "includes the error message" do
        expect(service.errors).to include("API error")
      end
    end

    context "when the AI returns invalid JSON" do
      let(:phrase) { "a calm dog" }

      before do
        allow(Ai::Provider).to receive(:call).and_return("not json")
      end

      it "returns a failed Result" do
        expect(service).to be_failure
      end
    end

    context "when the AI returns a JSON array instead of an object" do
      let(:phrase) { "a calm dog" }

      before do
        allow(Ai::Provider).to receive(:call).and_return(%([1, 2, 3]))
      end

      it "does not raise" do
        expect { service }.not_to raise_error
      end

      it "treats the intent as invalid" do
        expect(service).to be_success
        expect(service.data["valid"]).to be false
      end
    end

    context "when the model returns valid as a string" do
      let(:phrase) { "hello there" }
      let(:canned_response) do
        {
          "species" => [], "size" => [], "age_category" => [], "sex" => [],
          "temperament" => [], "living_situation" => [], "energy_level" => [],
          "keywords" => [], "understood" => [], "valid" => "false"
        }
      end

      it "treats the intent as invalid" do
        expect(service.data["valid"]).to be false
      end
    end

    context "when the model returns valid as a string but still extracts data" do
      let(:phrase) { "a calm dog" }
      let(:canned_response) do
        {
          "species" => [ "dog" ], "size" => [], "age_category" => [], "sex" => [],
          "temperament" => [ "calm" ], "living_situation" => [], "energy_level" => [],
          "keywords" => [ "calm dog" ], "understood" => [ "A calm dog" ], "valid" => "false"
        }
      end

      it "respects the explicit false instead of trusting the extracted arrays" do
        expect(service.data["valid"]).to be false
      end
    end

    context "with an unsupported locale" do
      let(:phrase) { "a calm dog" }
      let(:locale) { "fr" }

      it "falls back to the default locale language name" do
        expect(Ai::PromptBuilder).to receive(:call).with(
          prompt_name: "search_intent",
          variables: hash_including(language: "English")
        ).and_return("prompt")

        service
      end
    end
  end
end
