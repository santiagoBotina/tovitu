module Ai
  class GenerateLifePreview < ApplicationService
    def initialize(household_info:, housing_info:, lifestyle_info:, pet_id:, shelter_id:)
      @household_info = household_info
      @housing_info = housing_info
      @lifestyle_info = lifestyle_info
      @pet_id = pet_id
      @shelter_id = shelter_id
      super()
    end

    def call
      pet = Pet.find(@pet_id)
      policy_context = fetch_shelter_policy_context(pet)

      Ai::Provider.call(
        prompt: Ai::PromptBuilder.call(
          prompt_name: "life_preview",
          variables: {
            household_info: @household_info,
            housing_info: @housing_info,
            lifestyle_info: @lifestyle_info,
            pet_info: format_pet_info(pet),
            shelter_policy_context: policy_context
          }
        )
      )
    end

    private

    attr_reader :household_info, :housing_info, :lifestyle_info

    def format_pet_info(pet)
      [
        "Name: #{pet.name}",
        "Species: #{pet.species}",
        "Breed: #{pet.breed.presence || 'Mixed'}",
        "Age: #{pet.age_category}",
        "Size: #{pet.size}",
        "Description: #{pet.description}",
        "Personality: #{pet.personality_traits_list.join(', ')}"
      ].join("\n")
    end

    def fetch_shelter_policy_context(pet)
      query_text = [
        pet.species,
        pet.breed,
        pet.description&.truncate(500),
        pet.personality_traits_list.join(", ")
      ].compact.join(" ")

      embedding = Ai::Rag::EmbeddingService.call(query_text)
      chunks = Ai::Rag::VectorSearch.call(
        embedding: embedding,
        scope: Ai::DocumentChunk.joins(:ai_document)
                                .where(ai_documents: { shelter_id: pet.shelter_id }),
        limit: 5
      )

      chunks.map(&:content).join("\n\n").presence || "None provided."
    end
  end
end
