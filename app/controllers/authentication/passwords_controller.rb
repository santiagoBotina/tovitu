module Authentication
  class PasswordsController < ApplicationController
    before_action :require_no_authentication, only: [ :new, :create, :edit, :update ]

    def new
    end

    def create
      Authentication::SendPasswordReset.call(email: params[:password_reset][:email])

      redirect_to check_email_password_resets_path,
                  notice: "If your email is registered, you will receive a password reset link."
    end

    def edit
      @token = params[:id]
      token_record = PasswordResetToken.valid_token(@token)

      if token_record.nil?
        redirect_to new_password_reset_path,
                    alert: "Invalid or expired password reset link. Please request a new one."
      elsif token_record.expired?
        redirect_to new_password_reset_path,
                    alert: "Password reset link has expired. Please request a new one."
      end
    end

    def update
      result = Authentication::ResetPassword.call(
        token: params[:id],
        password: params[:user][:password],
        password_confirmation: params[:user][:password_confirmation]
      )

      if result.success?
        session[:user_id] = result.data[:id]
        redirect_to root_path, notice: "Password has been reset successfully."
      else
        flash.now[:alert] = Array(result.errors).join(", ")
        render :edit, status: :unprocessable_entity
      end
    end
  end
end
