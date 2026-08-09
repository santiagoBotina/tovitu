class ApplicationMailer < ActionMailer::Base
  default from: "Tovitu <noreply@tovitu.com>"
  layout "mailer"

  # Mailers don't inherit ApplicationController#default_url_options, so they
  # must build locale-scoped URLs themselves. `@locale` is set by each mailer's
  # locale wrapper; fall back to the current I18n locale (which ActiveJob
  # serializes at enqueue time) for URLs built before the wrapper runs.
  # `super` merges the host/port from config.action_mailer.default_url_options.
  def default_url_options
    super.merge(locale: @locale.presence || I18n.locale)
  end
end
