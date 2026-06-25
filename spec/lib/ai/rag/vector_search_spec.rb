require "rails_helper"

RSpec.describe Ai::Rag::VectorSearch do
  let(:shelter1) { create(:shelter) }
  let(:shelter2) { create(:shelter) }
  let(:doc1) { create(:ai_document, shelter: shelter1, status: "ready") }
  let(:doc2) { create(:ai_document, shelter: shelter2, status: "ready") }

  # Vectors with different directions for distinct cosine distances
  # dog is closest to query, cat is middle, other is farthest
  let(:dog_vector) { [ 0.9, 0.1 ] + [ 0.0 ] * 1534 }
  let(:cat_vector) { [ 0.5, 0.5 ] + [ 0.0 ] * 1534 }
  let(:other_vector) { [ 0.1, 0.9 ] + [ 0.0 ] * 1534 }
  let(:query_vector) { [ 0.85, 0.2 ] + [ 0.0 ] * 1534 }

  let!(:chunk_dog) do
    create(:ai_document_chunk,
      ai_document: doc1,
      content: "Dog adoption policies and procedures.",
      chunk_index: 0,
      embedding: Pgvector.encode(dog_vector))
  end

  let!(:chunk_cat) do
    create(:ai_document_chunk,
      ai_document: doc1,
      content: "Cat adoption policies and guidelines.",
      chunk_index: 1,
      embedding: Pgvector.encode(cat_vector))
  end

  let!(:chunk_other_shelter) do
    create(:ai_document_chunk,
      ai_document: doc2,
      content: "Other shelter policies.",
      chunk_index: 0,
      embedding: Pgvector.encode(other_vector))
  end

  describe ".call" do
    it "returns chunks ordered by cosine similarity" do
      result = described_class.call(query_vector, scope: nil)

      expect(result).to be_a(ActiveRecord::Relation)
      expect(result.first).to eq(chunk_dog)
    end

    it "respects scope filter" do
      scope = Ai::DocumentChunk.joins(:ai_document)
                               .where(ai_documents: { shelter_id: shelter1.id })
      result = described_class.call(query_vector, scope: scope)

      expect(result).to include(chunk_dog, chunk_cat)
      expect(result).not_to include(chunk_other_shelter)
    end

    it "respects limit parameter" do
      result = described_class.call(query_vector, scope: nil, limit: 1)

      expect(result.size).to eq(1)
      expect(result.first).to eq(chunk_dog)
    end

    it "returns empty relation when no matches in scope" do
      scope = Ai::DocumentChunk.joins(:ai_document)
                               .where(ai_documents: { shelter_id: -1 })
      result = described_class.call(query_vector, scope: scope)

      expect(result).to be_empty
    end

    it "works with nil scope (no filter)" do
      result = described_class.call(query_vector, scope: nil)

      expect(result).to include(chunk_dog, chunk_cat, chunk_other_shelter)
    end

    it "returns all chunks when limit is larger than total" do
      result = described_class.call(query_vector, scope: nil, limit: 100)

      expect(result.size).to eq(3)
    end
  end
end
