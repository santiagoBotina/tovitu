module Adoptions
  class Questionnaire
    DEFAULT_QUESTIONS = [
      { key: "interest_reason",       type: "textarea", required: true }.freeze,
      { key: "living_environment",    type: "select",   options: %w[indoor outdoor both], required: true }.freeze,
      { key: "hours_alone",           type: "text",     required: true }.freeze,
      { key: "previous_pets",         type: "textarea", required: true }.freeze,
      { key: "veterinarian",          type: "text",     required: false }.freeze,
      { key: "household_agreement",   type: "boolean",  required: true }.freeze,
      { key: "landlord_permission",   type: "boolean",  required: false,
        condition: { housing_type: %w[apartment condo] } }.freeze
    ].freeze

    attr_reader :shelter

    def initialize(shelter: nil)
      @shelter = shelter
    end

    def questions
      @questions ||= build_questions
    end

    def self.default_questions
      DEFAULT_QUESTIONS
    end

    private

    def build_questions
      custom = shelter&.adoption_policies&.dig("custom_questionnaire")
      return DEFAULT_QUESTIONS if custom.blank?

      merge_questions(custom)
    end

    def merge_questions(custom)
      merged = DEFAULT_QUESTIONS.dup
      custom.each do |cq|
        cq_sym = cq.symbolize_keys
        idx = merged.index { |dq| dq[:key] == cq_sym[:key] }
        if idx
          merged[idx] = cq_sym
        else
          merged << cq_sym
        end
      end
      merged
    end
  end
end
