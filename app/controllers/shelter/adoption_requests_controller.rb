class Shelter::AdoptionRequestsController < ApplicationController
  before_action :require_authentication
  before_action :set_shelter

  def index
    authorize AdoptionRequest
    @requests = policy_scope(AdoptionRequest)
                  .by_shelter(@shelter.id)
                  .includes(:pet, :adopter)
                  .newest_first

    @requests = @requests.by_status(params[:status]) if params[:status].present?
  end

  def show
    @request = AdoptionRequest.includes(:pet, :shelter, :adopter, :timeline_events, :reviewed_by)
                               .find(params[:id])
    authorize @request
    @pet = @request.pet
    @adopter = @request.adopter
    @profile = @adopter.adopter_profile
    @timeline = @request.timeline_events.chronological.includes(:actor)

    refresh_stale_insight
  end

  private

  def refresh_stale_insight
    Ai::GenerateAdopterInsightJob.perform_later(request_id: @request.id) if @request.pet_fit_stale?
  end

  def set_shelter
    @shelter = current_user.shelter
    unless @shelter
      redirect_to root_path, alert: t("flash.unauthorized")
    end
  end
end
