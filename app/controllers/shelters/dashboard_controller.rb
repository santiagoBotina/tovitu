module Shelters
  class DashboardController < ApplicationController
    before_action :require_authentication
    before_action :set_shelter

    def show
      authorize @shelter, :dashboard?

      @total_pets = 0
      @active_applications = 0
      @pending_tasks = []
    end

    private

    def set_shelter
      @shelter = Shelter.undiscarded.find(params[:shelter_id])
    end
  end
end
