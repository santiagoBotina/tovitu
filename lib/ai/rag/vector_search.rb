module Ai
  module Rag
    class VectorSearch < ApplicationService
      def initialize(embedding, scope: nil, limit: 5)
        @embedding = embedding
        @scope = scope
        @limit = limit
        super()
      end

      def call
        relation = Ai::DocumentChunk.all
        relation = relation.merge(@scope) if @scope
        relation.nearest_neighbors(@embedding, distance: :cosine)
                 .limit(@limit)
      end
    end
  end
end
