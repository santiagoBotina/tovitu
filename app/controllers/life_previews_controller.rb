class LifePreviewsController < ApplicationController
  def show
    @pet = Pet.undiscarded.find(params[:pet_id])
    authorize @pet, :show?
    @pet = PetPresenter.new(@pet)

    if @pet.life_preview_data.present? && !@pet.life_preview_stale?
      render partial: "pets/life_preview", locals: { pet: @pet, preview_data: @pet.life_preview_data }
    else
      Ai::GenerateLifePreviewJob.perform_later(@pet.id, I18n.locale.to_s)
      render partial: "pets/life_preview_loading", locals: { pet: @pet }
    end
  end
end
