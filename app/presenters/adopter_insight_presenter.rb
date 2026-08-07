# Prepares the Adopter Insight Card data for the request review pages.
#
# Combines the per-adopter cached insight (archetype, commitment signals,
# confidence, provenance) with the per-request pet-fit summary (fit indicators,
# summary, verification questions).
class AdopterInsightPresenter
  CONFIDENCE_ORDER = { "high" => 3, "medium" => 2, "low" => 1 }.freeze
  DIMENSION_LABEL_KEYS = {
    "energy" => "ai.adopter_insight.card.dimensions.energy",
    "time" => "ai.adopter_insight.card.dimensions.time",
    "experience" => "ai.adopter_insight.card.dimensions.experience",
    "home_space" => "ai.adopter_insight.card.dimensions.home_space",
    "household" => "ai.adopter_insight.card.dimensions.household"
  }.freeze
  STATUS_LABEL_KEYS = {
    "strong_fit" => "ai.adopter_insight.card.statuses.strong_fit",
    "possible_mismatch" => "ai.adopter_insight.card.statuses.possible_mismatch",
    "unknown" => "ai.adopter_insight.card.statuses.unknown"
  }.freeze

  def initialize(request:, adopter:)
    @request = request
    @adopter = adopter
  end

  def ready?
    insight.present? && insight.data.present? && request.pet_fit_data.present?
  end

  def loading?
    !ready? && request.created_at > 10.minutes.ago
  end

  def unavailable?
    !ready? && !loading?
  end

  def pet_fit_stale?
    request.pet_fit_stale?
  end

  def archetype_present?
    insight_data["archetype"].present?
  end

  def archetype_label
    return I18n.t("ai.adopter_insight.card.not_enough_activity") unless archetype_present?

    I18n.t(Ai::Adopter::Archetype.label_key(insight_data["archetype"]))
  end

  def self_report_present?
    insight_data["self_reported_personality"].present?
  end

  def self_report_label
    key = insight_data["self_reported_personality"]
    return "" unless key.present?

    I18n.t("onboarding.individual.questions.q7.options.#{key}")
  end

  def diverges?
    insight_data["archetype_diverges"] == true
  end

  def commitment_signals
    Array(insight_data["commitment_signals"]).filter_map do |signal|
      next unless signal.is_a?(Hash) && signal["observation"].present?

      {
        label: I18n.t("ai.adopter_insight.card.signal_labels.#{signal['label']}",
                      default: signal["label"].to_s.humanize),
        observation: signal["observation"],
        kind: signal["kind"].presence || "neutral"
      }
    end
  end

  def fit_indicators
    fit_data = request.pet_fit_data.to_h["fit_indicators"] || {}
    Ai::Adopter::PetFitAnalyzer::DIMENSIONS.map do |dimension|
      item = fit_data[dimension] || {}
      status = item["status"] || "unknown"
      {
        key: dimension,
        label: I18n.t(DIMENSION_LABEL_KEYS.fetch(dimension)),
        status: status,
        status_label: I18n.t(STATUS_LABEL_KEYS.fetch(status)),
        evidence: evidence_for(status, item["evidence"])
      }
    end
  end

  def summary
    request.pet_fit_data.to_h["summary"].to_s
  end

  def verification_questions
    Array(request.pet_fit_data.to_h["verification_questions"])
  end

  def confidence_key
    insight_conf = insight_data["confidence"]
    fit_conf = request.pet_fit_data.to_h["confidence"]
    return fit_conf if insight_conf.blank?
    return insight_conf if fit_conf.blank?

    CONFIDENCE_ORDER[fit_conf].to_i < CONFIDENCE_ORDER[insight_conf].to_i ? fit_conf : insight_conf
  end

  def confidence_label
    I18n.t("ai.adopter_insight.card.confidence.#{confidence_key}", default: confidence_key.to_s.humanize)
  end

  def based_on
    insight_data.dig("provenance", "based_on").to_s
  end

  def activity_up_to
    insight_data.dig("provenance", "activity_up_to")
  end

  def disclaimer
    I18n.t("ai.adopter_insight.card.disclaimer")
  end

  private

  attr_reader :request, :adopter

  def insight
    adopter.adopter_insight
  end

  def insight_data
    insight&.data || {}
  end

  def evidence_for(status, evidence)
    return I18n.t("ai.adopter_insight.card.not_enough_activity") if status == "unknown" && evidence.blank?
    return I18n.t("ai.adopter_insight.card.not_enough_activity") if evidence.blank?

    evidence
  end
end
