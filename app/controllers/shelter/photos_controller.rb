class Shelter::PhotosController < ApplicationController
  before_action :require_authentication
  before_action :set_pet

  def create
    authorize @pet, :manage_photos?

    result = Pets::PhotoManager.attach(pet: @pet, file: params[:file])

    if result.success?
      redirect_to shelter_pet_path(@pet), notice: t("pets.notices.photos_attached")
    else
      redirect_to shelter_pet_path(@pet), alert: Array(result.errors).join(", ")
    end
  end

  def destroy
    authorize @pet, :manage_photos?

    result = Pets::PhotoManager.detach(pet: @pet, blob_id: params[:id])

    if result.success?
      redirect_to shelter_pet_path(@pet), notice: t("pets.notices.photo_detached")
    else
      redirect_to shelter_pet_path(@pet), alert: Array(result.errors).join(", ")
    end
  end

  def update
    authorize @pet, :manage_photos?

    result = Pets::PhotoManager.reorder(pet: @pet, ordered_blob_ids: params[:ordered_blob_ids])

    if result.success?
      redirect_to shelter_pet_path(@pet), notice: t("pets.notices.photos_reordered")
    else
      redirect_to shelter_pet_path(@pet), alert: Array(result.errors).join(", ")
    end
  end

  private

  def set_pet
    @pet = current_user.shelter.pets.undiscarded.find(params[:shelter_pet_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to shelter_pets_path, alert: t("pets.not_found")
  end
end
