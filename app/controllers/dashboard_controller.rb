class DashboardController < ApplicationController
  before_action :require_authentication

  def index
    if current_user.shelter_user? && current_user.shelter_id.present?
      redirect_to shelter_dashboard_path(shelter_id: current_user.shelter_id) and return
    end

    @onboarding_complete = current_user.onboarding_completed?

    @adoption_applications = AdoptionApplication
      .where(applicant_email: current_user.email)
      .includes(pet: [ :shelter, { photos_attachments: :blob } ])
      .order(updated_at: :desc)
      .limit(3)

    @total_applications_count = AdoptionApplication
      .where(applicant_email: current_user.email)
      .count

    @show_onboarding = !@onboarding_complete

    render :index
  end
end
