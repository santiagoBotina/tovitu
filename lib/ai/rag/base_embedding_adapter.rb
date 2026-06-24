module Ai
  module Rag
    class BaseEmbeddingAdapter
      def embed(texts)
        raise NotImplementedError, "#{self.class} must implement #embed"
      end
    end
  end
end
