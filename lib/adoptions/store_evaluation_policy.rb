module Adoptions
  # Creates (or reuses) a ShelterEvaluationPolicy from a natural-language
  # statement. Deduplicates by exact content so repeated saves do not stack
  # duplicate policies (REQ-49-11).
  class StoreEvaluationPolicy < ApplicationService
    def initialize(shelter:, content:)
      @shelter = shelter
      @content = content.to_s.strip
    end

    def call
      return Result.failure([ I18n.t("adoptions.evaluation.errors.policy_blank") ]) if @content.blank?

      policy = @shelter.evaluation_policies.find_or_initialize_by(content: @content)
      policy.status = "draft" unless policy.translated?
      policy.save!

      Result.success(policy)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end

    private

    attr_reader :shelter, :content
  end
end
