require "rails_helper"

RSpec.describe "Section header explanations", type: :request do
  let(:user) { create(:user, :verified) }

  def sign_in_as(u)
    post session_path, params: { session: { email: u.email, password: "password123" } }
  end

  it "renders explanation on pets explorer" do
    get pets_path
    expect(response.body).to include("Browse adoptable pets near you")
  end

  it "renders explanation on notifications" do
    sign_in_as(user)
    get notifications_path
    expect(response.body).to include("all in one feed")
  end

  it "renders explanation on my pets" do
    sign_in_as(user)
    get my_pets_path
    expect(response.body).to include("Pets you&#39;ve published")
  end

  it "renders explanation on my adoption requests" do
    sign_in_as(user)
    get my_adoption_requests_path
    expect(response.body).to include("decide who meets your pet best")
  end

  it "renders explanation on adoption requests" do
    sign_in_as(user)
    get adoption_requests_path
    expect(response.body).to include("Every pet you&#39;ve applied for")
  end

  it "renders explanation on profile settings" do
    sign_in_as(user)
    get edit_profile_path
    expect(response.body).to include("better your pet matches")
  end

  it "renders explanation on shelter dashboard (no pending requests)" do
    shelter = create(:shelter)
    shelter_admin = create(:user, :verified, :shelter_admin, shelter: shelter)
    sign_in_as(shelter_admin)
    get shelter_dashboard_path(shelter)
    # No pending requests => the "new shelter" explanation is shown (dynamic behavior)
    expect(response.body).to include("Let&#39;s get your shelter set up")
  end

  it "renders explanation on shelter dashboard (with pending requests)" do
    shelter = create(:shelter)
    pet = create(:pet, shelter: shelter)
    adopter = create(:user, :verified, :onboarding_completed)
    create(:adoption_request, pet: pet, shelter: shelter, adopter: adopter, status: "pending")
    shelter_admin = create(:user, :verified, :shelter_admin, shelter: shelter)
    sign_in_as(shelter_admin)
    get shelter_dashboard_path(shelter)
    # With pending requests => the "at a glance" explanation is shown (dynamic behavior)
    expect(response.body).to include("at a glance")
  end

  it "renders explanation on shelter pets" do
    shelter = create(:shelter)
    shelter_admin = create(:user, :verified, :shelter_admin, shelter: shelter)
    sign_in_as(shelter_admin)
    get shelter_pets_path
    expect(response.body).to include("Every pet your shelter manages")
  end

  it "renders explanation on shelter adoption requests" do
    shelter = create(:shelter)
    shelter_admin = create(:user, :verified, :shelter_admin, shelter: shelter)
    sign_in_as(shelter_admin)
    get shelter_adoption_requests_path
    expect(response.body).to include("decide who fits best")
  end
end
