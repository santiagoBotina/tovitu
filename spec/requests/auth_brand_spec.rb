require "rails_helper"

# Regression lock for Item 1.1: Login and Sign Up must present the official
# Tovitu logo (shared/auth_brand lockup), not the geometric cat-dog mascot.
RSpec.describe "Authentication pages brand lockup", type: :request do
  let(:wordmark) { 'class="font-display text-2xl font-extrabold tracking-tight text-primary-600">Tovitu' }
  # Matches the asset with or without Propshaft's content digest (e.g. tovitu.svg / tovitu-14140419.svg).
  let(:logo_asset) { %r{tovitu(?:-[0-9a-f]+)?\.svg} }

  it "renders the official Tovitu logo on the login page" do
    get login_individual_path(locale: :en)

    expect(response.body).to match(logo_asset)
    expect(response.body).to include(wordmark)
    # The old geometric cat-dog mascot must no longer be the brand element.
    expect(response.body).not_to include('viewBox="0 0 64 64"')
  end

  it "renders the same official Tovitu logo on the sign up page" do
    get new_registration_path(locale: :en, role: "individual")

    expect(response.body).to match(logo_asset)
    expect(response.body).to include(wordmark)
  end

  it "renders the official Tovitu logo on the password reset page" do
    get new_password_reset_path(locale: :en)

    expect(response.body).to match(logo_asset)
    expect(response.body).to include(wordmark)
  end

  it "renders the official Tovitu logo on the check-email and verification pages" do
    get check_email_registration_path(locale: :en)
    expect(response.body).to match(logo_asset)

    get check_email_password_resets_path(locale: :en)
    expect(response.body).to match(logo_asset)
  end

  it "renders the localized title on the Spanish sign up page" do
    get new_registration_path(locale: :es, role: "individual")

    expect(response.body).to include("Crea tu cuenta")
    expect(response.body).not_to include("Create your account")
  end

  it "references the logo asset in both the navbar and the auth lockup" do
    get login_individual_path(locale: :en)

    # Each logo instance is an <img> pointing at the single branded asset —
    # no inline duplication, so gradient-id collisions are impossible.
    srcs = response.body.scan(%r{src="[^"]*tovitu(?:-[0-9a-f]+)?\.svg[^"]*"})
    expect(srcs.size).to eq(2) # navbar logo + auth lockup logo
  end
end
