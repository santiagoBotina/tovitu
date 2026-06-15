module Authentication
  class RegistrationsController < ApplicationController
    before_action :require_no_authentication, only: [:new, :create]

    def new
      @user = User.new
    end

    def create
      result = Authentication::RegisterUser.call(
        name: params[:user][:name],
        email: params[:user][:email],
        password: params[:user][:password],
        password_confirmation: params[:user][:password_confirmation]
      )

      if result.success?
        redirect_to check_email_registration_path,
                    notice: "Account created! Please check your email to verify your account."
      else
        @user = User.new(
          name: params[:user][:name],
          email: params[:user][:email]
        )
        Array(result.errors).each { |error| @user.errors.add(:base, error) }
        render :new, status: :unprocessable_entity
      end
    end
  end
end
