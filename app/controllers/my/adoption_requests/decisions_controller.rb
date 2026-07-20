module My
  module AdoptionRequests
    class DecisionsController < ApplicationController
      before_action :require_authentication
      before_action :require_individual
      before_action :set_request

      def new
      end

      def create
        decision = params[:decision]

        result = case decision
        when "in_validation", "accepted"
          Adoptions::ProcessRequest.call(
            request: @request,
            new_status: :accepted,
            actor: current_user,
            metadata: { decided_by: "individual_publisher" }
          )
        when "declined"
          Adoptions::DeclineRequest.call(
            request: @request,
            actor: current_user,
            selected_reasons: params[:decline_reasons] || [],
            custom_reason: params[:custom_reason]
          )
        else
          Result.failure([ I18n.t("adoptions.requests.errors.invalid_action") ])
        end

        if result.success?
          redirect_to my_adoption_request_path(@request),
                      notice: t(".decision_made")
        else
          flash.now[:alert] = Array(result.errors).join(", ")
          render :new, status: :unprocessable_entity
        end
      end

      private

      def set_request
        @request = AdoptionRequest
          .joins(:pet)
          .where(pets: { publisher_id: current_user.id })
          .includes(:pet, :adopter)
          .find(params[:adoption_request_id])
      rescue ActiveRecord::RecordNotFound
        redirect_to my_adoption_requests_path, alert: t("adoptions.requests.errors.not_found")
      end

      def require_individual
        unless current_user.individual?
          redirect_to root_path, alert: t("flash.unauthorized")
        end
      end
    end
  end
end
