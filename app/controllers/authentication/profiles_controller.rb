module Authentication
  class ProfilesController < ApplicationController
    before_action :require_authentication

    def edit
      @user = current_user
    end

    def update
      @user = current_user

      if @user.update(user_params)
        redirect_to edit_profile_path, notice: t("flash.profiles.update.success")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    # The account email is the sign-in identifier and is intentionally NOT
    # editable here — it is rendered read-only on the settings page. A
    # locale-only save (language selector auto-save) must never touch it.
    def user_params
      params.fetch(:user, {}).permit(:name, :locale)
    end
  end
end
