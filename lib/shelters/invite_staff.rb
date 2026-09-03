module Shelters
  class InviteStaff < ApplicationService
    def initialize(shelter:, inviter:, email:, role:)
      @shelter = shelter
      @inviter = inviter
      @email = email.to_s.downcase.strip
      @role = role.to_s
    end

    def call
      return Result.failure(I18n.t("errors.invite_staff.not_owner")) unless @inviter.shelter_owner?
      return Result.failure(I18n.t("errors.invite_staff.wrong_shelter")) unless @inviter.shelter_id == @shelter.id
      return Result.failure(I18n.t("errors.invite_staff.invalid_email")) unless @email.match?(URI::MailTo::EMAIL_REGEXP)
      return Result.failure(I18n.t("errors.invite_staff.owner_not_invitable")) if @role == "owner"
      return Result.failure(I18n.t("errors.invite_staff.invalid_role")) unless Invitation::ROLES.include?(@role)

      existing_user = User.find_by(email: @email)

      if existing_user
        return Result.failure(I18n.t("errors.invite_staff.already_member", email: @email)) if existing_user.shelter_id == @shelter.id
        return Result.failure(I18n.t("errors.invite_staff.other_shelter", email: @email)) if existing_user.shelter_id.present?
      end

      if @shelter.invitations.pending.where(email: @email).exists?
        return Result.failure(I18n.t("errors.invite_staff.already_invited", email: @email))
      end

      invitation = @shelter.invitations.new(
        email: @email,
        created_by: @inviter,
        role: @role
      )

      invitation.save!
      Result.success(invitation)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end
  end
end
