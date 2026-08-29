# Processes a batch pet import in the background. The PetImport record is the
# server-side source of truth for status: the record starts `pending`, moves to
# `processing`, and ends `completed` (with a persisted summary) or `failed`
# (with a human-readable error). On any unhandled error the record is marked
# failed and the job does NOT raise, so the worker acks the message and the
# shelter can retry from the UI instead of entering a retry loop.
class PetImportJob < ApplicationJob
  queue_as :default

  def perform(pet_import_id)
    import = PetImport.find_by(id: pet_import_id)
    return unless import&.pending?

    import.update!(status: "processing")

    unless import.file.attached?
      return mark_failed(import, I18n.t("shelter.pet_imports.errors.file_missing"))
    end

    import.file.open do |file|
      parse = Pets::ImportParser.call(path: file.path, filename: import.file_name)
      return mark_failed(import, parse.errors) if parse.failure?

      result = Pets::ImportProcessor.call(
        shelter: import.shelter,
        user: import.user,
        rows: parse.data[:rows]
      )

      import.update!(
        status: "completed",
        imported_count: result.data[:imported].length,
        duplicate_count: result.data[:duplicates].length,
        error_count: result.data[:errors].length,
        total_count: parse.data[:rows].length,
        summary: result.data,
        error: nil,
        completed_at: Time.current
      )
    end
  rescue StandardError => e
    mark_failed(import, e.message)
    Rails.logger.error "PetImportJob failed for import #{pet_import_id}: #{e.class} #{e.message}"
  end

  private

  def mark_failed(import, message)
    import&.update!(
      status: "failed",
      error: Array(message).join(", "),
      completed_at: Time.current
    )
  end
end
