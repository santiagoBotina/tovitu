module EmbeddingAdapterStubs
  def stub_embedding_adapter(return_value:)
    adapter_instance = instance_double(Ai::Rag::AnthropicEmbeddingAdapter)
    allow(Ai::Rag::AnthropicEmbeddingAdapter).to receive(:new).and_return(adapter_instance)
    allow(adapter_instance).to receive(:embed).and_return(return_value)
  end
end

RSpec.configure do |config|
  config.include EmbeddingAdapterStubs
end
