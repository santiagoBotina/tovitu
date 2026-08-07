require "rails_helper"

RSpec.describe Shelters::RestoreChecklist do
  describe "#call" do
    let(:shelter) { create(:shelter) }

    context "when the checklist is dismissed" do
      before { shelter.update!(checklist_dismissed_at: Time.current) }

      it "clears checklist_dismissed_at" do
        result = described_class.call(shelter: shelter)
        expect(result).to be_success
        expect(shelter.reload.checklist_dismissed_at).to be_nil
      end
    end

    context "when the checklist is not dismissed" do
      it "is idempotent and returns success" do
        result = described_class.call(shelter: shelter)
        expect(result).to be_success
        expect(shelter.reload.checklist_dismissed_at).to be_nil
      end
    end
  end
end
