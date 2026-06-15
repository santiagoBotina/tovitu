module Shelters
  class AcceptInvitation < ApplicationService
    def initialize(token:, user:)
      @token = token
      @user = user
    end

    def call
      invitation = Invitation.find_by(token: @token)
      return Result.failure(I18n.t("errors.accept_invitation.invalid")) unless invitation
      return Result.failure(I18n.t("errors.accept_invitation.expired")) if invitation.expired?
      return Result.failure(I18n.t("errors.accept_invitation.accepted")) if invitation.accepted?

      ActiveRecord::Base.transaction do
        @user.update!(shelter: invitation.shelter, role: "staff")
        invitation.accept!
      end

      Result.success(invitation.shelter)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end
  end
end
