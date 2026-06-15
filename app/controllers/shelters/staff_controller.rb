module Shelters
  class StaffController < ApplicationController
    before_action :require_authentication
    before_action :set_shelter

    def index
      authorize @shelter, :staff_index?
      @staff_members = @shelter.users.undiscarded.order(:name)
      @pending_invitations = @shelter.invitations.pending.order(created_at: :desc)
    end

    def create
      authorize @shelter, :staff_create?

      result = Shelters::InviteStaff.call(
        shelter: @shelter,
        inviter: current_user,
        email: params[:email]
      )

      if result.success?
        redirect_to shelter_staff_index_path(shelter_id: @shelter), notice: t("flash.staff.create.success")
      else
        redirect_to shelter_staff_index_path(shelter_id: @shelter), alert: Array(result.errors).join(", ")
      end
    end

    def destroy
      authorize @shelter, :staff_destroy?

      staff_user = @shelter.users.undiscarded.find(params[:id])

      result = Shelters::RemoveStaff.call(
        shelter: @shelter,
        user: current_user,
        staff_user: staff_user
      )

      if result.success?
        redirect_to shelter_staff_index_path(shelter_id: @shelter), notice: t("flash.staff.destroy.success")
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
