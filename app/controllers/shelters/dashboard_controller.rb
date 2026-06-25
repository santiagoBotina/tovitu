module Shelters
  class DashboardController < ApplicationController
    before_action :require_authentication
    before_action :set_shelter

    def show
      authorize @shelter, :dashboard?

      @total_pets = @shelter.pets.undiscarded.count
      @adoptable_pets = @shelter.pets.undiscarded.where(status: :available).count
      @pending_applications = AdoptionApplication.by_shelter(@shelter.id).pending.count
      @in_review_applications = AdoptionApplication.by_shelter(@shelter.id).under_review.count +
                                AdoptionApplication.by_shelter(@shelter.id).awaiting_response.count
      @active_adoptions = AdoptionApplication.by_shelter(@shelter.id).approved.count
      @total_applications_count = AdoptionApplication.by_shelter(@shelter.id).count

      @recent_activity = AdoptionApplication.by_shelter(@shelter.id)
                           .includes(:pet, :user)
                           .order(updated_at: :desc)
                           .limit(5)

      @staff_count = @shelter.users.undiscarded.count
      @staff_members = @shelter.users.undiscarded.limit(5)
      @pending_count = @pending_applications
    end

    private

    def set_shelter
      @shelter = Shelter.undiscarded.find(params[:shelter_id])
    end
  end
end
