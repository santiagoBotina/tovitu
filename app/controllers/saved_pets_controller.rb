class SavedPetsController < ApplicationController
  MAX_IMPORT_IDS = 20

  def index
    if signed_in?
      saved_pet_ids = current_user.saved_pets.pluck(:pet_id)
      @favorites_import = current_user.favorites_imports.latest.first
    else
      saved_pet_ids = session[:saved_pet_ids] || []
    end

    @pets = Pet.where(id: saved_pet_ids)
    @presented_pets = @pets.map { |pet| PetPresenter.new(pet) }
  end

  # Kicks off a background import of localStorage interests after account
  # creation. The client sends the pet ids; the server persists them in a
  # FavoritesImport record (the source of truth for status) and enqueues
  # FavoritesImportJob. The user can keep browsing while it runs.
  def import
    unless signed_in?
      redirect_to new_session_path, alert: t("saved_pets.import.require_login") and return
    end
    unless current_user.individual?
      redirect_to saved_pets_path, alert: t("saved_pets.import.require_individual") and return
    end

    # Accepts both comma-joined ("1,2,3") and array ("pet_ids[]=1&pet_ids[]=2")
    # param shapes. Non-numeric junk is dropped by to_i, so garbage input is a
    # no-op, never an error.
    pet_ids = Array(params[:pet_ids]).flat_map { |v| v.to_s.split(",") }
                                    .map(&:to_i).uniq.first(MAX_IMPORT_IDS)

    if pet_ids.empty?
      respond_to do |format|
        format.turbo_stream { head :ok }
        format.html { redirect_to saved_pets_path }
        format.json { head :ok }
      end
      return
    end

    # Reuse an in-flight or failed import instead of stacking duplicate
    # records (multi-tab auto-imports, retries after a failure). A pending
    # import keeps running with merged ids; a failed one is reset and
    # re-enqueued; otherwise a fresh record is created.
    @favorites_import = current_user.favorites_imports.latest.first

    if @favorites_import&.pending?
      merged_ids = (@favorites_import.requested_ids + pet_ids).uniq.first(MAX_IMPORT_IDS)
      @favorites_import.update!(requested_ids: merged_ids, total_count: merged_ids.length)
    elsif @favorites_import&.failed?
      @favorites_import.update!(
        status: "pending",
        requested_ids: pet_ids,
        total_count: pet_ids.length,
        imported_count: 0,
        error: nil,
        completed_at: nil
      )
      FavoritesImportJob.perform_later(@favorites_import.id)
    else
      @favorites_import = current_user.favorites_imports.create!(
        status: "pending",
        requested_ids: pet_ids,
        total_count: pet_ids.length
      )
      FavoritesImportJob.perform_later(@favorites_import.id)
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to saved_pets_path, notice: t("saved_pets.import.importing") }
      format.json { render json: import_status_json(@favorites_import) }
    end
  end

  # Polled by the Saved pets page while an import is in flight. Returns a
  # turbo_stream that updates the notice (and the list once the import lands).
  def import_status
    @favorites_import = current_user&.favorites_imports&.latest&.first

    if @favorites_import&.completed?
      saved_pet_ids = current_user.saved_pets.pluck(:pet_id)
      @pets = Pet.where(id: saved_pet_ids)
      @presented_pets = @pets.map { |pet| PetPresenter.new(pet) }
    end

    respond_to do |format|
      format.turbo_stream
      format.json { render json: import_status_json(@favorites_import) }
    end
  end

  # Re-runs a failed import from its persisted requested_ids (no localStorage
  # needed — the server kept the list).
  def retry_import
    unless signed_in?
      redirect_to new_session_path, alert: t("saved_pets.import.require_login") and return
    end

    @favorites_import = current_user.favorites_imports.find(params[:favorites_import_id])

    if @favorites_import.failed?
      @favorites_import.update!(
        status: "pending",
        imported_count: 0,
        error: nil,
        completed_at: nil
      )
      FavoritesImportJob.perform_later(@favorites_import.id)
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to saved_pets_path }
    end
  end

  private

  def import_status_json(favorites_import)
    return { status: "none" } unless favorites_import

    {
      status: favorites_import.status,
      imported_count: favorites_import.imported_count,
      total_count: favorites_import.total_count
    }
  end
end