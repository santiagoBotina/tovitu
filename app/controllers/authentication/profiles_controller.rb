module Authentication
  class ProfilesController < ApplicationController
    before_action :require_authentication

    def edit
      @user = current_user
    end

    def update
      @user = current_user
      old_email = @user.email
      attrs = user_params

      # Only normalize/apply the email when the form actually sent one.
      # A locale-only save (language selector auto-save) must not clear it.
      attrs = attrs.merge(email: attrs[:email]&.downcase&.strip) if attrs.key?(:email)

      if @user.update(attrs)
        if @user.email != old_email
          @user.update!(verified_at: nil)
          Authentication::ResendVerificationEmail.call(user: @user)
          redirect_to edit_profile_path,
                      notice: t("flash.profiles.update.email_changed")
        else
          redirect_to edit_profile_path, notice: t("flash.profiles.update.success")
        end
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def user_params
      params.fetch(:user, {}).permit(:name, :email, :locale)
    end
  end
end
