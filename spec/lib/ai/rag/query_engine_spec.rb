require "rails_helper"

RSpec.describe Ai::Rag::QueryEngine do
  let(:question) { "What is your adoption fee?" }
  let(:chunk1) { instance_double("Ai::DocumentChunk", content: "Adoption fee is $50.") }
  let(:chunk2) { instance_double("Ai::DocumentChunk", content: "We also offer fee waivers for seniors.") }
  let(:context_chunks) { [ chunk1, chunk2 ] }
  let(:built_prompt) { "System: You are an assistant\n\nContext:\n[Document 1]: Adoption fee is $50.\n\n[Document 2]: We also offer fee waivers for seniors.\n\nQuestion: What is your adoption fee?" }
  let(:provider_answer) { "Our adoption fee is $50." }

  before do
    allow(Ai::PromptBuilder).to receive(:call).and_return(built_prompt)
    allow(Ai::Provider).to receive(:call).and_return(provider_answer)
  end

  describe ".call" do
    it "calls PromptBuilder with correct arguments" do
      described_class.call(question: question, context_chunks: context_chunks)

      expect(Ai::PromptBuilder).to have_received(:call) do |args|
        expect(args[:prompt_name]).to eq("rag_faq")
        expect(args[:variables][:question]).to eq(question)
        expect(args[:variables][:context]).to be_present
        expect(args[:variables][:disclaimer]).to eq(I18n.t("ai.rag.disclaimer"))
      end
    end

    it "calls Provider with the built prompt" do
      described_class.call(question: question, context_chunks: context_chunks)

      expect(Ai::Provider).to have_received(:call).with(prompt: built_prompt)
    end

    it "returns the provider answer" do
      result = described_class.call(question: question, context_chunks: context_chunks)

      expect(result).to eq(provider_answer)
    end

    it "formats context chunks correctly" do
      described_class.call(question: question, context_chunks: context_chunks)

      expect(Ai::PromptBuilder).to have_received(:call) do |args|
        expected_context = "[Document 1]: Adoption fee is $50.\n\n[Document 2]: We also offer fee waivers for seniors."
        expect(args[:variables][:context]).to eq(expected_context)
      end
    end

    it "includes extra variables in prompt variables" do
      extra = { application_status: "pending", pet_name: "Buddy" }

      described_class.call(
        question: question,
        context_chunks: context_chunks,
        extra_variables: extra
      )

      expect(Ai::PromptBuilder).to have_received(:call) do |args|
        expect(args[:variables][:application_status]).to eq("pending")
        expect(args[:variables][:pet_name]).to eq("Buddy")
      end
    end

    it "defaults to rag_faq system prompt name" do
      described_class.call(question: question, context_chunks: context_chunks)

      expect(Ai::PromptBuilder).to have_received(:call) do |args|
        expect(args[:prompt_name]).to eq("rag_faq")
      end
    end

    it "allows custom system prompt name" do
      described_class.call(
        question: question,
        context_chunks: context_chunks,
        system_prompt_name: "rag_application_qa"
      )

      expect(Ai::PromptBuilder).to have_received(:call) do |args|
        expect(args[:prompt_name]).to eq("rag_application_qa")
      end
    end

    context "with empty context chunks" do
      it "works with empty chunks array" do
        described_class.call(question: question, context_chunks: [])

        expect(Ai::PromptBuilder).to have_received(:call) do |args|
          expect(args[:variables][:context]).to eq("")
        end
      end
    end
  end
end
