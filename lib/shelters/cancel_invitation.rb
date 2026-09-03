module Shelters
  class CancelInvitation < ApplicationService
    def initialize(shelter:, actor:, invitation:)
      @shelter = shelter
      @actor = actor
      @invitation = invitation
    end

    def call
      return Result.failure(I18n.t("errors.cancel_invitation.not_owner")) unless @actor.shelter_owner?
      return Result.failure(I18n.t("errors.cancel_invitation.wrong_shelter")) unless @actor.shelter_id == @shelter.id
      return Result.failure(I18n.t("errors.cancel_invitation.wrong_shelter")) unless @invitation.shelter_id == @shelter.id
      return Result.failure(I18n.t("errors.cancel_invitation.already_accepted")) if @invitation.accepted?
      return Result.failure(I18n.t("errors.cancel_invitation.already_cancelled")) if @invitation.cancelled?

      @invitation.cancel!
      Result.success(nil)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end
  end
end
