require "rails_helper"

# REQ-05 — Simplified navbar on Login and Sign Up (and the rest of the auth
# flow). The auth screens must not show the full app navigation: no sign-in,
# no create-account, no saved-pets heart — exactly one clear way back home.
RSpec.describe "Auth flow navbar", type: :request do
  let(:back_home) { I18n.t("shared.navbar.back_home") }
  let(:sign_in) { I18n.t("shared.navbar.sign_in") }
  let(:create_account) { I18n.t("shared.navbar.create_account") }
  let(:saved_pets_aria) { I18n.t("shared.interests.aria_view_saved") }

  # The navbar is the <header> element; page copy (e.g. the login subtitle
  # "Sign in to continue…") lives outside it, so assertions are scoped to the
  # header to avoid false positives.
  def navbar_html
    response.body.match(%r{<header.*?</header>}m).to_s
  end

  it "renders the minimal navbar on login" do
    get login_individual_path(locale: :en)

    expect(navbar_html).to include(back_home)
    expect(navbar_html).not_to include(sign_in)
    expect(navbar_html).not_to include(create_account)
    expect(navbar_html).not_to include(saved_pets_aria)
  end

  it "renders the minimal navbar on sign up" do
    get new_registration_path(locale: :en, role: "individual")

    expect(navbar_html).to include(back_home)
    expect(navbar_html).not_to include(sign_in)
    expect(navbar_html).not_to include(create_account)
    expect(navbar_html).not_to include(saved_pets_aria)
  end

  it "renders the minimal navbar on password reset" do
    get new_password_reset_path(locale: :en)

    expect(navbar_html).to include(back_home)
    expect(navbar_html).not_to include(sign_in)
    expect(navbar_html).not_to include(create_account)
  end

  it "renders the minimal navbar on deep links straight to login" do
    get new_session_path(locale: :en)

    expect(navbar_html).to include(back_home)
    expect(navbar_html).not_to include(sign_in)
    expect(navbar_html).not_to include(create_account)
  end

  it "has exactly one back-to-home action on login" do
    get login_individual_path(locale: :en)

    expect(navbar_html.scan(back_home).size).to eq(1)
  end

  it "has exactly one back-to-home action on sign up" do
    get new_registration_path(locale: :en, role: "individual")

    expect(navbar_html.scan(back_home).size).to eq(1)
  end

  it "keeps the full navbar on non-auth pages" do
    get pets_path(locale: :en)

    expect(navbar_html).to include(sign_in)
    expect(navbar_html).to include(create_account)
    expect(navbar_html).to include(saved_pets_aria)
  end
end
