class Shelter::PetsController < ApplicationController
  before_action :require_authentication
  before_action :set_shelter_pet, only: [ :show, :edit, :update, :destroy ]
  before_action :require_shelter

  def index
    @pets = policy_scope(Pet).undiscarded.where(shelter_id: current_user.shelter_id)
                             .order(created_at: :desc)
                             .includes(photos_attachments: :blob)
    @pets = @pets.where(status: params[:status]) if params[:status].present?
    @presented_pets = @pets.map { |pet| PetPresenter.new(pet) }
  end

  def show
    authorize @pet
    @pet = PetPresenter.new(@pet)
  end

  def new
    @pet = Pet.new(shelter: current_shelter)
    authorize @pet
  end

  def create
    @pet = Pet.new(shelter: current_shelter)
    authorize @pet

    result = Pets::Create.call(
      shelter: current_shelter,
      params: pet_params.except(:photos),
      photos: Array(params[:pet]&.dig(:photos))
    )

    if result.success?
      redirect_to shelter_pet_path(id: result.data), notice: t("pets.notices.created")
    else
      @pet = Pet.new(pet_params.except(:photos))
      @pet.shelter = current_shelter
      flash.now[:alert] = Array(result.errors).join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @pet
  end

  def update
    authorize @pet

    result = Pets::Update.call(pet: @pet, params: pet_params.except(:photos))

    if result.success?
      redirect_to shelter_pet_path(id: @pet), notice: t("pets.notices.updated")
    else
      flash.now[:alert] = Array(result.errors).join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @pet
    @pet.discard!
    redirect_to shelter_pets_path, notice: t("pets.notices.destroyed")
  end

  def change_status
    authorize @pet

    result = Pets::ChangeStatus.call(pet: @pet, new_status: params[:status])

    if result.success?
      redirect_to shelter_pet_path(id: @pet), notice: t("pets.notices.status_changed", status: t("pets.status.#{result.data.status}"))
    else
      redirect_to shelter_pet_path(id: @pet), alert: Array(result.errors).join(", ")
    end
  end

  def bulk_update
    authorize Pet

    result = Pets::BulkUpdate.call(
      shelter: current_shelter,
      pet_ids: params[:pet_ids],
      new_status: params[:new_status]
    )

    if result.success?
      redirect_to shelter_pets_path, notice: t("pets.notices.bulk_updated", count: result.data[:updated_count])
    else
      redirect_to shelter_pets_path, alert: Array(result.errors).join(", ")
    end
  end

  private

  def set_shelter_pet
    @pet = current_shelter.pets.undiscarded.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to shelter_pets_path, alert: t("pets.not_found")
  end

  def require_shelter
    unless current_user.shelter_id.present?
      redirect_to root_path, alert: t("flash.unauthorized")
    end
  end

  def current_shelter
    @current_shelter ||= current_user.shelter
  end

  def pet_params
    params.require(:pet).permit(
      :name, :species, :breed, :age_category, :birth_date, :size, :sex,
      :description, :personality_traits, :medical_notes,
      :spayed_neutered, :vaccinated, :special_needs,
      :good_with_children, :good_with_dogs, :good_with_cats,
      :requirements, :personality_spec, :adopter_tips,
      photos: []
    ).tap do |p|
      p[:personality_traits] = p[:personality_traits].to_s.split(",").map(&:strip).reject(&:blank?) if p[:personality_traits].present?
    end
  end
end
