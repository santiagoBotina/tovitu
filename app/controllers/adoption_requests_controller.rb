class AdoptionRequestsController < ApplicationController
  before_action :require_authentication, only: [ :index, :show, :new, :create, :withdraw ]
  before_action :require_onboarding_complete, only: [ :new, :create ]
  before_action :set_request, only: [ :show, :withdraw ]

  def index
    authorize AdoptionRequest
    @requests = policy_scope(AdoptionRequest).includes(:pet, :shelter, :timeline_events)
                                              .newest_first
  end

  def show
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

    result = Adoptions::SubmitRequest.call(
      adopter: current_user,
      pet: @pet,
      additional_answers: params[:additional_answers].presence || {}
    )

    if result.success?
      @request = result.data
      was_done = current_user.adoption_requests.where.not(id: @request.id).exists?
      milestone_notice = milestone_unlocked_message(current_user, :first_application, was_done: was_done)
      redirect_to adoption_request_path(@request), notice: milestone_notice || t("adoptions.requests.flash.submitted")
    else
      redirect_to pet_path(@pet), alert: Array(result.errors).join(", ")
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to pets_path, alert: t("pets.not_found")
  end

  def withdraw
    authorize @request, :withdraw?

    result = Adoptions::WithdrawRequest.call(request: @request, adopter: current_user)

    if result.success?
      redirect_to adoption_request_path(@request), notice: t("adoptions.requests.flash.withdrawn")
    else
      redirect_to adoption_request_path(@request), alert: Array(result.errors).join(", ")
    end
  end

  private

  def set_request
    @request = AdoptionRequest.includes(:pet, :shelter, :adopter, :timeline_events).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to adoption_requests_path, alert: t("adoptions.requests.errors.not_found")
  end
end
