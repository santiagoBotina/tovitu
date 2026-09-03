require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:email_verification_tokens).dependent(:destroy) }
    it { is_expected.to have_many(:password_reset_tokens).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }

    it "validates email uniqueness case-insensitively" do
      create(:user, email: "test@example.com")
      user = build(:user, email: "TEST@example.com")
      user.valid?
      expect(user.errors[:email]).to include("has already been taken")
    end
    it { is_expected.to allow_value("user@example.com").for(:email) }
    it { is_expected.not_to allow_value("invalid-email").for(:email) }
    it { is_expected.to validate_inclusion_of(:role).in_array(%w[admin staff]) }

    context "when new record" do
      subject { build(:user) }
      it { is_expected.to validate_length_of(:password).is_at_least(8) }
    end
  end

  describe "secure password" do
    it "has has_secure_password" do
      user = create(:user, password: "securepass1", password_confirmation: "securepass1")
      expect(user.authenticate("securepass1")).to be_truthy
      expect(user.authenticate("wrongpass")).to be_falsey
    end
  end

  describe "email normalization" do
    it "downcases and strips email before validation" do
      user = create(:user, email: "  Test@Example.COM  ")
      expect(user.email).to eq("test@example.com")
    end
  end

  describe "#verified?" do
    it "returns true when verified_at is set" do
      user = build(:user, :verified)
      expect(user).to be_verified
    end

    it "returns false when verified_at is nil" do
      user = build(:user)
      expect(user).not_to be_verified
    end
  end

  describe "#staff?" do
    it "returns true for staff role" do
      user = build(:user, role: "staff")
      expect(user).to be_staff
    end

    it "returns false for admin role" do
      user = build(:user, role: "admin")
      expect(user).not_to be_staff
    end
  end

  describe "#admin?" do
    it "returns true for admin role" do
      user = build(:user, role: "admin")
      expect(user).to be_admin
    end

    it "returns false for staff role" do
      user = build(:user, role: "staff")
      expect(user).not_to be_admin
    end
  end

  describe "#discard / #undiscard / #discarded?" do
    it "marks user as discarded" do
      user = create(:user)
      expect { user.discard }.to change(user, :discarded_at).from(nil)
      expect(user).to be_discarded
    end

    it "restores a discarded user" do
      user = create(:user, :discarded)
      expect { user.undiscard }.to change(user, :discarded_at).to(nil)
      expect(user).not_to be_discarded
    end
  end

  describe "shelter roles" do
    it "exposes the shelter role predicates" do
      owner = build(:user, shelter_role: "owner")
      administrator = build(:user, shelter_role: "administrator")
      staff_member = build(:user, shelter_role: "staff_member")

      expect(owner).to be_shelter_owner
      expect(owner).not_to be_shelter_administrator
      expect(administrator).to be_shelter_administrator
      expect(staff_member).to be_shelter_staff_member
      expect([ owner, administrator, staff_member ]).to all(be_shelter_member)
    end

    it "is false for users without a shelter role" do
      user = build(:user)
      expect(user).not_to be_shelter_member
      expect(user).not_to be_shelter_owner
    end

    it "derives the shelter role from the legacy role when a shelter is present" do
      shelter = create(:shelter)
      admin = build(:user, role: "shelter_admin", shelter: shelter)
      admin.valid?
      expect(admin.shelter_role).to eq("owner")

      staff = build(:user, role: "shelter_staff", shelter: shelter)
      staff.valid?
      expect(staff.shelter_role).to eq("staff_member")
    end

    it "keeps a manually assigned shelter role when both are present" do
      shelter = create(:shelter)
      administrator = build(:user, role: "shelter_staff", shelter_role: "administrator", shelter: shelter)
      administrator.valid?
      expect(administrator.shelter_role).to eq("administrator")
    end

    it "maps legacy predicates to the shelter role" do
      owner = build(:user, shelter_role: "owner")
      staff_member = build(:user, shelter_role: "staff_member")

      expect(owner).to be_shelter_admin
      expect(staff_member).to be_shelter_staff
    end
  end

  describe "scopes" do
    let!(:verified_user) { create(:user, :verified) }
    let!(:unverified_user) { create(:user) }
    let!(:discarded_user) { create(:user, :discarded) }

    it "includes verified users" do
      expect(User.verified).to include(verified_user)
      expect(User.verified).not_to include(unverified_user)
    end

    it "includes unverified users" do
      expect(User.unverified).to include(unverified_user)
      expect(User.unverified).not_to include(verified_user)
    end

    it "includes undiscarded users only" do
      expect(User.undiscarded).to include(verified_user, unverified_user)
      expect(User.undiscarded).not_to include(discarded_user)
    end
  end
end
