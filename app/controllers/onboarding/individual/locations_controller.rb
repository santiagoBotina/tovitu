module Onboarding
  module Individual
    class LocationsController < ApplicationController
      before_action :require_authentication
      before_action :ensure_individual_role

      # Handles the optional location step in the individual onboarding
      # wizard. Accepts three intents:
      #   device — reverse-geocodes browser coords to city-level precision
      #   manual — stores the typed city/region/country
      #   skip   — records the consent decision (skipped) with no location
      # Responds with JSON matching the wizard's question-save contract so the
      # frontend can advance to completion on success or fall back to manual
      # entry on failure (REQ-48-7 graceful degradation).
      def update
        result = process_intent

        if result.success?
          render json: { success: true, data: result.data }, status: :ok
        else
          render json: { success: false, errors: result.errors }, status: :unprocessable_entity
        end
      end

      private

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
        when "skip"
          Locations::RecordDecision.call(user: current_user, decision: "skipped")
        else
          Result.failure([ I18n.t("locations.errors.invalid_intent") ])
        end
      end

      def ensure_individual_role
        return if current_user.individual?

        render json: { success: false, errors: [ I18n.t("flash.unauthorized") ] },
               status: :forbidden
      end
    end
  end
end
