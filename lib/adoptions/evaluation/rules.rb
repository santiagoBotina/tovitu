module Adoptions
  module Evaluation
    # Evaluator classes for the bounded rule vocabulary. Each rule reads the
    # signals hash and returns a RuleResult. Base provides the shared result
    # builders (passed / failed / unevaluable) and evidence helper.
    module Rules
      class Base
        def initialize(signals:, rule_type:, severity:, params:, source:, policy_text: nil)
          @signals = signals
          @rule_type = rule_type
          @severity = severity
          @params = params || {}
          @source = source
          @policy_text = policy_text
        end

        def call
          raise NotImplementedError, "#{self.class} must implement #call"
        end

        private

        attr_reader :signals, :rule_type, :severity, :params, :source, :policy_text

        def label_key
          RuleCatalog.label_key(rule_type)
        end

        def passed(evidence:)
          RuleResult.new(rule_type: rule_type, severity: severity, source: source,
                         passed: true, unevaluable: false, evidence: evidence,
                         policy_text: policy_text, params: params, label_key: label_key)
        end

        def failed(evidence:)
          RuleResult.new(rule_type: rule_type, severity: severity, source: source,
                         passed: false, unevaluable: false, evidence: evidence,
                         policy_text: policy_text, params: params, label_key: label_key)
        end

        def unevaluable(evidence:)
          RuleResult.new(rule_type: rule_type, severity: severity, source: source,
                         passed: nil, unevaluable: true, evidence: evidence,
                         policy_text: policy_text, params: params, label_key: label_key)
        end

        def evidence(key, params = {})
          { "key" => key, "params" => params }
        end
      end

      class AccountAge < Base
        def call
          days = params["days"].to_i
          actual = signals[:account_age_days]
          if actual < days
            failed(evidence: evidence("adoptions.evaluation.evidence.account_age_days", { days: actual }))
          else
            passed(evidence: evidence("adoptions.evaluation.evidence.account_age_days", { days: actual }))
          end
        end
      end

      class EmailVerified < Base
        def call
          if signals[:email_verified]
            passed(evidence: evidence("adoptions.evaluation.evidence.email_verified"))
          else
            failed(evidence: evidence("adoptions.evaluation.evidence.email_not_verified"))
          end
        end
      end

      class AdopterAge < Base
        def call
          age = signals[:age_years]
          min = params["years"].to_i
          if age.nil?
            unevaluable(evidence: evidence("adoptions.evaluation.evidence.adopter_age_missing"))
          elsif age < min
            failed(evidence: evidence("adoptions.evaluation.evidence.adopter_age", { years: age }))
          else
            passed(evidence: evidence("adoptions.evaluation.evidence.adopter_age", { years: age }))
          end
        end
      end

      class HomeFencedYard < Base
        def call
          home = signals[:home_environment]
          if home.blank?
            unevaluable(evidence: evidence("adoptions.evaluation.evidence.home_environment_missing"))
          elsif home == "house_with_fenced_yard"
            passed(evidence: evidence("adoptions.evaluation.evidence.home_environment", { home: home }))
          else
            failed(evidence: evidence("adoptions.evaluation.evidence.home_environment", { home: home }))
          end
        end
      end

      class OtherPets < Base
        def call
          other = signals[:other_pets]
          if other.blank?
            unevaluable(evidence: evidence("adoptions.evaluation.evidence.other_pets_missing"))
          elsif other == "no_other_pets"
            passed(evidence: evidence("adoptions.evaluation.evidence.other_pets", { other_pets: other }))
          else
            failed(evidence: evidence("adoptions.evaluation.evidence.other_pets", { other_pets: other }))
          end
        end
      end

      class ProfileCompleteness < Base
        def call
          completeness = signals[:profile_completeness]
          threshold = params["percent"].to_i
          if completeness.nil?
            unevaluable(evidence: evidence("adoptions.evaluation.evidence.profile_missing"))
          else
            percent = (completeness[:fraction].to_f * 100).round
            evidence_params = { percent: percent, answered: completeness[:answered],
                                total: completeness[:total] }
            if percent < threshold
              failed(evidence: evidence("adoptions.evaluation.evidence.profile_completeness", evidence_params))
            else
              passed(evidence: evidence("adoptions.evaluation.evidence.profile_completeness", evidence_params))
            end
          end
        end
      end

      class PetExperience < Base
        LEVEL_ORDER = RuleCatalog::PET_EXPERIENCE_LEVELS.freeze

        def call
          actual = signals[:pet_experience]
          required = params["level"].to_s
          if actual.blank?
            unevaluable(evidence: evidence("adoptions.evaluation.evidence.pet_experience_missing"))
          elsif LEVEL_ORDER.index(actual).to_i < LEVEL_ORDER.index(required).to_i
            failed(evidence: evidence("adoptions.evaluation.evidence.pet_experience", { level: actual }))
          else
            passed(evidence: evidence("adoptions.evaluation.evidence.pet_experience", { level: actual }))
          end
        end
      end

      class DailyTime < Base
        LEVEL_ORDER = RuleCatalog::DAILY_TIME_LEVELS.freeze

        def call
          actual = signals[:daily_time_available]
          required = params["level"].to_s
          if actual.blank?
            unevaluable(evidence: evidence("adoptions.evaluation.evidence.daily_time_missing"))
          elsif LEVEL_ORDER.index(actual).to_i < LEVEL_ORDER.index(required).to_i
            failed(evidence: evidence("adoptions.evaluation.evidence.daily_time", { level: actual }))
          else
            passed(evidence: evidence("adoptions.evaluation.evidence.daily_time", { level: actual }))
          end
        end
      end

      class AdoptionPriority < Base
        def call
          if signals[:adoption_priority_present]
            passed(evidence: evidence("adoptions.evaluation.evidence.adoption_priority_present"))
          else
            failed(evidence: evidence("adoptions.evaluation.evidence.adoption_priority_missing"))
          end
        end
      end

      class AdditionalAnswers < Base
        def call
          if signals[:additional_answers_present]
            passed(evidence: evidence("adoptions.evaluation.evidence.additional_answers_present"))
          else
            failed(evidence: evidence("adoptions.evaluation.evidence.additional_answers_missing"))
          end
        end
      end

      class PriorDecline < Base
        def call
          if signals[:prior_decline_same_pet]
            failed(evidence: evidence("adoptions.evaluation.evidence.prior_decline_same_pet"))
          else
            passed(evidence: evidence("adoptions.evaluation.evidence.no_prior_decline_same_pet"))
          end
        end
      end

      EVALUATORS = {
        "account_age_min" => AccountAge,
        "email_verified" => EmailVerified,
        "adopter_age_min" => AdopterAge,
        "home_fenced_yard_required" => HomeFencedYard,
        "other_pets_allowed" => OtherPets,
        "profile_completeness_min" => ProfileCompleteness,
        "pet_experience_min" => PetExperience,
        "daily_time_available_min" => DailyTime,
        "adoption_priority_present" => AdoptionPriority,
        "additional_answers_present" => AdditionalAnswers,
        "no_prior_decline_same_pet" => PriorDecline
      }.freeze

      def self.for(rule_type)
        EVALUATORS[rule_type.to_s]
      end
    end
  end
end
