module Shelters
  class InvitationsController < ApplicationController
    before_action :require_authentication

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
  end
end
