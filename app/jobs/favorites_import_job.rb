# Imports a user's locally-saved pet interests into real SavedPet records in
# the background. The FavoritesImport record is the server-side source of truth
# for the import status, so the Saved pets page can show progress that survives
# navigation and refreshes.
#
# Best-effort semantics:
# - Only currently available pets are imported (unavailable ones are skipped).
# - find_or_create_by keeps the import idempotent — pre-existing favorites are
#   preserved and never duplicated.
# - On failure the record is marked `failed` (with a human-readable error) and
#   the job does NOT raise, so the worker acks the message and the user can
#   retry from the UI instead of being stuck in an automatic retry loop.
class FavoritesImportJob < ApplicationJob
  queue_as :default

  def perform(favorites_import_id)
    import = FavoritesImport.find_by(id: favorites_import_id)
    return unless import&.pending?

    user = import.user
    imported = 0

    Pet.available.where(id: import.requested_ids).find_each do |pet|
      user.saved_pets.find_or_create_by!(pet: pet)
      imported += 1
    end

    import.update!(
      status: "completed",
      imported_count: imported,
      error: nil,
      completed_at: Time.current
    )
  rescue StandardError => e
    import&.update!(
      status: "failed",
      error: e.message,
      completed_at: Time.current
    )
    Rails.logger.error "FavoritesImportJob failed for import #{favorites_import_id}: #{e.class} #{e.message}"
  end
end