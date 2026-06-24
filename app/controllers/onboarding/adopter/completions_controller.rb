module Onboarding
  module Adopter
    class CompletionsController < ApplicationController
      before_action :require_authentication
      before_action :ensure_adopter_role

      def create
        if current_user.onboarding_completed? && params[:from_profile] == "true"
          redirect_to edit_profile_path, notice: t("flash.onboarding.preferences_updated")
          return
        end

        skip = params[:skip] == "true"
        zero_answers = current_user.adopter_profile.nil? ||
                       current_user.adopter_profile.onboarding_step.to_i == 0

        result = Onboarding::Adopter::Complete.call(
          user: current_user,
          skip: skip
        )

        redirect_destination = params[:redirect_to].presence || pets_path

        if result.success?
          if skip && zero_answers
            redirect_to redirect_destination,
                        notice: t("flash.onboarding.adopter.skipped")
          else
            redirect_to redirect_destination,
                        notice: t("flash.onboarding.adopter.complete")
          end
        else
          redirect_to onboarding_adopter_questions_path,
                      alert: Array(result.errors).join(", ")
        end
      end

      private

      def ensure_adopter_role
        unless current_user.adopter?
          redirect_to root_path, alert: t("flash.unauthorized")
        end
      end
    end
  end
end
