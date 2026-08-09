class SavedPetsController < ApplicationController
  MAX_IMPORT_IDS = 20

  def index
    if signed_in?
      saved_pet_ids = current_user.saved_pets.pluck(:pet_id)
    else
      saved_pet_ids = session[:saved_pet_ids] || []
    end

    @pets = Pet.where(id: saved_pet_ids)
    @presented_pets = @pets.map { |pet| PetPresenter.new(pet) }
  end

  # One-time import of localStorage interests after account creation.
  # Best-effort: only available pets are imported, count is capped, and the
  # client clears its local copy on success (see interest_import_controller).
  def import
    unless signed_in?
      redirect_to new_session_path, alert: t("saved_pets.import.require_login") and return
    end
    unless current_user.individual?
      redirect_to saved_pets_path, alert: t("saved_pets.import.require_individual") and return
    end

    # Accepts both comma-joined ("1,2,3") and array ("pet_ids[]=1&pet_ids[]=2")
    # param shapes. Non-numeric junk is dropped by to_i and filtered by the
    # Pet.available scope, so garbage input is a no-op, never an error.
    pet_ids = Array(params[:pet_ids]).flat_map { |v| v.to_s.split(",") }
                                    .map(&:to_i).uniq.first(MAX_IMPORT_IDS)
    @imported = 0
    Pet.available.where(id: pet_ids).find_each do |pet|
      current_user.saved_pets.find_or_create_by!(pet: pet)
      @imported += 1
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to saved_pets_path, notice: import_notice(@imported) }
    end
  end

  private

  def import_notice(count)
    case count
    when 0 then t("saved_pets.import.imported_none")
    when 1 then t("saved_pets.import.imported_one")
    else t("saved_pets.import.imported_other", count: count)
    end
  end
end
