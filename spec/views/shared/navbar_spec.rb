require "rails_helper"

RSpec.describe "shared/navbar", type: :view do
  it "renders the minimal variant inside the auth flow" do
    view.define_singleton_method(:auth_flow?) { true }

    render partial: "shared/navbar"

    expect(rendered).to include(I18n.t("shared.navbar.back_home"))
    expect(rendered).not_to include(I18n.t("shared.navbar.sign_in"))
    expect(rendered).not_to include(I18n.t("shared.navbar.create_account"))
    expect(rendered).not_to include(I18n.t("shared.interests.aria_view_saved"))
  end

  it "renders the full navbar outside the auth flow" do
    view.define_singleton_method(:auth_flow?) { false }
    view.define_singleton_method(:signed_in?) { false }
    view.define_singleton_method(:saved_pets_count) { 0 }

    render partial: "shared/navbar"

    expect(rendered).to include(I18n.t("shared.navbar.sign_in"))
    expect(rendered).to include(I18n.t("shared.navbar.create_account"))
    expect(rendered).not_to include(I18n.t("shared.navbar.back_home"))
  end
end
