require "rails_helper"

RSpec.describe "landing/featured_pets", type: :view do
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

  def render_partial
    render partial: "landing/featured_pets"
  end

  it "renders the horizontal scroll strip with proximity snapping" do
    render_partial

    assert_select "div[role='list'][class~='snap-x'][class~='snap-proximity']"
  end

  it "does not force mandatory snapping so the last card can rest fully in view" do
    render_partial

    assert_select "div[role='list'][class~='snap-mandatory']", false
  end

  it "adds end padding so the last card is never clipped at the right edge" do
    render_partial

    assert_select "div[role='list'][class~='pl-4'][class~='pr-8']"
  end

  it "keeps the list semantics and aria-label intact" do
    render_partial

    assert_select "div[role='list'][aria-label='#{I18n.t("landing.index.featured.title")}']"
    # 1 pet card + the CTA card that closes the strip.
    assert_select "div[role='listitem']", count: 2
  end

  it "renders the pet card fully" do
    render_partial

    expect(rendered).to include("Fido")
  end

  it "keeps the horizontal-scroll container math intact" do
    render_partial

    # -mx-4 + pl-4 keeps the first card aligned with the section content while
    # overflow-x-auto contains the scroll; pr-8 is the end padding. Removing any
    # of these would reintroduce clipping or page-level horizontal overflow.
    assert_select "div[role='list'][class~='overflow-x-auto'][class~='-mx-4'][class~='pl-4'][class~='pr-8'][class~='pb-4'][class~='scrollbar-none']"
  end

  it "renders every pet card in the strip (few-cards case)" do
    assign(:presented_featured_pets, [
      PetPresenter.new(pet),
      PetPresenter.new(create(:pet, shelter: shelter, name: "Rex")),
      PetPresenter.new(create(:pet, shelter: shelter, name: "Mia"))
    ])
    render_partial

    # 3 pet cards + the CTA card.
    assert_select "div[role='listitem']", count: 4
    expect(rendered).to include("Fido")
    expect(rendered).to include("Rex")
    expect(rendered).to include("Mia")
  end

  it "renders a single pet card plus the CTA card without clipping" do
    render_partial

    assert_select "div[role='listitem']", count: 2
    assert_select "div[role='listitem']:first-child div[class~='rounded-xl']"
    assert_select "div[role='listitem']:last-child div[class~='bg-primary-500']"
  end

  it "renders the CTA card as the last item with sign-up and sign-in links" do
    render_partial

    assert_select "div[role='listitem']:last-child" do
      assert_select "a[href='#{new_registration_path(role: "individual")}']", text: I18n.t("landing.index.featured.cta_sign_up")
      assert_select "a[href='#{new_session_path}']", text: I18n.t("landing.index.featured.cta_sign_in")
    end
  end

  it "renders the carousel arrows with aria-labels and fine-pointer visibility" do
    render_partial

    assert_select "button[aria-label='#{I18n.t("landing.index.featured.prev_aria")}'][class~='hidden'][class~='[@media(hover:hover)_and_(pointer:fine)]:inline-flex']"
    assert_select "button[aria-label='#{I18n.t("landing.index.featured.next_aria")}'][class~='hidden'][class~='[@media(hover:hover)_and_(pointer:fine)]:inline-flex']"
  end

  it "renders the empty-state CTA when there are no featured pets" do
    assign(:presented_featured_pets, [])
    render_partial

    assert_select "div[role='list']", false
    expect(rendered).to include(I18n.t("landing.index.featured.browse_all"))
  end
end
