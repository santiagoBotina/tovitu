require "csv"

module Pets
  # Generates a CSV template for the pet batch import: one header row (all
  # canonical columns) and one filled-in example row so shelters can see the
  # expected values and just replace them.
  class ImportTemplate < ApplicationService
    HEADERS = %w[
      name species breed age_category birth_date size sex status description
      personality_traits medical_notes spayed_neutered vaccinated special_needs
      good_with_children good_with_dogs good_with_cats requirements
      personality_spec adopter_tips
    ].freeze

    EXAMPLE = {
      "name" => "Rex",
      "species" => "dog",
      "breed" => "Labrador Retriever",
      "age_category" => "young",
      "birth_date" => "2024-03-01",
      "size" => "medium",
      "sex" => "male",
      "status" => "available",
      "description" => "Friendly and loves belly rubs.",
      "personality_traits" => "Friendly, Playful",
      "medical_notes" => "",
      "spayed_neutered" => "yes",
      "vaccinated" => "yes",
      "special_needs" => "no",
      "good_with_children" => "yes",
      "good_with_dogs" => "yes",
      "good_with_cats" => "no",
      "requirements" => "A fenced yard",
      "personality_spec" => "",
      "adopter_tips" => ""
    }.freeze

    def call
      CSV.generate do |csv|
        csv << HEADERS
        csv << HEADERS.map { |header| EXAMPLE[header] }
      end
    end
  end
end
