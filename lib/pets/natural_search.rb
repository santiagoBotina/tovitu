module Pets
  # Ranks a constrained set of pets against a structured search intent (the
  # data hash produced by Ai::ExtractSearchIntent).
  #
  # Deterministic, in-process scoring — NO per-pet AI calls (cost/latency
  # mitigation per plan 36). The controller constrains the candidate set with
  # the existing structured filters, then this service orders that set by
  # relevance to the natural-language intent.
  #
  # Score weights (documented):
  #   species match          hard constraint (requested species only)
  #   size match              +25
  #   age match               +20
  #   sex match               +15
  #   text affinity            +4 per matched token, capped at +40
  #   tie-break               created_at desc
  #
  # When the intent explicitly names a species (e.g. "cat"), the candidate set
  # is constrained to that species so unrelated pets never surface — the user
  # said what they want, so mismatched species are excluded, not just demoted.
  # All other dimensions (size/age/sex/temperament) rank within that set.
  #
  # Result data (STRING keys):
  #   "ordered_ids" => Array of pet ids ranked best-first
  #   "reasons"     => Hash { pet_id => { "matched" => { "species" => bool,
  #                    "size" => bool, "age" => bool, "sex" => bool },
  #                    "temperament" => [tokens that matched] } }
  #   "count"       => candidate count
  class NaturalSearch < ApplicationService
    SIZE_MATCH_SCORE = 25
    AGE_MATCH_SCORE = 20
    SEX_MATCH_SCORE = 15
    TEXT_TOKEN_SCORE = 4
    TEXT_TOKEN_CAP = 40

    TEXT_SOURCES = %w[temperament living_situation energy_level keywords].freeze
    STRUCTURED_KEYS = %w[species size age_category sex].freeze

    def initialize(pets:, intent:, locale: nil)
      @pets = pets
      @intent = intent
      @locale = locale
      super()
    end

    def call
      records = load_records
      return Result.success(no_op_result(records)) if blank_intent?

      records = filter_by_species(records)

      ranked = records.map { |pet| [ pet, score(pet) ] }
                      .sort_by { |pet, score| [ -score, -pet.created_at.to_i ] }

      ordered_ids = ranked.map { |pet, _score| pet.id }
      reasons = ranked.each_with_object({}) do |(pet, _score), hash|
        hash[pet.id] = reason_for(pet)
      end

      Result.success(
        "ordered_ids" => ordered_ids,
        "reasons" => reasons,
        "count" => records.size
      )
    end

    private

    attr_reader :pets, :intent

    def load_records
      if pets.is_a?(ActiveRecord::Relation)
        pets.select(:id, :species, :size, :age_category, :sex,
                    :personality_traits, :description, :requirements,
                    :breed, :created_at).to_a
      else
        Array(pets)
      end
    end

    def requested_species
      Array(intent&.dig("species")).map(&:to_s).select(&:present?)
    end

    def filter_by_species(records)
      return records if requested_species.empty?
      records.select { |pet| requested_species.include?(pet.species) }
    end

    def blank_intent?
      return true if intent.nil?
      return true unless intent.is_a?(Hash)
      return true if intent["valid"] == false

      (TEXT_SOURCES + STRUCTURED_KEYS).none? { |key| Array(intent[key]).any? }
    end

    def no_op_result(records)
      ordered = records.sort_by { |pet| -pet.created_at.to_i }
      {
        "ordered_ids" => ordered.map(&:id),
        "reasons" => {},
        "count" => records.size
      }
    end

    def score(pet)
      size_score(pet) + age_score(pet) + sex_score(pet) + text_score(pet)
    end

    def size_score(pet)
      requested = Array(intent["size"])
      return 0 if requested.empty?

      requested.include?(pet.size) ? SIZE_MATCH_SCORE : 0
    end

    def age_score(pet)
      requested = Array(intent["age_category"])
      return 0 if requested.empty?

      requested.include?(pet.age_category) ? AGE_MATCH_SCORE : 0
    end

    def sex_score(pet)
      requested = Array(intent["sex"])
      return 0 if requested.empty?

      requested.include?(pet.sex) ? SEX_MATCH_SCORE : 0
    end

    def text_score(pet)
      matched = matched_tokens(pet)
      [ matched.size * TEXT_TOKEN_SCORE, TEXT_TOKEN_CAP ].min
    end

    def matched_tokens(pet)
      haystack = normalize_text(text_haystack(pet))
      text_tokens.select { |token| haystack.include?(normalize_text(token)) }
    end

    def text_tokens
      @text_tokens ||= TEXT_SOURCES.flat_map { |key| Array(intent[key]) }
                                  .map(&:to_s)
                                  .map(&:strip)
                                  .reject(&:empty?)
                                  .uniq
    end

    def text_haystack(pet)
      [
        Array(pet.personality_traits),
        pet.description,
        pet.requirements,
        pet.breed
      ].flatten.compact.join(" ")
    end

    def normalize_text(value)
      value.to_s
           .downcase
           .unicode_normalize(:nfd)
           .gsub(/\p{Mn}/, "")
    end

    def reason_for(pet)
      {
        "matched" => {
          "species" => species_matched?(pet),
          "size" => size_matched?(pet),
          "age" => age_matched?(pet),
          "sex" => sex_matched?(pet)
        },
        "temperament" => matched_tokens(pet)
      }
    end

    def species_matched?(pet)
      requested = Array(intent["species"])
      requested.any? && requested.include?(pet.species)
    end

    def size_matched?(pet)
      requested = Array(intent["size"])
      requested.any? && requested.include?(pet.size)
    end

    def age_matched?(pet)
      requested = Array(intent["age_category"])
      requested.any? && requested.include?(pet.age_category)
    end

    def sex_matched?(pet)
      requested = Array(intent["sex"])
      requested.any? && requested.include?(pet.sex)
    end
  end
end
