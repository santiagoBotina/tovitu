module Ai
  class GenerateLifePreviewJob < ApplicationJob
    queue_as :default

    def perform(pet_id)
      pet = Pet.find(pet_id)
      return unless pet.shelter.ai_features_enabled?

      result = Ai::GenerateLifePreview.call(
        pet: pet,
        personality_spec: pet.personality_spec,
        adopter_tips: pet.adopter_tips
      )

      if result.success?
        pet.update!(
          life_preview_data: result.data,
          life_preview_generated_at: Time.current,
          life_preview_version: current_prompt_version
        )
      else
        raise result.errors.join(", ")
      end
    end

    private

    def current_prompt_version
      path = Rails.root.join("config/prompts/life_preview.yml")
      YAML.load_file(path)["version"] || 2
    end
  end
end
