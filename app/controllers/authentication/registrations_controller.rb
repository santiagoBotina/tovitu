module Authentication
  class RegistrationsController < ApplicationController
    before_action :require_no_authentication, only: [ :new, :create ]

    def new
      @role = params[:role] || "adopter"
      @user = User.new
    end

    def create
      role = params[:user][:role].presence || "adopter"

      result = Authentication::RegisterUser.call(
        name: params[:user][:name],
        email: params[:user][:email],
        password: params[:user][:password],
        password_confirmation: params[:user][:password_confirmation],
        role: role
      )

      if result.success?
        redirect_to check_email_registration_path,
                    notice: t("flash.registrations.create.success")
      else
        @user = User.new(
          name: params[:user][:name],
          email: params[:user][:email],
          role: role
        )
        Array(result.errors).each { |error| @user.errors.add(:base, error) }
        render :new, status: :unprocessable_entity
      end
    end
  end
end
