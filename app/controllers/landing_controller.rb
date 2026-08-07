class LandingController < ApplicationController
  before_action :redirect_signed_in_users, only: [ :index ]

  def index
  end

  private

  # Redirect signed-in users away from the marketing page without a flash.
  # The "already logged in" notice is reserved for the login/registration flows
  # (see require_no_authentication in ApplicationController).
  def redirect_signed_in_users
    redirect_to after_sign_in_path if signed_in?
  end
end
