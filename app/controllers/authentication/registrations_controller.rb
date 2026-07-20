module Authentication
  class RegistrationsController < ApplicationController
    LOCALE_WHITELIST = %w[en es].freeze

    before_action :require_no_authentication, only: [ :new, :create ]

    def new
      @role = params[:role] || "individual"
      @user = User.new
    end

    def create
      role = params[:user][:role].presence || "individual"

      result = Authentication::RegisterUser.call(
        name: params[:user][:name],
        email: params[:user][:email],
        password: params[:user][:password],
        password_confirmation: params[:user][:password_confirmation],
        role: role,
        locale: detected_locale
      )

      if result.success?
        redirect_to check_email_registration_path,
                    notice: t("flash.registrations.create.success")
      else
        @role = role
        @user = User.new(
          name: params[:user][:name],
          email: params[:user][:email],
          role: role
        )
        Array(result.errors).each { |error| @user.errors.add(:base, error) }
        render :new, status: :unprocessable_entity
      end
    end

    private

    def detected_locale
      browser_locale = request.env["HTTP_ACCEPT_LANGUAGE"]&.scan(/^[a-z]{2}/)&.first
      return I18n.default_locale.to_s unless browser_locale
      LOCALE_WHITELIST.include?(browser_locale) ? browser_locale : I18n.default_locale.to_s
    end
  end
end
