# A shelter-authored natural-language adoption policy (REQ-49-4 / REQ-49-11).
#
# Status lifecycle:
#   - draft:      created but not yet translated (or re-translation pending)
#   - translated: an AI translation produced one or more ShelterEvaluationRule
#   - not_evaluated: the policy references data we cannot check yet; it stays
#                    visible to adopters but never affects a verdict
#   - failed:     the AI translation failed; the raw text is kept and a retry
#                 is surfaced in the settings
class ShelterEvaluationPolicy < ApplicationRecord
  STATUSES = %w[draft translated not_evaluated failed].freeze
  # Why a policy could not be evaluated — mapped to a localized label, so the
  # explanation is never frozen in a single AI-generated language.
  REASONS = %w[unsupported_data not_screening].freeze

  belongs_to :shelter
  has_many :rules, class_name: "ShelterEvaluationRule", foreign_key: :policy_id,
                   dependent: :destroy

  validates :content, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :reason, inclusion: { in: REASONS }, allow_nil: true

  scope :translated, -> { where(status: "translated") }
  scope :not_evaluated, -> { where(status: "not_evaluated") }
  scope :actionable, -> { where(status: %w[draft failed]) }

  def translated?
    status == "translated"
  end

  def not_evaluated?
    status == "not_evaluated"
  end

  def failed?
    status == "failed"
  end

  def draft?
    status == "draft"
  end

  # Localized reason for a "not auto-evaluated" policy. Falls back to the raw
  # stored value so legacy rows never break rendering.
  def reason_label
    I18n.t("adoptions.evaluation.settings.reasons.#{reason}", default: reason.to_s)
  end
end
