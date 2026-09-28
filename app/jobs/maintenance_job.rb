class MaintenanceJob < ApplicationJob
  queue_as :default

  # Nightly maintenance sweep, invoked by the EventBridge Scheduler rule
  # `tovitu-nightly-maintenance` (see .localstack/06-scheduler.sh) via the
  # invocation-spec handler in Queuing::Worker.
  #
  # Marks AI documents stuck in `processing` past the timeout as `failed`, so
  # an ingestion that died mid-run (worker crash, lost SQS message, killed
  # process) surfaces instead of blocking the RAG pipeline forever.
  DOCUMENT_PROCESSING_TIMEOUT = 1.hour

  def perform(*)
    stale_documents.update_all(
      status: "failed",
      error_message: I18n.t("jobs.maintenance.document_timeout")
    )
  end

  private

  def stale_documents
    Ai::Document.where(status: "processing")
      .where("updated_at < ?", DOCUMENT_PROCESSING_TIMEOUT.ago)
  end
end
