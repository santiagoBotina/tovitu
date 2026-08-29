require "rails_helper"

RSpec.describe "landing/index", type: :view do
  let(:shelter) { create(:shelter) }
  let(:pet) { create(:pet, shelter: shelter, name: "Fido") }

  before do
    # signed_in? is a controller helper_method, not a view helper — define it
    # on the view so the save button renders the signed-out path. The routes are
    # locale-scoped, so the test controller needs default_url_options too
    # (request specs get it from ApplicationController; view specs do not).
    view.singleton_class.define_method(:signed_in?) { false }
    view.controller.singleton_class.define_method(:default_url_options) { { locale: I18n.locale } }
    assign(:presented_featured_pets, [ PetPresenter.new(pet) ])
  end

  it "keeps one h2 per redesigned section" do
    render

    %w[how-it-works matching process benefits for-shelters].each do |id|
      assert_select "section##{id} h2", count: 1
    end
  end

  it "gives the Application Management feature a real card body" do
    render

    # feature2 is a white card with border + shadow (no longer a flat
    # primary-50 box that disappears on the section background).
    assert_select "section#for-shelters div.bg-white.border-2.border-secondary-200.shadow-sm h3",
                  text: I18n.t("landing.index.for_shelters.feature2_title")
  end

  it "renders the request-inbox mock inside the Application Management card" do
    render

    # Decorative mock: applicant rows with status dots (aria-hidden, shapes only).
    assert_select "section#for-shelters div[aria-hidden='true'] span.bg-warning"
    assert_select "section#for-shelters div[aria-hidden='true'] span.bg-secondary-500"
  end

  it "keeps process card body copy at neutral-700 or darker" do
    render

    # No light-gray body copy anywhere in the process section. The white cards
    # use neutral-700; the dark teal Adopt/Thrive cards use secondary-100
    # (4.83:1+ on their surfaces).
    assert_select "section#process p.text-neutral-500", false
    assert_select "section#process p.text-neutral-600", false
    assert_select "section#process p.text-neutral-700", minimum: 4
    assert_select "section#process p.text-secondary-100", count: 2
  end

  it "makes the AI fit card the saturated hero of the matching trio" do
    render

    assert_select "section#matching div.bg-primary-500.border-2.border-primary-700.shadow-button-primary h3",
                  text: I18n.t("landing.index.matching.step2_title")
    assert_select "section#matching span", text: I18n.t("landing.index.matching.ai_badge")
  end

  it "renders the how-it-works journey with oversized numerals and a saturated destination" do
    render

    assert_select "section#how-it-works span[aria-hidden='true'].font-display.text-7xl", count: 3
    assert_select "section#how-it-works div.bg-primary-500 h3", text: I18n.t("landing.index.how_it_works.step3_title")
  end

  it "keeps the benefits CTA wired to registration" do
    render

    assert_select "a[href='#{new_registration_path(role: "individual")}']", text: I18n.t("landing.index.benefits.cta")
  end
end
