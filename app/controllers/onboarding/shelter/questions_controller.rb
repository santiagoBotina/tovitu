module Onboarding
  module Shelter
    class QuestionsController < ApplicationController
      before_action :require_authentication
      before_action :ensure_shelter_role
      before_action :require_onboarding_not_complete

      def show
        @from_profile = params[:from_profile] == "true"
        @hide_nav = !@from_profile
        @user = current_user
        @profile = @user.shelter_profile || @user.build_shelter_profile
        @questions_data = Onboarding::Shelter::QuestionsData.all
        @current_step = [ @profile.onboarding_step.to_i, 1 ].max
        @total_questions = Onboarding::Shelter::QuestionsData.count
      end

      def update
        result = Onboarding::Shelter::SaveResponse.call(
          user: current_user,
          question_number: params[:question_number],
          answer: params[:answer]
        )

        if result.success?
          render json: {
            success: true,
            data: result.data
          }, status: :ok
        else
          render json: {
            success: false,
            errors: result.errors
          }, status: :unprocessable_entity
        end
      end

      private

      def ensure_shelter_role
        unless current_user.shelter_user?
          redirect_to root_path, alert: t("flash.unauthorized")
        end
      end

      def require_onboarding_not_complete
        return if params[:from_profile] == "true"

        if current_user.onboarding_completed?
          redirect_to after_sign_in_path, notice: t("flash.onboarding.already_complete")
        end
      end
    end
  end
end
