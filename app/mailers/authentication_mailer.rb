class AuthenticationMailer < ApplicationMailer
  def verification(user, token)
    @user = user
    @token = token
    @verification_url = verification_url(token: token.token)

    mail to: user.email, subject: t(".subject")
  end

  def password_reset(user, token)
    @user = user
    @token = token
    @password_reset_url = edit_password_reset_url(token.token)

    mail to: user.email, subject: t(".subject")
  end

  def email_changed(user)
    @user = user
    mail to: user.email, subject: t(".subject")
  end
end
