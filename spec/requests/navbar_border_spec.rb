require "rails_helper"

# Regression lock for Item 1.2 (navbar border): the navbar must be borderless on
# the unauthenticated/public surface and keep its bottom border once signed in.
RSpec.describe "Navbar border on public vs app pages", type: :request do
  it "renders the navbar without a bottom border when signed out" do
    get root_path(locale: :en)

    assert_select "header[class~='sticky']" do |headers|
      expect(headers.first["class"]).not_to include("border-b")
    end
  end

  it "renders the navbar without a bottom border on public pets browse" do
    get pets_path(locale: :en)

    assert_select "header[class~='sticky']" do |headers|
      expect(headers.first["class"]).not_to include("border-b")
    end
  end

  it "renders the navbar with a bottom border when signed in" do
    user = create(:user, :verified, :onboarding_completed)
    post session_path(locale: :en), params: { session: { email: user.email, password: "password123" } }

    get user_dashboard_path(locale: :en)

    assert_select "header[class~='sticky']" do |headers|
      expect(headers.first["class"]).to include("border-b")
    end
  end
end
