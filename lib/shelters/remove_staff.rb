module Shelters
  class RemoveStaff < ApplicationService
    def initialize(shelter:, user:, staff_user:)
      @shelter = shelter
      @user = user
      @staff_user = staff_user
    end

    def call
      return Result.failure(I18n.t("errors.remove_staff.not_admin")) unless @user.shelter_admin?
      return Result.failure(I18n.t("errors.remove_staff.wrong_shelter")) unless @user.shelter_id == @shelter.id
      return Result.failure(I18n.t("errors.remove_staff.cannot_remove_self")) if @user.id == @staff_user.id
      return Result.failure(I18n.t("errors.remove_staff.not_member", name: @staff_user.name)) unless @staff_user.shelter_id == @shelter.id

      if @staff_user.admin? && @shelter.users.admin.count <= 1
        return Result.failure(I18n.t("errors.remove_staff.last_admin"))
      end

      @staff_user.update!(shelter: nil, role: "staff")
      Result.success(nil)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end
  end
end
