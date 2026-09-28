module Adoptions
  # Runs the AI translation for a shelter's evaluation policies (REQ-49-4).
  # Each policy is updated with its proposed rules (enabled = false, awaiting
  # shelter review) or marked "not_evaluated" with a localized reason. Transient
  # provider failures are retried automatically (up to MAX_ATTEMPTS); only a
  # persistent failure is surfaced so the raw policy text is preserved and a
  # manual retry can be offered — it never deletes or blocks policy saving.
  class TranslatePolicies < ApplicationService
    MAX_ATTEMPTS = 3

    def initialize(shelter:, policies:)
      @shelter = shelter
      @policies = Array(policies)
    end

    def call
      statements = @policies.map(&:content)
      translation = translate_with_retries(statements)
      return translation unless translation.success?

      by_statement = index_by_statement(translation.data)

      @policies.each do |policy|
        outcome = by_statement[policy.content]
        apply_outcome(policy, outcome)
      end

      Result.success(@policies.map(&:reload))
    end

    private

    attr_reader :shelter, :policies

    # Retry automatic failures (provider/network/parse) up to MAX_ATTEMPTS.
    # "not_evaluated" is a successful translation, not a retryable failure.
    def translate_with_retries(statements)
      last_result = nil
      MAX_ATTEMPTS.times do
        last_result = Ai::TranslatePolicy.call(policies: statements)
        break if last_result.success?
      end
      last_result
    end

    def index_by_statement(items)
      items.each_with_object({}) do |item, map|
        map[item[:statement]] = item
        # Defensive: also index a squashed version so a lightly-mangled echo
        # from the provider still matches its source policy.
        squashed = item[:statement].gsub(/\s+/, " ").downcase
        map[squashed] ||= item
      end
    end

    def apply_outcome(policy, outcome)
      if outcome.nil? || outcome[:status] != "translated" || outcome[:rules].empty?
        policy.update!(
          status: "not_evaluated",
          reason: outcome&.dig(:reason)
        )
        policy.rules.destroy_all
        return
      end

      policy.transaction do
        policy.rules.destroy_all
        outcome[:rules].each do |rule|
          policy.rules.create!(
            rule_type: rule[:rule_type],
            params: rule[:params],
            severity: rule[:severity],
            enabled: false
          )
        end
        policy.update!(status: "translated", reason: nil)
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn("Policy translation persistence failed for policy #{policy.id}: #{e.record.errors.full_messages.join(', ')}")
      policy.update_columns(status: "failed")
    end
  end
end
