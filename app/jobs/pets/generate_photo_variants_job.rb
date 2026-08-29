# Pre-generates the canonical photo variants (thumb/medium/large) for a pet
# photo right after upload, so the first page view never pays the on-demand
# variant generation cost (download original from S3 + process + re-upload).
#
# The job is best-effort: if a blob is missing or unprocessable the upload
# already succeeded, so we log and move on — the on-demand path in
# PetPresenter remains as a fallback.
#
# Runs on the dedicated `variants` queue (SQS: <prefix>-variants) so image
# processing is isolated from AI/import jobs and mailers. Run a dedicated
# worker with `SQS_QUEUES=variants bin/rails queuing:work` for isolation and
# scale; otherwise the default worker polls it alongside the other queues.
class Pets::GeneratePhotoVariantsJob < ApplicationJob
  queue_as :variants

  def perform(blob_id)
    attachment = ActiveStorage::Attachment.find_by(blob_id: blob_id)
    return unless attachment

    Pets::PhotoVariants.keys.each do |variant|
      Pets::PhotoVariants.for(attachment, variant).processed
    rescue StandardError => e
      Rails.logger.warn "Photo variant pre-generation failed blob=#{blob_id} variant=#{variant}: #{e.class} #{e.message}"
    end
  end
end
