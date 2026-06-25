require "rails_helper"

RSpec.describe AdoptionNote, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:adoption_application).touch(true) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:content) }
  end

  describe "scopes" do
    let(:app) { create(:adoption_application) }
    let!(:pinned_note) { create(:adoption_note, adoption_application: app, pinned: true, created_at: 1.day.ago) }
    let!(:recent_note) { create(:adoption_note, adoption_application: app, pinned: false, created_at: 1.hour.ago) }
    let!(:old_note) { create(:adoption_note, adoption_application: app, pinned: false, created_at: 2.days.ago) }

    it "pinned_first returns pinned notes first, then by created_at desc" do
      result = AdoptionNote.pinned_first
      expect(result.first).to eq(pinned_note)
    end

    it "pinned returns only pinned notes" do
      expect(AdoptionNote.pinned).to include(pinned_note)
      expect(AdoptionNote.pinned).not_to include(recent_note, old_note)
    end

    it "unpinned returns only unpinned notes" do
      expect(AdoptionNote.unpinned).to include(recent_note, old_note)
      expect(AdoptionNote.unpinned).not_to include(pinned_note)
    end
  end
end
