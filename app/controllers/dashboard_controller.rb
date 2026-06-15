class DashboardController < ApplicationController
  before_action :require_authentication

  def index
    if current_user.adopter?
      redirect_to pets_path and return
    elsif current_user.shelter_user? && current_user.shelter_id.present?
      redirect_to shelter_dashboard_path(shelter_id: current_user.shelter_id) and return
    end
  end
end
