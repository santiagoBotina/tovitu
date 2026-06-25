class SavedPetsController < ApplicationController
  def index
    if signed_in?
      saved_pet_ids = current_user.saved_pets.pluck(:pet_id)
    else
      saved_pet_ids = session[:saved_pet_ids] || []
    end

    @pets = Pet.where(id: saved_pet_ids)
    @presented_pets = @pets.map { |pet| present(pet) }
  end
end
