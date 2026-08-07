require "rails_helper"

RSpec.describe "Onboarding loading state (shelter + individual)", type: :request do
  let(:user) { create(:user, :verified) }

  before do
    post session_path, params: { session: { email: user.email, password: "password123" } }
  end

  it "individual wizard renders overlay + button data attributes" do
    get onboarding_individual_questions_path
    expect(response.body).to include("data-onboarding-target=\"loadingOverlay\"")
    expect(response.body).to include("data-completing-text=\"#{I18n.t("onboarding.individual.loading.button")}\"")
    expect(response.body).to include("data-onboarding-target=\"nextButtonText\"")
  end

  it "shelter wizard wires the nextButtonText target so the shared controller does not crash" do
    user.update!(role: "shelter_admin", shelter: create(:shelter))
    delete session_path
    post session_path, params: { session: { email: user.email, password: "password123" } }

    get onboarding_shelter_questions_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("data-onboarding-target=\"nextButtonText\"")
    expect(response.body).to include("data-completing-text=\"#{I18n.t("onboarding.shelter.loading.button")}\"")
  end
end
