module Authentication
  class VerifyEmail < ApplicationService
    def initialize(token:)
      @token_string = token
    end

    def call
      token = EmailVerificationToken.valid_token(@token_string)
      return Result.failure("Invalid verification link", error_code: :invalid_token) unless token
      return Result.failure("Verification link has expired", error_code: :expired) if token.expired?

      user = token.user

      ActiveRecord::Base.transaction do
        user.update!(verified_at: Time.current)
        token.consume!
      end

      Result.success(
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        verified: true
      )
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      Result.failure(e.message)
    end
  end
end
