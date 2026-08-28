require "rails_helper"

# REQ-06 — Cohesive visual redesign of Login and Sign Up. Both screens share
# one decorative, aria-hidden background that supports the form without
# competing with it.
RSpec.describe "Auth screens shared background", type: :request do
  it "renders the shared decorative background on login" do
    get login_individual_path(locale: :en)

    expect(response.body).to include('class="auth-background absolute')
    expect(response.body).to include('aria-hidden="true"')
  end

  it "renders the same background on sign up" do
    get new_registration_path(locale: :en, role: "individual")

    expect(response.body).to include('class="auth-background absolute')
  end

  it "renders the background exactly once per page" do
    get login_individual_path(locale: :en)

    expect(response.body.scan('class="auth-background absolute').size).to eq(1)
  end

  it "renders the background on the password reset screen too" do
    get new_password_reset_path(locale: :en)

    expect(response.body).to include('class="auth-background absolute')
  end
end
