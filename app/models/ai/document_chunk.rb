module Ai
  class DocumentChunk < ApplicationRecord
    self.table_name = "ai_document_chunks"

    belongs_to :ai_document, class_name: "Ai::Document"

    scope :nearest_neighbors, ->(embedding, distance: :cosine) {
      order(Arel.sql("embedding <=> '#{Pgvector.encode(embedding)}'"))
    }
  end
end
