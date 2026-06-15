class PetsController < ApplicationController
  before_action :set_pet, only: [:show]

  def index
    @pets = Pets::Search.call(params: index_params)
    @pets = @pets.includes(:shelter, photos_attachments: :blob)
    @presented_pets = @pets.map { |pet| PetPresenter.new(pet) }
    skip_authorization

    respond_to do |format|
      format.html
    end
  end

  def show
    authorize @pet
    @pet = PetPresenter.new(@pet)
  end

  private

  def set_pet
    @pet = Pet.undiscarded.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to pets_path, alert: t("pets.not_found")
  end

  def index_params
    params.permit(:locale, :page, :per_page, :species, :breed, :age_category, :size, :sex,
                  :city, :state, :good_with_children, :good_with_dogs, :good_with_cats,
                  :query, :shelter_id)
  end
end
