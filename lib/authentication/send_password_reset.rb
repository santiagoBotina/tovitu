module Authentication
  class SendPasswordReset < ApplicationService
    def initialize(email:)
      @email = email.to_s.downcase.strip
    end

    def call
      user = User.undiscarded.find_by(email: @email)

      return Result.success(nil) unless user
      return Result.success(nil) unless user.verified?

      reset_token = user.password_reset_tokens.create!(
        expires_at: 1.hour.from_now
      )

      AuthenticationMailer.password_reset(user, reset_token).deliver_later

      Result.success(nil)
    end
  end
end
