module Onboarding
  class DetermineDestination < ApplicationService
    def initialize(user:)
      @user = user
    end

    def call
      if @user.adopter?
        adopter_destination
      elsif @user.shelter_user?
        shelter_destination
      else
        "/"
      end
    end

    private

    def adopter_destination
      if @user.onboarding_completed?
        "/pets"
      else
        "/onboarding/adopter/questions"
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
