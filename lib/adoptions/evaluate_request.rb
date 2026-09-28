module Adoptions
  # Evaluates an adoption request against system rules (always) and the
  # shelter's enabled evaluation rules (when the request targets a shelter),
  # and persists the verdict snapshot on the request (REQ-49-1, REQ-49-7).
  #
  # The evaluation is deterministic — structured rules over stored signals, no
  # provider call — and ADVISORY. It never changes request status and never
  # notifies anyone of a decision (REQ-49-2, AC-49-2).
  class EvaluateRequest < ApplicationService
    SYSTEM_RULES = %w[account_age_min email_verified adopter_age_min
                      profile_completeness_min no_prior_decline_same_pet].freeze

    def initialize(request:)
      @request = request
    end

    def call
      signals = Evaluation::Signals.call(request: @request)
      results = build_rule_specs.map { |spec| evaluate(spec, signals) }

      verdict = Evaluation::Verdict.call(results)
      return Result.failure([ I18n.t("adoptions.evaluation.errors.no_rules") ]) if verdict == :none

      snapshot = persist_snapshot(verdict, results)

      Result.success(snapshot)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end

    private

    attr_reader :request

    def build_rule_specs
      system_specs + shelter_specs
    end

    def system_specs
      config = Rails.application.config_for(:evaluation).dig(:system_rules) || {}
      SYSTEM_RULES.filter_map do |rule_type|
        rule_config = config[rule_type.to_sym]
        next unless rule_config

        {
          rule_type: rule_type,
          severity: rule_config[:severity] || "yellow",
          params: Evaluation::RuleCatalog.normalize_params(rule_type, rule_config),
          source: "system",
          policy_text: nil
        }
      end
    end

    def shelter_specs
      return [] unless request.shelter.present?

      request.shelter.evaluation_rules.enabled.includes(:policy).filter_map do |rule|
        next unless Evaluation::RuleCatalog.valid_key?(rule.rule_type)

        {
          rule_type: rule.rule_type,
          severity: rule.severity,
          params: Evaluation::RuleCatalog.normalize_params(rule.rule_type, rule.params),
          source: "shelter",
          policy_text: rule.policy&.content
        }
      end
    end

    def evaluate(spec, signals)
      evaluator = Evaluation::Rules.for(spec[:rule_type])
      return unevaluable_result(spec) unless evaluator

      evaluator.new(
        signals: signals,
        rule_type: spec[:rule_type],
        severity: spec[:severity],
        params: spec[:params],
        source: spec[:source],
        policy_text: spec[:policy_text]
      ).call
    end

    def unevaluable_result(spec)
      Evaluation::RuleResult.new(
        rule_type: spec[:rule_type], severity: spec[:severity], source: spec[:source],
        passed: nil, unevaluable: true,
        evidence: { "key" => "adoptions.evaluation.evidence.rule_not_supported" },
        policy_text: spec[:policy_text], params: spec[:params],
        label_key: Evaluation::RuleCatalog.label_key(spec[:rule_type])
      )
    end

    def persist_snapshot(verdict, results)
      ordered = Evaluation::Verdict.order_results(results)

      AdoptionRequestEvaluation.transaction do
        request.policy_evaluation&.destroy!
        request.create_policy_evaluation!(
          verdict: verdict,
          summary: Evaluation::Verdict.summary(verdict, ordered),
          rules: ordered.map(&:to_h_snapshot),
          version: Evaluation::VERSION,
          evaluated_at: Time.current
        )
      end
    end
  end
end
