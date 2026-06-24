FactoryBot.define do
  factory :ai_document, class: "Ai::Document" do
    shelter
    title { Faker::Lorem.sentence(word_count: 4) }
    content { Faker::Lorem.paragraphs(number: 10).join("\n\n") }
    source_type { "manual" }
    status { "processing" }
  end
end
