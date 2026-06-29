class DashboardController < ApplicationController
  before_action :require_authentication

  def index
    if current_user.shelter_user? && current_user.shelter_id.present?
      redirect_to shelter_dashboard_path(shelter_id: current_user.shelter_id) and return
    end

    @onboarding_complete = current_user.onboarding_completed?

    @adoption_requests = AdoptionRequest
      .where(adopter_id: current_user.id)
      .includes(:pet, :shelter)
      .order(updated_at: :desc)
      .limit(3)

    @total_requests_count = AdoptionRequest
      .where(adopter_id: current_user.id)
      .count

    @show_onboarding = !@onboarding_complete

    render :index
  end
end
