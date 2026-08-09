module ApplicationHelper
  def present(model)
    presenter_class = "#{model.class}Presenter".safe_constantize
    return model unless presenter_class

    presenter_class.new(model)
  end

  # Small rounded badge used in the adoption process journey. The number
  # conveys order within a linear path — not a decorative section kicker.
  def render_step_badge(number)
    content_tag :span,
                class: "w-10 h-10 rounded-full bg-secondary-500 text-white font-display font-bold text-base flex items-center justify-center mx-auto mb-4 shadow-sm",
                aria: { hidden: "true" } do
      number.to_s
    end
  end

  def safe_url(url)
    return "" unless url.present?

    uri = URI.parse(url)
    uri.scheme.in?(%w[http https]) ? url : ""
  rescue URI::InvalidURIError
    ""
  end

  def question_icon(number)
    icons = {
      1 => "\u{1F3E0}",
      2 => "\u{1F3C3}",
      3 => "\u{1F431}",
      4 => "\u{1F393}",
      5 => "\u{1F497}",
      6 => "\u{23F0}",
      7 => "\u{1F9D0}",
      8 => "\u{1F4AC}"
    }
    icons[number] || "\u{1F43E}"
  end

  def option_icon(question_number, option)
    icons = {
      2 => { very_calm: "\u{1F634}", mostly_calm: "\u{1F634}", balanced: "\u{2696}\u{FE0F}", active: "\u{26A1}", very_active: "\u{1F525}" },
      3 => { calm_friend: "\u{1F43E}", playful_companion: "\u{1F3B6}", affectionate_pet: "\u{1F496}", independent_pet: "\u{1F98E}", social_pet: "\u{1F46B}" },
      4 => { first_time: "\u{1F331}", some_experience: "\u{1F4DA}", years_of_experience: "\u{1F3DB}\u{FE0F}", very_experienced: "\u{1F3AF}" },
      6 => { less_than_1h: "\u{23F1}\u{FE0F}", "1_to_2h": "\u{23F1}\u{FE0F}", "2_to_4h": "\u{23F1}\u{FE0F}", more_than_4h: "\u{23F1}\u{FE0F}" },
      7 => { calm_thoughtful: "\u{1F9D0}", friendly_social: "\u{1F60A}", adventurous_energetic: "\u{1F30D}", organized_routine: "\u{1F4CB}", flexible_spontaneous: "\u{1F300}" }
    }
    icons.dig(question_number, option.to_sym) || ""
  end

  def shelter_question_icon(number)
    icons = {
      1 => "\u{1F3E2}",
      2 => "\u{1F4CA}",
      3 => "\u{1F91D}",
      4 => "\u{1F4DD}",
      5 => "\u{1F4E7}",
      6 => "\u{1F4A1}",
      7 => "\u{1F4AD}"
    }
    icons[number] || "\u{1F3E2}"
  end

  def shelter_option_icon(question_number, option)
    icons = {
      1 => { small_rescue: "\u{1F43E}", independent_shelter: "\u{1F3E0}", large_shelter: "\u{1F3E2}", ngo_foundation: "\u{1F4CB}", foster_based: "\u{1F3E1}" },
      3 => { basic_screening: "\u{1F4DD}", interviews: "\u{1F4AC}", extensive_matching: "\u{1F50D}", long_term_support: "\u{1F4AA}" }
    }
    icons.dig(question_number, option.to_sym) || ""
  end

  def us_states
    [
      %w[AL Alabama], %w[AK Alaska], %w[AZ Arizona], %w[AR Arkansas],
      %w[CA California], %w[CO Colorado], %w[CT Connecticut], %w[DE Delaware],
      %w[FL Florida], %w[GA Georgia], %w[HI Hawaii], %w[ID Idaho],
      %w[IL Illinois], %w[IN Indiana], %w[IA Iowa], %w[KS Kansas],
      %w[KY Kentucky], %w[LA Louisiana], %w[ME Maine], %w[MD Maryland],
      %w[MA Massachusetts], %w[MI Michigan], %w[MN Minnesota], %w[MS Mississippi],
      %w[MO Missouri], %w[MT Montana], %w[NE Nebraska], %w[NV Nevada],
      %w[NH New\ Hampshire], %w[NJ New\ Jersey], %w[NM New\ Mexico],
      %w[NY New\ York], %w[NC North\ Carolina], %w[ND North\ Dakota],
      %w[OH Ohio], %w[OK Oklahoma], %w[OR Oregon], %w[PA Pennsylvania],
      %w[RI Rhode\ Island], %w[SC South\ Carolina], %w[SD South\ Dakota],
      %w[TN Tennessee], %w[TX Texas], %w[UT Utah], %w[VT Vermont],
      %w[VA Virginia], %w[WA Washington], %w[WV West\ Virginia],
      %w[WI Wisconsin], %w[WY Wyoming]
    ]
  end

  # SVG path data for a milestone icon, keyed by the icon name used in
  # Gamification::Journey::MILESTONES. Kept here so views stay readable.
  def milestone_icon_path(icon)
    case icon.to_sym
    when :heart
      "M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
    when :paper_plane
      "M22 2 11 13M22 2l-7 20-4-9-9-4 20-7z"
    when :clock
      "M12 6v6l4 2m6-2a10 10 0 11-20 0 10 10 0 0120 0z"
    when :paw
      "M5.5 10.5a2.5 2.5 0 100-5 2.5 2.5 0 000 5zm13 0a2.5 2.5 0 100-5 2.5 2.5 0 000 5zM12 20a4.5 4.5 0 004.5-4.5c0-1.6-1.2-3.8-2.7-5.2a2.5 2.5 0 00-3.6 0C8.7 11.7 7.5 13.9 7.5 15.5A4.5 4.5 0 0012 20z"
    else
      "M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
    end
  end

  # Memoized adoption journey for the current user. The sidebar and dashboard
  # both render journey-derived UI, so sharing a single instance per request
  # avoids re-running the underlying count queries on every page load.
  def current_user_journey
    return nil unless current_user

    @current_user_journey ||= Gamification::Journey.new(current_user)
  end
end
