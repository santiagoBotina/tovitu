module Shelters
  class InviteStaff < ApplicationService
    def initialize(shelter:, inviter:, email:)
      @shelter = shelter
      @inviter = inviter
      @email = email.to_s.downcase.strip
    end

    def call
      return Result.failure(I18n.t("errors.invite_staff.not_admin")) unless @inviter.shelter_admin?
      return Result.failure(I18n.t("errors.invite_staff.wrong_shelter")) unless @inviter.shelter_id == @shelter.id
      return Result.failure(I18n.t("errors.invite_staff.invalid_email")) unless @email.match?(URI::MailTo::EMAIL_REGEXP)

      existing_user = User.find_by(email: @email)

      if existing_user
        return Result.failure(I18n.t("errors.invite_staff.already_member", email: @email)) if existing_user.shelter_id == @shelter.id
        return Result.failure(I18n.t("errors.invite_staff.other_shelter", email: @email)) if existing_user.shelter_id.present?

        existing_user.update!(shelter: @shelter, role: "staff")
        return Result.success(nil)
      end

      invitation = @shelter.invitations.new(
        email: @email,
        created_by: @inviter
      )

      invitation.save!
      Result.success(invitation)
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end
  end
end
