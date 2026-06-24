module Ai
  class ProcessDocumentJob < ApplicationJob
    queue_as :ai
    retry_on StandardError, attempts: 3, wait: :exponentially_longer

    def perform(document_id)
      document = Ai::Document.find(document_id)
      return unless document.status == "processing"

      if document.source_type == "pdf"
        extract_text_from_pdf(document)
      end

      chunks = Ai::Rag::Chunker.call(document.content)
      texts = chunks.map { |c| c[:content] }
      embeddings = Ai::Rag::EmbeddingService.call(texts)

      ApplicationRecord.transaction do
        chunks.each_with_index do |chunk, i|
          document.chunks.create!(
            content: chunk[:content],
            chunk_index: chunk[:index],
            embedding: embeddings[i]
          )
        end
        document.update!(status: "ready")
      end
    rescue StandardError => e
      document.update!(status: "failed", error_message: e.message)
      raise
    end

    private

    def extract_text_from_pdf(document)
      file = document.file.download
      reader = PDF::Reader.new(StringIO.new(file))
      text = reader.pages.map(&:text).join("\n\n")
      document.update!(content: text)
    end
  end
end
