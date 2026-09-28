# A structured, evaluable rule translated from a shelter's natural-language
# policy (REQ-49-5). Rules are proposed by the AI translation service and only
# participate in request-time evaluation once the shelter enables them after
# review. `rule_type` is bounded to the evaluable vocabulary; `params` hold the
# configured parameters (e.g. minimum days/years/percent); `severity` is
# red (high concern) or yellow (warning).
class ShelterEvaluationRule < ApplicationRecord
  SEVERITIES = %w[red yellow].freeze

  belongs_to :policy, class_name: "ShelterEvaluationPolicy"

  validates :rule_type, presence: true
  validates :severity, inclusion: { in: SEVERITIES }

  scope :enabled, -> { where(enabled: true) }
end
