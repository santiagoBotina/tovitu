module Authentication
  class ResendVerificationEmail < ApplicationService
    def initialize(user:)
      @user = user
    end

    def call
      return Result.failure("User is already verified") if @user.verified?

      verification_token = @user.email_verification_tokens.create!(
        expires_at: 24.hours.from_now
      )

      AuthenticationMailer.verification(@user, verification_token).deliver_later

      Result.success(nil)
    end
  end
end
