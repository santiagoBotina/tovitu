module Shelters
  class RemoveStaff < ApplicationService
    def initialize(shelter:, user:, staff_user:)
      @shelter = shelter
      @user = user
      @staff_user = staff_user
    end

    def call
      return Result.failure(I18n.t("errors.remove_staff.not_owner")) unless @user.shelter_owner?
      return Result.failure(I18n.t("errors.remove_staff.wrong_shelter")) unless @user.shelter_id == @shelter.id
      return Result.failure(I18n.t("errors.remove_staff.cannot_remove_self")) if @user.id == @staff_user.id
      return Result.failure(I18n.t("errors.remove_staff.not_member", name: @staff_user.name)) unless @staff_user.shelter_id == @shelter.id
      return Result.failure(I18n.t("errors.remove_staff.cannot_remove_owner")) if @staff_user.shelter_owner?

      # Clear the membership and, when the removed user's account type was a
      # shelter role, reset it so they are no longer routed through shelter
      # flows (login/sidebar) after removal.
      new_role = @staff_user.shelter_account_type? ? "individual" : @staff_user.role
      @staff_user.update!(shelter: nil, shelter_role: nil, role: new_role)
      Result.success(nil)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end
  end
end
