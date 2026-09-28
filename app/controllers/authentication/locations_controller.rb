module Authentication
  class LocationsController < ApplicationController
    before_action :require_authentication

    # Profile-settings "My Location" management (REQ-48-4). Handles both
    # collection methods (device re-detection / manual edit) and deletion.
    # Consent is not re-requested for a same-purpose change (REQ-48-4).
    def update
      authorize location_for_authorization

      result = process_intent

      if result.success?
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to edit_profile_path, notice: t("locations.flash.updated") }
        end
      else
        respond_to do |format|
          format.turbo_stream { render turbo_stream: turbo_stream.replace("my-location-card", template: "authentication/locations/card") }
          format.html { redirect_to edit_profile_path, alert: Array(result.errors).join(", ") }
        end
      end
    end

    def destroy
      authorize location_for_authorization

      result = Locations::Delete.call(user: current_user)

      if result.success?
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to edit_profile_path, notice: t("locations.flash.deleted") }
        end
      else
        redirect_to edit_profile_path, alert: Array(result.errors).join(", ")
      end
    end

    private

    # The policy needs a persisted-or-new record to check ownership; build one
    # for the current user when none exists yet.
    def location_for_authorization
      @location_for_authorization ||= current_user.user_location || current_user.build_user_location
    end

    # The settings card submits top-level fields (the manual form is a plain
    # `form_with` and device detection fills top-level hidden inputs), so read
    # them directly — matching the onboarding location endpoint's contract.
    def process_intent
      case params[:intent].to_s
      when "device"
        Locations::SaveFromDevice.call(
          user: current_user,
          latitude: params[:latitude],
          longitude: params[:longitude]
        )
      when "manual"
        Locations::SaveManual.call(
          user: current_user,
          city: params[:city],
          region: params[:region],
          country: params[:country]
        )
      else
        Result.failure([ I18n.t("locations.errors.invalid_intent") ])
      end
    end
  end
end
