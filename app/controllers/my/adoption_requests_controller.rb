module My
  class AdoptionRequestsController < ApplicationController
    before_action :require_authentication
    before_action :require_individual

    def index
      @requests = AdoptionRequest
        .joins(:pet)
        .where(pets: { publisher_id: current_user.id })
        .includes(:pet, :adopter)
        .order(created_at: :desc)
    end

    def show
      @request = AdoptionRequest
        .joins(:pet)
        .where(pets: { publisher_id: current_user.id })
        .includes(:pet, :adopter, :timeline_events)
        .find(params[:id])
      @adopter_profile = @request.adopter.individual_profile
      @timeline = @request.timeline_events.chronological.includes(:actor)
      @other_pending_count = AdoptionRequest
        .joins(:pet)
        .where(pets: { publisher_id: current_user.id })
        .where(status: :pending)
        .where.not(id: @request.id)
        .count

      refresh_stale_insight
    end

    private

    def refresh_stale_insight
      Ai::GenerateAdopterInsightJob.perform_later(request_id: @request.id) if @request.pet_fit_stale?
    end

    def require_individual
      unless current_user.individual?
        redirect_to root_path, alert: t("flash.unauthorized")
      end
    end
  end
end
