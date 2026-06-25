module Ai
  module Rag
    class Chunker < ApplicationService
      TARGET_SIZE = 1000
      OVERLAP_SIZE = 200

      def initialize(text, metadata: {})
        @text = text
        @metadata = metadata
        super()
      end

      def call
        return [] if @text.blank?

        chunks = []
        start_pos = 0

        while start_pos < @text.length
          end_pos = find_chunk_end(start_pos)
          content = @text[start_pos...end_pos].strip
          chunks << { content: content, index: chunks.size, metadata: @metadata } if content.present?
          break if end_pos >= @text.length || chunks.size >= 100
          start_pos = end_pos - OVERLAP_SIZE
          start_pos = 0 if start_pos < 0
        end

        chunks
      end

      private

      def find_chunk_end(start_pos)
        target_end = start_pos + TARGET_SIZE
        return @text.length if target_end >= @text.length

        paragraph_boundary = @text.index("\n\n", target_end - OVERLAP_SIZE)
        return paragraph_boundary + 2 if paragraph_boundary && (paragraph_boundary - target_end).abs < TARGET_SIZE / 2

        sentence_boundary = @text.index(/\.\s/, target_end - OVERLAP_SIZE)
        return sentence_boundary + 2 if sentence_boundary && (sentence_boundary - target_end).abs < TARGET_SIZE / 2

        word_boundary = @text.rindex(/\s/, target_end)
        word_boundary ? word_boundary : target_end
      end
    end
  end
end
