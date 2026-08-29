require "rails_helper"

RSpec.describe FavoritesImport, type: :model do
  describe "validations" do
    it "is valid with a user and requested ids" do
      import = build(:favorites_import)
      expect(import).to be_valid
    end

    it "requires requested ids" do
      import = build(:favorites_import, requested_ids: [])
      expect(import).not_to be_valid
    end

    it "restricts status to the known set" do
      expect { create(:favorites_import, status: "bogus") }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "status helpers" do
    it "reports pending/completed/failed" do
      expect(build(:favorites_import, status: "pending")).to be_pending
      expect(build(:favorites_import, status: "completed")).to be_completed
      expect(build(:favorites_import, status: "failed")).to be_failed
    end
  end

  describe "scopes" do
    it "orders latest first" do
      user = create(:user)
      older = create(:favorites_import, user: user, created_at: 2.days.ago)
      newer = create(:favorites_import, user: user, created_at: 1.day.ago)

      expect(user.favorites_imports.latest.first).to eq(newer)
      expect(user.favorites_imports.latest.to_a).to eq([ newer, older ])
    end
  end
end
