module Onboarding
  module Shelter
    class CompletionsController < ApplicationController
      before_action :require_authentication
      before_action :ensure_shelter_role

      def create
        skip = params[:skip] == "true"
        zero_answers = current_user.shelter_profile.nil? ||
                       current_user.shelter_profile.onboarding_step.to_i == 0

        result = Onboarding::Shelter::Complete.call(
          user: current_user,
          skip: skip
        )

        redirect_destination = if params[:redirect_to].present?
          params[:redirect_to]
        elsif current_user.shelter_id.present?
          shelter_dashboard_path(shelter_id: current_user.shelter_id)
        else
          new_shelter_path
        end

        if result.success?
          if skip && zero_answers
            redirect_to redirect_destination,
                        notice: t("flash.onboarding.shelter.skipped")
          else
            redirect_to redirect_destination,
                        notice: t("flash.onboarding.shelter.complete")
          end
        else
          redirect_to onboarding_shelter_questions_path,
                      alert: Array(result.errors).join(", ")
        end
      end

      private

      def ensure_shelter_role
        unless current_user.shelter_user?
          redirect_to root_path, alert: t("flash.unauthorized")
        end
      end
    end
  end
end
