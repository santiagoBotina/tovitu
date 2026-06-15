module Authentication
  class ResetPassword < ApplicationService
    def initialize(token:, password:, password_confirmation:)
      @token_string = token
      @password = password
      @password_confirmation = password_confirmation
    end

    def call
      token = PasswordResetToken.valid_token(@token_string)
      return Result.failure("Invalid password reset link", error_code: :invalid_token) unless token
      return Result.failure("Password reset link has expired", error_code: :expired) if token.expired?

      user = token.user

      ActiveRecord::Base.transaction do
        user.update!(
          password: @password,
          password_confirmation: @password_confirmation
        )
        token.consume!
      end

      Result.success(
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role
      )
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(e.record.errors.full_messages)
    end
  end
end
