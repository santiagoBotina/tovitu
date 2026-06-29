class AdoptionRequestsController < ApplicationController
  before_action :require_authentication, only: [:index, :show, :new, :create]
  before_action :require_onboarding_complete, only: [:new, :create]

  def index
    authorize AdoptionRequest
    @requests = policy_scope(AdoptionRequest).includes(:pet, :shelter, :timeline_events)
                                              .newest_first
  end

  def show
    @request = AdoptionRequest.includes(:pet, :shelter, :adopter, :timeline_events).find(params[:id])
    authorize @request
    @pet = @request.pet
    @shelter = @request.shelter
    @timeline = @request.timeline_events.chronological
  end

  def new
    @pet = Pet.undiscarded.available.find(params[:pet_id])
    @shelter = @pet.shelter
    @profile = current_user.adopter_profile

    authorize AdoptionRequest
  rescue ActiveRecord::RecordNotFound
    redirect_to pets_path, alert: t("pets.not_found")
  end

  def create
    @pet = Pet.undiscarded.find(params[:pet_id])

    result = Adoptions::SubmitRequest.call(adopter: current_user, pet: @pet)

    if result.success?
      @request = result.data
      Adoptions::NotifyAdopter.call(adoption_request: @request)
      Adoptions::NotifyShelter.call(adoption_request: @request)
      redirect_to adoption_request_path(@request), notice: t("adoptions.requests.flash.submitted")
    else
      redirect_to pet_path(@pet), alert: Array(result.errors).join(", ")
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to pets_path, alert: t("pets.not_found")
  end
end
