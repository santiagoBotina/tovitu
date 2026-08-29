require "rails_helper"

# Guards the shared .select-control component (REQ-17) against drifting off the
# DESIGN.md spacing scale. The chevron gap and right padding must stay on the
# defined tokens (md = 16px, 2xl = 48px) — no ad-hoc values (AC-39-1, AC-39-3).
RSpec.describe "shared select-control component", type: :view do
  let(:css_path) { Rails.root.join("app/assets/tailwind/application.css") }
  let(:css) { File.read(css_path) }

  # Pull the body of the .select-control rule out of its @layer components block.
  let(:select_control_rule) do
    match = css.match(/\.select-control\s*\{([^}]*)\}/m)
    match && match[1]
  end

  it "defines the shared select-control component" do
    expect(select_control_rule).to be_present
  end

  it "positions the chevron one md token (16px) from the right edge" do
    expect(select_control_rule).to include("background-position: right 16px center")
  end

  it "reserves 2xl (48px) of right padding so option text never runs under the chevron" do
    expect(select_control_rule).to include("padding-right: 48px")
  end

  it "removes the native appearance so the custom chevron is the only arrow" do
    expect(select_control_rule).to include("appearance: none")
  end

  it "keeps the chevron decorative (no text alternative is exposed)" do
    # The chevron is a background-image on a native <select>; native selects do
    # not expose their arrow to assistive tech, so no aria-hidden is required.
    expect(select_control_rule).to include("background-image: url(")
  end
end
