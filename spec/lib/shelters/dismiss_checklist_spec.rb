require "rails_helper"

RSpec.describe Shelters::DismissChecklist do
  describe "#call" do
    let(:shelter) { create(:shelter) }

    context "when the checklist is complete" do
      before do
        create(:pet, shelter: shelter)
        create(:user, :verified, shelter: shelter, role: "staff")
        shelter.update!(
          adoption_policies: { "adoption_fee" => "150" },
          hours: "Mon-Fri 9-5",
          description: "A great place for pets"
        )
      end

      it "persists checklist_dismissed_at" do
        result = described_class.call(shelter: shelter)
        expect(result).to be_success
        expect(shelter.reload.checklist_dismissed_at).to be_present
      end

      it "is idempotent when already dismissed" do
        shelter.update!(checklist_dismissed_at: 1.day.ago)
        result = described_class.call(shelter: shelter)
        expect(result).to be_success
        expect(shelter.reload.checklist_dismissed_at).to be_within(1.minute).of(1.day.ago)
      end
    end

    context "when the checklist is incomplete" do
      it "returns a failure and does not dismiss" do
        result = described_class.call(shelter: shelter)
        expect(result).to be_failure
        expect(shelter.reload.checklist_dismissed_at).to be_nil
      end
    end
  end
end
