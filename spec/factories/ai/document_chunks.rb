FactoryBot.define do
  factory :ai_document_chunk, class: "Ai::DocumentChunk" do
    ai_document
    content { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    chunk_index { 0 }
    embedding { Array.new(1536) { rand(-0.1..0.1) } }
  end
end
