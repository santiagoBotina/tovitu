# Prepares the "Policy check" evaluation card for the request review pages
# (REQ-49-8 / REQ-49-9). Reads the per-request snapshot and resolves the
# localized labels, severity, evidence, and advisory summary for rendering.
class PolicyCheckPresenter
  VERDICT_BADGE_CLASSES = {
    "high_concern" => "bg-danger/10 text-danger border-danger/20",
    "needs_review" => "bg-warning/10 text-warning border-warning/20",
    "pre_accept" => "bg-success/10 text-success border-success/20"
  }.freeze

  VERDICT_DOT_CLASSES = {
    "high_concern" => "bg-danger",
    "needs_review" => "bg-warning",
    "pre_accept" => "bg-success"
  }.freeze

  def initialize(request:)
    @request = request
  end

  def ready?
    evaluation.present?
  end

  def evaluating?
    !ready? && request.created_at > 10.minutes.ago
  end

  def empty?
    !ready? && !evaluating?
  end

  def verdict
    evaluation.verdict
  end

  def verdict_label
    I18n.t("adoptions.evaluation.verdicts.#{verdict}")
  end

  def verdict_badge_classes
    VERDICT_BADGE_CLASSES.fetch(verdict, "bg-neutral-100 text-neutral-600 border-neutral-200")
  end

  def verdict_dot_classes
    VERDICT_DOT_CLASSES.fetch(verdict, "bg-neutral-400")
  end

  def summary
    data = evaluation.summary.to_h.with_indifferent_access
    key = data[:key]
    return "" if key.blank?

    params = (data[:params] || {}).transform_keys(&:to_sym)
    I18n.t(key, **params)
  end

  def rules
    Array(evaluation.rules).map { |raw| rule_view(raw) }
  end

  def failed_count
    rules.count { |rule| rule[:state] == "failed" }
  end

  def evaluated_at
    evaluation.evaluated_at
  end

  private

  attr_reader :request

  def evaluation
    @request.policy_evaluation
  end

  def rule_view(raw)
    raw = raw.with_indifferent_access
    state = rule_state(raw)
    {
      rule: raw[:rule],
      label: I18n.t(raw[:label_key], default: raw[:rule].to_s.humanize),
      severity: raw[:severity],
      severity_label: I18n.t("adoptions.evaluation.severity.#{raw[:severity]}"),
      source: raw[:source],
      source_label: I18n.t("adoptions.evaluation.sources.#{raw[:source]}"),
      state: state,
      state_label: I18n.t("adoptions.evaluation.states.#{state}"),
      evidence: evidence_text(raw),
      policy_text: raw[:policy_text]
    }
  end

  def rule_state(raw)
    return "unevaluable" if raw[:unevaluable] == true

    raw[:passed] == true ? "passed" : "failed"
  end

  def evidence_text(raw)
    evidence = raw[:evidence].to_h.with_indifferent_access
    key = evidence[:key]
    return "" if key.blank?

    params = (evidence[:params] || {}).symbolize_keys
    params = localize_evidence_params(raw[:rule], params)
    params[:count] = params[:days] if params[:days].present?

    I18n.t(key, **params)
  end

  # Evidence params that reference onboarding option keys are resolved to their
  # localized labels here so the snapshot stays locale-neutral.
  def localize_evidence_params(rule, params)
    case rule
    when "pet_experience_min"
      params[:level] = I18n.t("onboarding.individual.questions.q4.options.#{params[:level]}", default: params[:level])
    when "daily_time_available_min"
      params[:level] = I18n.t("onboarding.individual.questions.q6.options.#{params[:level]}", default: params[:level])
    when "home_fenced_yard_required"
      params[:home] = I18n.t("onboarding.individual.questions.q10.options.#{params[:home]}", default: params[:home])
    when "other_pets_allowed"
      params[:other_pets] = I18n.t("onboarding.individual.questions.q11.options.#{params[:other_pets]}", default: params[:other_pets])
    end
    params
  end
end
