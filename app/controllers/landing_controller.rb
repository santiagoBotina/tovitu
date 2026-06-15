class LandingController < ApplicationController
  before_action :require_no_authentication, only: [ :index ]

  def index
  end
end
