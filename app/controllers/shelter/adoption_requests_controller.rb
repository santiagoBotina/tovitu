class Shelter::AdoptionRequestsController < ApplicationController
  before_action :require_authentication
  before_action :set_shelter

  def index
    authorize AdoptionRequest
    scope = policy_scope(AdoptionRequest)
              .by_shelter(@shelter.id)
              .newest_first
    scope = scope.by_status(params[:status]) if params[:status].present?

    result = Adoptions::RequestIndex.call(scope: scope, params: index_params)
    @requests = result.records
    @pagination = result
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

  def index_params
    params.permit(:status, :page, :per_page)
  end

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
