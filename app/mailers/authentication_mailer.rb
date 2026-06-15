class AuthenticationMailer < ApplicationMailer
  def verification(user, token)
    @user = user
    @token = token
    @verification_url = verification_url(token: token.token)

    mail to: user.email, subject: "Verify your email address"
  end

  def password_reset(user, token)
    @user = user
    @token = token
    @password_reset_url = edit_password_reset_url(token.token)

    mail to: user.email, subject: "Reset your password"
  end

  def email_changed(user)
    @user = user
    mail to: user.email, subject: "Your email address has been changed"
  end
end
