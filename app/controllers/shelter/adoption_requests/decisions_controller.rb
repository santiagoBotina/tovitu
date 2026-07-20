class Shelter::AdoptionRequests::DecisionsController < ApplicationController
  before_action :require_authentication
  before_action :set_request

  def new
    authorize @request, :manage?
  end

  def create
    authorize @request, :manage?

    decision = params[:decision]
    result = case decision
    when "in_validation", "accepted"
      Adoptions::ProcessRequest.call(
        request: @request,
        new_status: decision,
        actor: current_user,
        metadata: { source: "shelter_web" }
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
      flash_key = decision == "declined" ? "declined" : "updated"
      redirect_to shelter_adoption_request_path(@request),
                  notice: t("adoptions.requests.flash.#{flash_key}")
    else
      flash.now[:alert] = Array(result.errors).join(", ")
      render :new
    end
  end

  private

  def set_request
    @request = AdoptionRequest.find(params[:adoption_request_id])
    @shelter = current_user.shelter
  rescue ActiveRecord::RecordNotFound
    redirect_to shelter_adoption_requests_path, alert: t("adoptions.requests.errors.not_found")
  end
end
