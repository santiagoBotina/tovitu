module Shelters
  class InvitationsController < ApplicationController
    before_action :require_authentication
    before_action :set_shelter, only: [ :cancel ]

    def create
      result = Shelters::AcceptInvitation.call(
        token: params[:token],
        user: current_user
      )

      if result.success?
        redirect_to shelter_dashboard_path(shelter_id: result.data), notice: t("flash.invitations.create.success")
      else
        redirect_to root_path, alert: Array(result.errors).join(", ")
      end
    end

    def cancel
      authorize @shelter, :invitations_cancel?

      invitation = @shelter.invitations.find(params[:id])

      result = Shelters::CancelInvitation.call(
        shelter: @shelter,
        actor: current_user,
        invitation: invitation
      )

      if result.success?
        redirect_to shelter_staff_index_path(shelter_id: @shelter), notice: t("flash.invitations.cancel.success")
      else
        redirect_to shelter_staff_index_path(shelter_id: @shelter), alert: Array(result.errors).join(", ")
      end
    end

    private

    def set_shelter
      @shelter = Shelter.undiscarded.find(params[:shelter_id])
    end
  end
end
