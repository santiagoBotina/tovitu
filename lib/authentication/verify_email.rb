module Authentication
  class VerifyEmail < ApplicationService
    def initialize(token:)
      @token_string = token
    end

    def call
      token = EmailVerificationToken.valid_token(@token_string)
      return Result.failure(I18n.t("errors.verify_email.invalid"), error_code: :invalid_token) unless token
      return Result.failure(I18n.t("errors.verify_email.expired"), error_code: :expired) if token.expired?

      user = token.user

      ActiveRecord::Base.transaction do
        user.update!(verified_at: Time.current)
        token.consume!
      end

      deliver_welcome(user)

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

    private

    # The `welcome` notification fires here — after verification, never at
    # signup — so the welcome email cannot race the verification email.
    def deliver_welcome(user)
      Notifications::Deliver.call(
        recipient: user,
        kind: :welcome,
        notifiable: user,
        title: I18n.t("notifications.titles.welcome"),
        body: I18n.t("notifications.bodies.welcome"),
        action_url: Rails.application.routes.url_helpers.pets_path(locale: user.locale || I18n.locale),
        metadata: {}
      )
    end
  end
end
