# Per-request snapshot of the adoption policy evaluation (REQ-49-7).
#
# The full outcome is captured at evaluation time — verdict, summary reference,
# and per-rule results — so the review page never recomputes live. Re-running
# (REQ-49-14) replaces the snapshot against current adopter signals. The
# evaluation is advisory only and never changes request status.
class AdoptionRequestEvaluation < ApplicationRecord
  VERDICTS = %w[high_concern needs_review pre_accept].freeze

  belongs_to :adoption_request

  validates :verdict, inclusion: { in: VERDICTS }
  validates :evaluated_at, presence: true

  def high_concern?
    verdict == "high_concern"
  end

  def needs_review?
    verdict == "needs_review"
  end

  def pre_accept?
    verdict == "pre_accept"
  end
end
