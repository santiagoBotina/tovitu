require "rails_helper"

RSpec.describe Shelters::OnboardingChecklist do
  subject(:checklist) { described_class.new(shelter) }

  describe "step conditions" do
    context "with a bare shelter" do
      let(:shelter) { create(:shelter) }

      # Note: a fresh shelter is already "active" (publish step done), but the
      # remaining setup steps keep it far from completed.
      it "reports not completed with fewer steps done than total" do
        expect(checklist.done_count).to be < checklist.total_count
        expect(checklist).not_to be_completed
      end

      it "reports setup steps as not done" do
        %i[add_pet policies staff hours profile].each do |key|
          expect(checklist.step_done?(key)).to be(false)
        end
      end
    end

    context "with a fully configured shelter" do
      let(:shelter) do
        create(:shelter).tap do |s|
          create(:pet, shelter: s)
          create(:user, :verified, shelter: s, role: "staff")
          s.update!(
            adoption_policies: { "adoption_fee" => "150" },
            hours: "Mon-Fri 9-5",
            description: "A great place for pets"
          )
        end
      end

      it "reports all steps done and completed" do
        expect(checklist.done_count).to eq(6)
        expect(checklist).to be_completed
      end
    end

    context "with team members in either staff role spelling" do
      let(:shelter) { create(:shelter) }

      it "counts the staff step done for an invited member (role: staff)" do
        create(:user, :verified, shelter: shelter, role: "staff")
        expect(checklist.step_done?(:staff)).to be(true)
      end

      it "counts the staff step done for a shelter_staff member" do
        create(:user, :verified, shelter: shelter, role: "shelter_staff")
        expect(checklist.step_done?(:staff)).to be(true)
      end

      it "does not count the owning shelter_admin as team" do
        create(:user, :shelter_admin, shelter: shelter)
        expect(checklist.step_done?(:staff)).to be(false)
      end

      it "does not count a discarded staff member" do
        create(:user, :verified, :discarded, shelter: shelter, role: "staff")
        expect(checklist.step_done?(:staff)).to be(false)
      end
    end
  end

  describe "dismissed state" do
    let(:shelter) { create(:shelter) }

    it "is false when checklist_dismissed_at is nil" do
      expect(checklist).not_to be_dismissed
    end

    it "is true when checklist_dismissed_at is set" do
      shelter.update!(checklist_dismissed_at: Time.current)
      expect(checklist).to be_dismissed
    end
  end

  describe "unknown step key" do
    let(:shelter) { create(:shelter) }

    it "raises ArgumentError" do
      expect { checklist.step_done?(:not_a_step) }.to raise_error(ArgumentError, /unknown checklist step/)
    end
  end
end
