class Shelter::PhotosController < ApplicationController
  before_action :require_authentication
  before_action :set_pet

  def create
    authorize @pet, :manage_photos?

    if params[:url].present?
      result = Pets::PhotoManager.attach_by_url(pet: @pet, url: params[:url])
    else
      files = Array(params[:files]).presence || Array(params[:file]).compact
      result = Pets::PhotoManager.attach_many(pet: @pet, files: files)
    end

    respond_to do |format|
      format.turbo_stream { render_media_turbo(result) }
      format.html do
        if result.success?
          redirect_to shelter_pet_path(@pet), notice: photos_notice(result)
        else
          redirect_to shelter_pet_path(@pet), alert: Array(result.errors).join(", ")
        end
      end
    end
  end

  def destroy
    authorize @pet, :manage_photos?

    result = Pets::PhotoManager.detach(pet: @pet, blob_id: params[:id])

    respond_to do |format|
      format.turbo_stream { render_media_turbo(result, notice: t("pets.notices.photo_detached")) }
      format.html do
        if result.success?
          redirect_to shelter_pet_path(@pet), notice: t("pets.notices.photo_detached")
        else
          redirect_to shelter_pet_path(@pet), alert: Array(result.errors).join(", ")
        end
      end
    end
  end

  def update
    authorize @pet, :manage_photos?

    result = Pets::PhotoManager.reorder(pet: @pet, ordered_blob_ids: params[:ordered_blob_ids])

    respond_to do |format|
      format.turbo_stream { render_media_turbo(result, notice: t("pets.notices.photos_reordered")) }
      format.html do
        if result.success?
          redirect_to shelter_pet_path(@pet), notice: t("pets.notices.photos_reordered")
        else
          redirect_to shelter_pet_path(@pet), alert: Array(result.errors).join(", ")
        end
      end
    end
  end

  def set_primary
    authorize @pet, :manage_photos?

    result = Pets::PhotoManager.set_primary(pet: @pet, blob_id: params[:id])

    respond_to do |format|
      format.turbo_stream { render_media_turbo(result, notice: t("pets.notices.primary_set")) }
      format.html do
        if result.success?
          redirect_to media_shelter_pet_path(@pet), notice: t("pets.notices.primary_set")
        else
          redirect_to media_shelter_pet_path(@pet), alert: Array(result.errors).join(", ")
        end
      end
    end
  end

  def move
    authorize @pet, :manage_photos?

    result = Pets::PhotoManager.move(pet: @pet, blob_id: params[:id], direction: params[:direction])

    respond_to do |format|
      format.turbo_stream { render_media_turbo(result, notice: t("pets.notices.photos_reordered")) }
      format.html do
        if result.success?
          redirect_to media_shelter_pet_path(@pet), notice: t("pets.notices.photos_reordered")
        else
          redirect_to media_shelter_pet_path(@pet), alert: Array(result.errors).join(", ")
        end
      end
    end
  end

  private

  def render_media_turbo(result, notice: nil)
    @presented_pet = PetPresenter.new(@pet)
    @notice = result.success? ? (notice || photos_notice(result)) : nil
    @alert = result.errors.any? ? Array(result.errors).join(", ") : nil
    render :media_turbo, status: result.success? ? :ok : :unprocessable_entity
  end

  def photos_notice(result)
    if result.errors.any?
      t("pets.notices.photos_attached_partial")
    else
      t("pets.notices.photos_attached")
    end
  end

  def set_pet
    @pet = current_user.shelter.pets.undiscarded.find(params[:pet_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to shelter_pets_path, alert: t("pets.not_found")
  end
end
