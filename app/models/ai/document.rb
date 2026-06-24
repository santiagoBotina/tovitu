module Ai
  class Document < ApplicationRecord
    self.table_name = "ai_documents"

    belongs_to :shelter
    has_many :chunks, class_name: "Ai::DocumentChunk", foreign_key: :ai_document_id,
             dependent: :destroy

    has_one_attached :file

    validates :title, :content, :source_type, presence: true
    validates :source_type, inclusion: { in: %w[manual pdf] }
    validates :status, inclusion: { in: %w[processing ready failed] }

    scope :ready, -> { where(status: "ready") }
    scope :for_shelter, ->(shelter_id) { where(shelter_id: shelter_id) }
  end
end
