require "rails_helper"

RSpec.describe Ai::PromptBuilder do
  let(:prompts_dir) { Rails.root.join("config/prompts") }

  describe "#call" do
    let(:prompt_name) { "life_preview" }
    let(:variables) { { pet_name: "Buddy", species: "dog" } }

    it "loads and interpolates a prompt template" do
      result = described_class.call(prompt_name: prompt_name, variables: variables)
      expect(result).to be_a(String)
      expect(result).to include("Buddy")
      expect(result).to include("dog")
    end

    it "raises error for missing prompt" do
      expect {
        described_class.call(prompt_name: "nonexistent_prompt")
      }.to raise_error(RuntimeError, /not found/)
    end

    context "without variables" do
      it "returns the template as-is" do
        result = described_class.call(prompt_name: prompt_name)
        expect(result).to be_a(String)
      end
    end
  end
end
