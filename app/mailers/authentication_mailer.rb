class AuthenticationMailer < ApplicationMailer
  HEADER = "X-Tovitu-Notification-Id"

  def verification(user, token)
    @user = user
    @token = token

    render_in_user_locale(user) do
      @verification_url = verification_url(token: token.token)
      mail to: user.email, subject: t(".subject")
    end
  end

  def password_reset(user, token)
    @user = user
    @token = token

    render_in_user_locale(user) do
      @password_reset_url = edit_password_reset_url(token.token)
      mail to: user.email, subject: t(".subject")
    end
  end

  def email_changed(user)
    @user = user
    render_in_user_locale(user) do
      mail to: user.email, subject: t(".subject")
    end
  end

  # Delivered once, after email verification (see Authentication::VerifyEmail),
  # so it never races the verification email at signup.
  def welcome(user, notification_id = nil)
    @user = user
    render_in_user_locale(user) do
      headers[HEADER] = notification_id.to_s if notification_id.present?
      mail to: user.email, subject: t(".subject")
    end
  end

  private

  def render_in_user_locale(user)
    @locale = user&.locale.presence || I18n.default_locale
    I18n.with_locale(@locale) { yield }
  end
end
