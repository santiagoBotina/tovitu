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
        @total_questions = Onboarding::Shelter::QuestionsData.count
        @current_step = if params[:start].present?
          params[:start].to_i.clamp(1, @total_questions)
        else
          [ @profile.onboarding_step.to_i, 1 ].max
        end

        render :review if @from_profile
      end

      def update
        result = Onboarding::Shelter::SaveResponse.call(
          user: current_user,
          question_number: params[:question_number],
          answer: params[:answer]
        )

        if params[:from_profile] == "true"
          if result.success?
            redirect_to profile_shelter_onboarding_path, notice: t("flash.onboarding.preferences_updated")
          else
            redirect_to profile_shelter_onboarding_path, alert: Array(result.errors).join(", ")
          end
          return
        end

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
