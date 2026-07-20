class NotificationPreferencesController < ApplicationController
  before_action :require_authentication

  def edit
    authorize :notification_preference
    @preference = current_user.notification_preference || NotificationPreference.defaults_for(current_user)
  end

  def update
    authorize :notification_preference
    @preference = current_user.notification_preference || NotificationPreference.defaults_for(current_user)

    if @preference.update(preference_params)
      redirect_to edit_notification_preferences_path, notice: t("notifications.preferences.saved")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def preference_params
    params.require(:notification_preference).permit(:in_app, :email, :whatsapp, :whatsapp_phone, per_kind_overrides: {})
  end
end
