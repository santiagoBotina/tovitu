module Onboarding
  class DetermineDestination < ApplicationService
    include Rails.application.routes.url_helpers

    def initialize(user:)
      @user = user
    end

    def call
      if @user.individual?
        individual_destination
      elsif @user.shelter_user?
        shelter_destination
      else
        root_path(locale: I18n.locale)
      end
    end

    private

    # Returns fully-formed, locale-scoped paths (the app's routes live under
    # `/:locale`), so any redirect to these values lands on a real route.
    def individual_destination
      if @user.onboarding_completed?
        pets_path(locale: I18n.locale)
      else
        onboarding_individual_questions_path(locale: I18n.locale)
      end
    end

    def shelter_destination
      if @user.onboarding_completed?
        if @user.shelter_id.present?
          shelter_dashboard_path(shelter_id: @user.shelter_id, locale: I18n.locale)
        else
          new_shelter_path(locale: I18n.locale)
        end
      else
        onboarding_shelter_questions_path(locale: I18n.locale)
      end
    end
  end
end
