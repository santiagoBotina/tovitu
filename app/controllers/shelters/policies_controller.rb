module Shelters
  class PoliciesController < ApplicationController
    before_action :require_authentication
    before_action :set_shelter

    def show
      authorize @shelter, :policies_edit?
    end

    def edit
      authorize @shelter, :policies_edit?
    end

    def update
      authorize @shelter, :policies_update?

      @shelter.update!(adoption_policies: policy_params)

      redirect_to shelter_policies_path(shelter_id: @shelter), notice: t("flash.policies.update.success")
    rescue ActiveRecord::RecordInvalid => e
      flash.now[:alert] = e.record.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end

    private

    def set_shelter
      @shelter = Shelter.undiscarded.find(params[:shelter_id])
    end

    def policy_params
      params.require(:shelter).permit(
        adoption_policies: %i[
          adoption_fee fee_description minimum_age
          home_visit_required fenced_yard_required
          vet_reference_required other_requirements
        ]
      ).fetch(:adoption_policies, {})
    end
  end
end
