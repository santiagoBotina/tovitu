# frozen_string_literal: true

require "rails_helper"

RSpec.describe MaintenanceJob do
  let(:shelter) { create(:shelter) }

  describe "queue routing" do
    it "routes to the default queue (provisioned as tovitu-jobs)" do
      expect(described_class.queue_name).to eq("default")
    end
  end

  describe "#perform" do
    it "marks documents stuck in processing past the timeout as failed" do
      stale = create(:ai_document, shelter: shelter, status: "processing", updated_at: 2.hours.ago)
      fresh = create(:ai_document, shelter: shelter, status: "processing")
      ready = create(:ai_document, shelter: shelter, status: "ready", updated_at: 2.days.ago)

      described_class.perform_now

      expect(stale.reload.status).to eq("failed")
      expect(stale.reload.error_message).to eq(I18n.t("jobs.maintenance.document_timeout"))
      expect(fresh.reload.status).to eq("processing")
      expect(ready.reload.status).to eq("ready")
    end

    it "marks stale documents as failed regardless of shelter" do
      other_shelter = create(:shelter)
      stale = create(:ai_document, shelter: other_shelter, status: "processing", updated_at: 3.hours.ago)

      described_class.perform_now

      expect(stale.reload.status).to eq("failed")
    end
  end
end
