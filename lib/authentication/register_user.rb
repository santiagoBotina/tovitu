module Authentication
  class RegisterUser < ApplicationService
    VALID_ROLES = %w[adopter shelter_admin shelter_staff].freeze

    def initialize(name:, email:, password:, password_confirmation:, role: "adopter", locale: nil)
      @name = name
      @email = email
      @password = password
      @password_confirmation = password_confirmation
      @role = role
      @locale = locale
    end

    def call
      return Result.failure([ I18n.t("errors.register_user.invalid_role") ]) unless VALID_ROLES.include?(@role)

      user = User.new(
        name: @name,
        email: @email,
        password: @password,
        password_confirmation: @password_confirmation,
        role: @role,
        locale: @locale
      )

      return Result.failure(user.errors.full_messages) unless user.save

      verification_token = user.email_verification_tokens.create!(
        expires_at: 24.hours.from_now
      )

      AuthenticationMailer.verification(user, verification_token).deliver_later

      Result.success(
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        verified: user.verified?
      )
    end
  end
end
