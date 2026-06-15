module Authentication
  class VerificationsController < ApplicationController
    def show
      result = Authentication::VerifyEmail.call(token: params[:token])

      if result.success?
        session[:user_id] = result.data[:id]
        user = current_user

        if user.onboarding_completed?
          redirect_to after_sign_in_path, notice: t("flash.verifications.show.success")
        else
          destination = Onboarding::DetermineDestination.call(user: user)
          redirect_to destination, notice: t("flash.verifications.show.success")
        end
      elsif result.error_code == :expired
        render :expired, status: :unprocessable_entity
      elsif result.error_code == :invalid_token
        token = EmailVerificationToken.find_by(token: params[:token])
        if token&.consumed?
          render :already_verified
        else
          redirect_to root_path,
                      alert: Array(result.errors).join(", ")
        end
      else
        redirect_to root_path,
                    alert: Array(result.errors).join(", ")
      end
    end
  end
end
