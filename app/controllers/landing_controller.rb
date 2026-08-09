class LandingController < ApplicationController
  before_action :redirect_signed_in_users, only: [ :index ]

  FEATURED_PETS_LIMIT = 6

  def index
    @featured_pets = Pet.available.includes(:shelter, photos_attachments: :blob)
                        .order(created_at: :desc)
                        .limit(FEATURED_PETS_LIMIT)
    @presented_featured_pets = @featured_pets.map { |pet| PetPresenter.new(pet) }
  end

  private

  # Redirect signed-in users away from the marketing page without a flash.
  # The "already logged in" notice is reserved for the login/registration flows
  # (see require_no_authentication in ApplicationController).
  def redirect_signed_in_users
    redirect_to after_sign_in_path if signed_in?
  end
end
