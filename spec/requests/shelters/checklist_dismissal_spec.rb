require "rails_helper"

RSpec.describe "Shelter Dashboard Checklist Dismissal" do
  let(:shelter) { create(:shelter) }
  let(:user) { create(:user, :verified, :onboarding_completed, shelter: shelter) }

  before do
    post session_path, params: { session: { email: user.email, password: "password123" } }
  end

  # Completes all six onboarding steps so the checklist reports done_count == total.
  def complete_checklist!
    create(:pet, shelter: shelter)
    create(:user, :verified, shelter: shelter, role: "staff")
    shelter.update!(
      adoption_policies: { "adoption_fee" => "150" },
      hours: "Mon-Fri 9-5",
      description: "A great place for pets"
    )
  end

  describe "dismiss action visibility" do
    it "shows the dismiss action only when the checklist is complete" do
      complete_checklist!
      get shelter_dashboard_path(shelter_id: shelter)
      expect(response.body).to include(I18n.t("shelters.dashboard.show.onboarding.dismiss"))
    end

    it "does not show the dismiss action while any step is incomplete" do
      create(:pet, shelter: shelter) # one step done, five remaining
      get shelter_dashboard_path(shelter_id: shelter)
      expect(response.body).not_to include(I18n.t("shelters.dashboard.show.onboarding.dismiss"))
    end
  end

  describe "dismissing the checklist" do
    it "persists dismissal and hides the checklist on subsequent visits" do
      complete_checklist!

      expect {
        post dismiss_checklist_shelter_dashboard_path(shelter_id: shelter)
      }.to change { shelter.reload.checklist_dismissed_at }.from(nil)

      expect(response).to redirect_to(shelter_dashboard_path(shelter_id: shelter))

      get shelter_dashboard_path(shelter_id: shelter)
      expect(response.body).not_to include(I18n.t("shelters.dashboard.show.onboarding.title"))
      expect(response.body).to include(I18n.t("shelters.dashboard.show.onboarding.restore"))
    end
  end

  describe "restoring the checklist" do
    it "clears dismissal and renders the checklist again" do
      complete_checklist!
      shelter.update!(checklist_dismissed_at: Time.current)

      expect {
        delete restore_checklist_shelter_dashboard_path(shelter_id: shelter)
      }.to change { shelter.reload.checklist_dismissed_at }.to(nil)

      expect(response).to redirect_to(shelter_dashboard_path(shelter_id: shelter))

      get shelter_dashboard_path(shelter_id: shelter)
      expect(response.body).to include(I18n.t("shelters.dashboard.show.onboarding.title"))
      expect(response.body).not_to include(I18n.t("shelters.dashboard.show.onboarding.restore"))
    end
  end

  describe "authorization" do
    it "rejects non-members from dismissing the checklist" do
      complete_checklist!

      # The member from the outer before block is signed in; log out first so
      # require_no_authentication does not swallow the outsider's login.
      delete session_path
      outsider = create(:user, :verified)
      post session_path, params: { session: { email: outsider.email, password: "password123" } }

      post dismiss_checklist_shelter_dashboard_path(shelter_id: shelter)
      expect(response).to redirect_to(root_path)
      expect(shelter.reload.checklist_dismissed_at).to be_nil
    end
  end
end
