module Authentication
  class ProfilesController < ApplicationController
    before_action :require_authentication

    def edit
      @user = current_user
    end

    def update
      @user = current_user
      old_email = @user.email
      new_email = params[:user][:email]&.downcase&.strip

      if @user.update(name: params[:user][:name], email: new_email)
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
  end
end
