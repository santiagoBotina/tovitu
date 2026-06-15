module Authentication
  class VerificationsController < ApplicationController
    def show
      result = Authentication::VerifyEmail.call(token: params[:token])

      if result.success?
        session[:user_id] = result.data[:id]
        redirect_to root_path, notice: "Email verified successfully! Welcome to Tovitu."
      elsif result.error_code == :expired
        render :expired, status: :unprocessable_entity
      elsif result.error_code == :invalid_token
        token = EmailVerificationToken.find_by(token: params[:token])
        if token&.consumed?
          render :already_verified
        else
          redirect_to new_session_path,
                      alert: Array(result.errors).join(", ")
        end
      else
        redirect_to new_session_path,
                    alert: Array(result.errors).join(", ")
      end
    end
  end
end
