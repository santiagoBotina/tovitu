module Shelters
  class DashboardController < ApplicationController
    before_action :require_authentication
    before_action :set_shelter

    def show
      authorize @shelter, :dashboard?

      # Track welcome overlay dismissal
      if params[:welcome_dismissed] == "true"
        session[:welcome_overlay_dismissed] = true
      end

      @total_pets = @shelter.pets.undiscarded.count
      @adoptable_pets = @shelter.pets.undiscarded.where(status: :available).count
      @pending_requests = @shelter.adoption_requests.where(status: :pending).count
      @in_review_requests = @shelter.adoption_requests.where(status: :in_validation).count
      @active_adoptions = @shelter.adoption_requests.where(status: :accepted).count
      @total_requests_count = @shelter.adoption_requests.count

      @recent_activity = @shelter.adoption_requests
                           .includes(:pet, :adopter)
                           .order(updated_at: :desc)
                           .limit(5)

      @staff_count = @shelter.users.undiscarded.count
      @staff_members = @shelter.users.undiscarded.limit(5)
      @pending_count = @pending_requests
    end

    private

    def set_shelter
      @shelter = Shelter.undiscarded.find(params[:shelter_id])
    end
  end
end
