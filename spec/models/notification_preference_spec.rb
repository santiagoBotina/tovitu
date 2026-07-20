require "rails_helper"

RSpec.describe NotificationPreference, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { build(:notification_preference) }

    it { is_expected.to validate_inclusion_of(:in_app).in_array([true, false]) }
    it { is_expected.to validate_inclusion_of(:email).in_array([true, false]) }
    it { is_expected.to validate_inclusion_of(:whatsapp).in_array([true, false]) }
  end

  describe "scopes" do
    describe ".whatsapp_opted_in" do
      let!(:opted_in) { create(:notification_preference, :whatsapp_opted_in) }
      let!(:not_opted_in) { create(:notification_preference, :whatsapp_opted_out) }

      it "includes users with whatsapp enabled and verified" do
        expect(described_class.whatsapp_opted_in).to include(opted_in)
      end

      it "excludes users without whatsapp enabled" do
        expect(described_class.whatsapp_opted_in).not_to include(not_opted_in)
      end
    end

    describe ".whatsapp_verified" do
      let!(:verified) { create(:notification_preference, :whatsapp_opted_in) }
      let!(:unverified) { create(:notification_preference) }

      it "includes users with whatsapp_verified_at set" do
        expect(described_class.whatsapp_verified).to include(verified)
      end

      it "excludes users without whatsapp_verified_at" do
        expect(described_class.whatsapp_verified).not_to include(unverified)
      end
    end
  end

  describe "#channel_enabled?" do
    let(:preference) { build(:notification_preference, in_app: true, email: false, whatsapp: false) }

    it "returns true for enabled channel" do
      expect(preference.channel_enabled?(:in_app)).to be true
    end

    it "returns false for disabled channel" do
      expect(preference.channel_enabled?(:email)).to be false
    end
  end

  describe "#kind_enabled?" do
    let(:preference) do
      build(:notification_preference,
        in_app: true,
        email: false,
        per_kind_overrides: { "request_submitted" => { "email" => true } })
    end

    it "uses per-kind override when present" do
      expect(preference.kind_enabled?(:request_submitted, :email)).to be true
    end

    it "falls back to channel default when no override" do
      expect(preference.kind_enabled?(:request_accepted, :email)).to be false
    end

    it "uses channel default when kind override lacks channel key" do
      preference.update!(per_kind_overrides: { "request_submitted" => { "whatsapp" => true } })
      expect(preference.kind_enabled?(:request_submitted, :email)).to be false
    end
  end

  describe ".defaults_for" do
    let(:user) { create(:user) }

    it "creates a new preference with default values" do
      preference = described_class.defaults_for(user)
      expect(preference).to be_persisted
      expect(preference.in_app).to be true
      expect(preference.email).to be true
      expect(preference.whatsapp).to be false
    end

    it "returns existing preference if already present" do
      existing = create(:notification_preference, user: user, in_app: false)
      preference = described_class.defaults_for(user)
      expect(preference).to eq(existing)
      expect(preference.in_app).to be false
    end
  end
end
