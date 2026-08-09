module Pets
  class SavesController < ApplicationController
    before_action :set_pet

    def create
      if signed_in?
        was_done = current_user.saved_pets.exists?
        current_user.saved_pets.find_or_create_by!(pet: @pet)
        @milestone_notice = milestone_unlocked_message(current_user, :first_saved_pet, was_done: was_done)
      else
        session[:saved_pet_ids] = (session[:saved_pet_ids] || []) | [ @pet.id ]
      end

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: pets_path, notice: @milestone_notice || t(".saved") }
        format.json { head :ok }
      end
    end

    def destroy
      if signed_in?
        current_user.saved_pets.find_by(pet: @pet)&.destroy
      else
        session[:saved_pet_ids] = (session[:saved_pet_ids] || []) - [ @pet.id ]
      end

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_back fallback_location: pets_path, notice: t(".unsaved") }
        format.json { head :ok }
      end
    end

    private

    def set_pet
      @pet = Pet.find(params[:pet_id])
    end
  end
end
