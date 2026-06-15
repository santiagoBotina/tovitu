module Authentication
  class AuthenticateUser < ApplicationService
    def initialize(email:, password:, ip_address: "0.0.0.0", user_agent: nil)
      @email = email.to_s.downcase.strip
      @password = password
      @ip_address = ip_address
      @user_agent = user_agent
    end

    def call
      if LoginAttempt.locked_out?(@email)
        remaining = LoginAttempt.lockout_remaining_seconds(@email)
        return Result.failure(
          "Account temporarily locked. Try again in #{remaining} seconds.",
          error_code: :locked
        )
      end

      user = User.undiscarded.find_by(email: @email)

      if user && user.authenticate(@password)
        log_attempt(success: true)

        if user.verified?
          Result.success(
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
            verified: true
          )
        else
          Authentication::ResendVerificationEmail.call(user: user)
          Result.failure(
            "Please verify your email before logging in. A new verification email has been sent.",
            error_code: :unverified
          )
        end
      else
        log_attempt(success: false)
        Result.failure("Invalid email or password", error_code: :invalid_credentials)
      end
    end

    private

    def log_attempt(success:)
      LoginAttempt.create!(
        email: @email,
        ip_address: @ip_address,
        user_agent: @user_agent,
        attempted_at: Time.current,
        success: success
      )
    rescue ActiveRecord::RecordInvalid
      nil
    end
  end
end
