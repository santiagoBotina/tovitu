# Presentation helpers for the Adopter Insight card.
#
# Icon rendering + presentation-only label/status maps for the visual
# redesign. No business logic lives here — everything is derived from
# presenter fields already exposed by AdopterInsightPresenter.
module AdopterInsightHelper
  # Lucide-style stroke icons (24px viewBox, currentColor). Each entry holds
  # the inner SVG markup for one named glyph; the helper wraps it in an <svg>.
  ICONS = {
    bolt: [ '<path d="M13 2 3 14h9l-1 8 10-12h-9l1-8Z"/>' ],
    clock: [
      '<path d="M12 6v6l4 2"/>',
      '<circle cx="12" cy="12" r="10"/>'
    ],
    home: [
      '<path d="m3 10 9-7 9 7v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z"/>',
      '<path d="M9 22v-6h6v6"/>'
    ],
    users: [
      '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/>',
      '<circle cx="9" cy="7" r="4"/>',
      '<path d="M22 21v-2a4 4 0 0 0-3-3.87"/>',
      '<path d="M16 3.13a4 4 0 0 1 0 7.75"/>'
    ],
    paw: [
      '<circle cx="7.3" cy="10.8" r="1.7"/>',
      '<circle cx="10.1" cy="8.4" r="1.7"/>',
      '<circle cx="13.9" cy="8.4" r="1.7"/>',
      '<circle cx="16.7" cy="10.8" r="1.7"/>',
      '<circle cx="12" cy="14.6" r="2.7"/>'
    ],
    check_circle: [
      '<path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/>',
      '<path d="m9 11 3 3L22 4"/>'
    ],
    alert_triangle: [
      '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/>',
      '<path d="M12 9v4"/>',
      '<path d="M12 17h.01"/>'
    ],
    minus: [ '<path d="M5 12h14"/>' ],
    compass: [
      '<circle cx="12" cy="12" r="10"/>',
      '<path d="m16.24 7.76-2.12 6.36-6.36 2.12 2.12-6.36Z"/>'
    ],
    heart: [ '<path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.51 4.04 3 5.5l7 7Z"/>' ],
    shield_check: [
      '<path d="M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1 1 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1Z"/>',
      '<path d="m9 12 2 2 4-4"/>'
    ],
    calendar: [
      '<path d="M8 2v4"/>',
      '<path d="M16 2v4"/>',
      '<rect x="3" y="4" width="18" height="18" rx="2"/>',
      '<path d="M3 10h18"/>'
    ],
    sparkles: [ '<path d="M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .963 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.963 0Z"/>' ],
    message: [ '<path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5Z"/>' ],
    info: [
      '<circle cx="12" cy="12" r="10"/>',
      '<path d="M12 16v-4"/>',
      '<path d="M12 8h.01"/>'
    ],
    thumbs_up: [
      '<path d="M7 10v12"/>',
      '<path d="M15 5.88 14 10h5.83a2 2 0 0 1 1.92 2.56l-2.33 8A2 2 0 0 1 17.5 22H4a2 2 0 0 1-2-2v-8a2 2 0 0 1 2-2h2.76a2 2 0 0 0 1.79-1.11L12 2a3.13 3.13 0 0 1 3 3.88Z"/>'
    ]
  }.freeze

  # Stable dimension key -> icon. Extend here as the analyzer adds dimensions.
  FACTOR_ICONS = {
    "energy" => :bolt,
    "time" => :clock,
    "experience" => :paw,
    "home_space" => :home,
    "household" => :users
  }.freeze

  # Stable archetype key -> icon. Extend here as the taxonomy grows.
  ARCHETYPE_ICONS = {
    "active_outdoors_partner" => :compass,
    "homebody_companion" => :home,
    "first_time_parent" => :heart,
    "experienced_guardian" => :shield_check,
    "family_builder" => :users,
    "routine_keeper" => :calendar,
    "spontaneous_spirit" => :sparkles,
    "social_house" => :message
  }.freeze

  # Commitment signal kind -> icon + tint.
  SIGNAL_ICONS = {
    "positive" => :thumbs_up,
    "attention" => :alert_triangle,
    "neutral" => :minus
  }.freeze

  STATUS_TINT_CLASSES = {
    "strong_fit" => "bg-secondary-50 text-secondary-700",
    "possible_mismatch" => "bg-warning/10 text-warning",
    "unknown" => "bg-neutral-100 text-neutral-500"
  }.freeze

  SIGNAL_TINT_CLASSES = {
    "positive" => "bg-secondary-50 text-secondary-700",
    "attention" => "bg-warning/10 text-warning",
    "neutral" => "bg-neutral-100 text-neutral-500"
  }.freeze

  DEFAULT_FACTOR_ICON = :check_circle
  DEFAULT_ARCHETYPE_ICON = :sparkles
  DEFAULT_SIGNAL_ICON = :minus
  # Evidence longer than this gets a one-line clamp + "Why?" expander.
  EVIDENCE_EXPAND_THRESHOLD = 110
  # Summaries longer than this get the line-clamp + "Read more" expander.
  SUMMARY_EXPAND_THRESHOLD = 140

  # Wraps one of the ICONS glyphs in a Lucide-style stroke <svg>.
  def adopter_insight_icon(name, size: "w-4 h-4", stroke_width: 2, extra_class: "")
    elements = ICONS[name.to_sym]
    return "".html_safe unless elements

    classes = [ size, extra_class ].reject(&:blank?).join(" ")
    content_tag :svg,
                class: classes,
                fill: "none",
                stroke: "currentColor",
                "stroke-width": stroke_width,
                "stroke-linecap": "round",
                "stroke-linejoin": "round",
                viewBox: "0 0 24 24",
                "aria-hidden": "true" do
      elements.join.html_safe
    end
  end

  def adopter_insight_factor_icon(dimension)
    adopter_insight_icon(FACTOR_ICONS.fetch(dimension.to_s, DEFAULT_FACTOR_ICON))
  end

  def adopter_insight_archetype_icon(key)
    adopter_insight_icon(
      ARCHETYPE_ICONS.fetch(key.to_s, DEFAULT_ARCHETYPE_ICON),
      size: "w-6 h-6",
      stroke_width: 1.75
    )
  end

  def adopter_insight_signal_icon(kind)
    adopter_insight_icon(SIGNAL_ICONS.fetch(kind.to_s, DEFAULT_SIGNAL_ICON), size: "w-3.5 h-3.5")
  end

  def adopter_insight_status_tint(status)
    STATUS_TINT_CLASSES.fetch(status.to_s, STATUS_TINT_CLASSES["unknown"])
  end

  def adopter_insight_signal_tint(kind)
    SIGNAL_TINT_CLASSES.fetch(kind.to_s, SIGNAL_TINT_CLASSES["neutral"])
  end

  def adopter_insight_evidence_long?(text)
    text.to_s.length > EVIDENCE_EXPAND_THRESHOLD
  end

  def adopter_insight_summary_long?(text)
    text.to_s.length > SUMMARY_EXPAND_THRESHOLD
  end
end
