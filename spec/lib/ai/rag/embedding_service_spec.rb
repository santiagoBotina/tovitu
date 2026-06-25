require "rails_helper"

RSpec.describe Ai::Rag::EmbeddingService do
  describe ".call" do
    context "with empty texts" do
      it "returns empty array" do
        result = described_class.call([])
        expect(result).to eq([])
      end
    end

    context "with texts" do
      let(:fake_adapter) { instance_double(Ai::Rag::AnthropicEmbeddingAdapter) }
      let(:embeddings) { [ [ 0.1, 0.2 ], [ 0.3, 0.4 ] ] }

      before do
        allow(Ai::Rag::AnthropicEmbeddingAdapter).to receive(:new).and_return(fake_adapter)
      end

      it "calls adapter.embed with the texts" do
        allow(fake_adapter).to receive(:embed).with([ "hello world" ]).and_return(embeddings)
        result = described_class.call("hello world")
        expect(result).to eq(embeddings)
      end

      it "handles single text string" do
        allow(fake_adapter).to receive(:embed).with([ "test" ]).and_return([ [ 0.5 ] ])
        result = described_class.call("test")
        expect(result).to eq([ [ 0.5 ] ])
      end

      it "handles array of texts" do
        allow(fake_adapter).to receive(:embed).with([ "text1", "text2" ]).and_return(embeddings)
        result = described_class.call([ "text1", "text2" ])
        expect(result).to eq(embeddings)
      end

      it "returns empty array when adapter returns empty" do
        allow(fake_adapter).to receive(:embed).with([ "test" ]).and_return([])
        result = described_class.call("test")
        expect(result).to eq([])
      end
    end

    context "adapter resolution" do
      let(:fake_adapter) { instance_double(Ai::Rag::AnthropicEmbeddingAdapter) }

      before do
        allow(fake_adapter).to receive(:embed).and_return([])
      end

      it "resolves anthropic adapter by default" do
        allow(Ai::Rag::AnthropicEmbeddingAdapter).to receive(:new).and_return(fake_adapter)
        described_class.call("test")
        expect(Ai::Rag::AnthropicEmbeddingAdapter).to have_received(:new)
      end

      it "resolves adapter based on config" do
        allow(Rails.configuration.ai).to receive(:embedding_provider).and_return("anthropic")
        allow(Ai::Rag::AnthropicEmbeddingAdapter).to receive(:new).and_return(fake_adapter)
        described_class.call("test")
        expect(Ai::Rag::AnthropicEmbeddingAdapter).to have_received(:new)
      end

      it "raises NameError for unknown adapter" do
        allow(Rails.configuration.ai).to receive(:embedding_provider).and_return("nonexistent")
        expect { described_class.call("test") }.to raise_error(NameError)
      end
    end
  end
end
