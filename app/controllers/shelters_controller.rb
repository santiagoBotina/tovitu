class SheltersController < ApplicationController
  before_action :require_authentication, only: %i[new create edit update]
  before_action :set_shelter, only: %i[show edit update]

  def index
    @shelters = Shelters::DirectorySearch.call(params: filter_params)
    skip_authorization
  end

  def show
    authorize @shelter
  end

  def new
    @shelter = Shelter.new
    authorize @shelter
  end

  def create
    @shelter = Shelter.new(shelter_params)
    authorize @shelter

    result = Shelters::Register.call(user: current_user, shelter_params: shelter_params)

    if result.success?
      redirect_to shelter_dashboard_path(shelter_id: result.data), notice: t("flash.shelters.create.success")
    else
      @shelter = Shelter.new(shelter_params)
      @shelter.validate
      flash.now[:alert] = Array(result.errors).join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @shelter
  end

  def update
    authorize @shelter

    result = Shelters::UpdateProfile.call(shelter: @shelter, user: current_user, params: shelter_params)

    if result.success?
      redirect_to shelter_path(id: @shelter), notice: t("flash.shelters.update.success")
    else
      flash.now[:alert] = Array(result.errors).join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_shelter
    @shelter = Shelter.undiscarded.find(params[:id])
  end

  def shelter_params
    params.require(:shelter).permit(
      :name, :street, :city, :state, :zip, :phone, :website,
      :description, :hours, :status, species_served: []
    )
  end

  def filter_params
    params.permit(:city, :state, :species)
  end
end
