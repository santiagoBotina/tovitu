module Onboarding
  module Individual
    class CompletionsController < ApplicationController
      before_action :require_authentication
      before_action :ensure_individual_role

      def create
        if current_user.onboarding_completed? && params[:from_profile] == "true"
          redirect_to edit_profile_path, notice: t("flash.onboarding.preferences_updated")
          return
        end

        skip = params[:skip] == "true"
        zero_answers = current_user.individual_profile.nil? ||
                       current_user.individual_profile.onboarding_step.to_i == 0

        # Capture whether the profile-starter milestone was already unlocked
        # BEFORE completing, so the toast only fires on the first completion.
        was_done = current_user.onboarding_completed?

        result = Onboarding::Individual::Complete.call(
          user: current_user,
          skip: skip
        )

        redirect_destination = params[:redirect_to].presence || pets_path

        if result.success?
          if skip && zero_answers
            # Skipping is not completing: the "profile starter" milestone
            # should only celebrate a genuine completion, so a skipped wizard
            # keeps the plain skipped notice.
            redirect_to redirect_destination,
                        notice: t("flash.onboarding.individual.skipped")
          else
            milestone_notice = milestone_unlocked_message(current_user, :profile_starter, was_done: was_done)
            redirect_to redirect_destination,
                        notice: milestone_notice || t("flash.onboarding.individual.complete")
          end
        else
          redirect_to onboarding_individual_questions_path,
                      alert: Array(result.errors).join(", ")
        end
      end

      private

      def ensure_individual_role
        unless current_user.individual?
          redirect_to root_path, alert: t("flash.unauthorized")
        end
      end
    end
  end
end
