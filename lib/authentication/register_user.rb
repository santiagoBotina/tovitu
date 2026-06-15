module Authentication
  class RegisterUser < ApplicationService
    def initialize(name:, email:, password:, password_confirmation:)
      @name = name
      @email = email
      @password = password
      @password_confirmation = password_confirmation
    end

    def call
      user = User.new(
        name: @name,
        email: @email,
        password: @password,
        password_confirmation: @password_confirmation,
        role: "staff"
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
