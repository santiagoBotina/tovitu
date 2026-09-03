module Shelters
  class ChangeRole < ApplicationService
    def initialize(shelter:, actor:, member:, new_role:)
      @shelter = shelter
      @actor = actor
      @member = member
      @new_role = new_role.to_s
    end

    def call
      return Result.failure(I18n.t("errors.change_role.not_owner")) unless @actor.shelter_owner?
      return Result.failure(I18n.t("errors.change_role.wrong_shelter")) unless @actor.shelter_id == @shelter.id
      return Result.failure(I18n.t("errors.change_role.not_member", name: @member.name)) unless @member.shelter_id == @shelter.id
      return Result.failure(I18n.t("errors.change_role.cannot_change_owner")) if @member.shelter_owner?
      return Result.failure(I18n.t("errors.change_role.invalid_role")) unless User::SHELTER_ROLES.include?(@new_role)
      return Result.failure(I18n.t("errors.change_role.owner_not_assignable")) if @new_role == "owner"

      @member.update!(shelter_role: @new_role)
      Result.success(@member)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end
  end
end
