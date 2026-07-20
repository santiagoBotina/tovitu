module Onboarding
  class DetermineDestination < ApplicationService
    def initialize(user:)
      @user = user
    end

    def call
      if @user.individual?
        individual_destination
      elsif @user.shelter_user?
        shelter_destination
      else
        "/"
      end
    end

    private

    def individual_destination
      if @user.onboarding_completed?
        "/pets"
      else
        "/onboarding/individual/questions"
      end
    end

    def shelter_destination
      if @user.onboarding_completed?
        if @user.shelter_id.present?
          "/shelters/#{@user.shelter_id}/dashboard"
        else
          "/shelters/new"
        end
      else
        "/onboarding/shelter/questions"
      end
    end
  end
end
