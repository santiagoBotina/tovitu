require "rails_helper"

RSpec.describe NotificationPreference, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { build(:notification_preference) }

    it { is_expected.to validate_inclusion_of(:in_app).in_array([ true, false ]) }
    it { is_expected.to validate_inclusion_of(:email).in_array([ true, false ]) }
    it { is_expected.to validate_inclusion_of(:whatsapp).in_array([ true, false ]) }
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

    it "global OFF wins over a per-kind override that would enable the channel" do
      expect(preference.kind_enabled?(:request_submitted, :email)).to be false
    end

    it "falls back to channel default when no override" do
      expect(preference.kind_enabled?(:request_accepted, :email)).to be false
    end

    it "uses channel default when kind override lacks channel key" do
      preference.update!(per_kind_overrides: { "request_submitted" => { "whatsapp" => true } })
      expect(preference.kind_enabled?(:request_submitted, :email)).to be false
    end

    it "returns true when the channel is on globally and no override exists" do
      preference.update!(email: true)
      expect(preference.kind_enabled?(:request_submitted, :email)).to be true
    end

    it "respects an explicit per-kind disable when the channel is on globally" do
      preference.update!(email: true, per_kind_overrides: { "request_submitted" => { "email" => false } })
      expect(preference.kind_enabled?(:request_submitted, :email)).to be false
    end

    it "respects a per-kind enable when the channel is on globally" do
      preference.update!(email: true, per_kind_overrides: { "request_submitted" => { "email" => true } })
      expect(preference.kind_enabled?(:request_submitted, :email)).to be true
    end

    it "applies per-kind overrides per channel" do
      preference.update!(email: true, whatsapp: true, per_kind_overrides: { "request_submitted" => { "whatsapp" => false } })
      expect(preference.kind_enabled?(:request_submitted, :email)).to be true
      expect(preference.kind_enabled?(:request_submitted, :whatsapp)).to be false
    end

    it "preserves per-kind overrides when the global toggle is off (re-enabling restores them)" do
      preference.update!(email: true, per_kind_overrides: { "request_submitted" => { "email" => false } })
      preference.update!(email: false)
      expect(preference.per_kind_enabled?(:request_submitted, :email)).to be false
      preference.update!(email: true)
      expect(preference.kind_enabled?(:request_submitted, :email)).to be false
    end
  end

  describe "#per_kind_enabled?" do
    let(:preference) { build(:notification_preference, email: true) }

    it "defaults to true when there is no override" do
      expect(preference.per_kind_enabled?(:request_submitted, :email)).to be true
    end

    it "returns the override value when present" do
      preference.per_kind_overrides = { "request_submitted" => { "email" => "0" } }
      expect(preference.per_kind_enabled?(:request_submitted, :email)).to be false
    end

    it "is independent of the global toggle" do
      preference.email = false
      expect(preference.per_kind_enabled?(:request_submitted, :email)).to be true
    end
  end

  describe "#per_kind_overrides=" do
    it "coerces form checkbox values to booleans" do
      preference = build(:notification_preference)
      preference.per_kind_overrides = { "request_submitted" => { "email" => "1" }, "welcome" => { "email" => "0" } }
      expect(preference.per_kind_overrides).to eq(
        { "request_submitted" => { "email" => true }, "welcome" => { "email" => false } }
      )
    end

    it "accepts nil" do
      preference = build(:notification_preference)
      expect { preference.per_kind_overrides = nil }.not_to raise_error
    end
  end

  describe ".ui_kinds" do
    it "only includes kinds that can be triggered today" do
      expect(described_class.ui_kinds).to match_array(
        %w[request_submitted request_in_validation request_accepted request_declined request_withdrawn welcome]
      )
    end

    it "excludes deferred kinds" do
      expect(described_class.ui_kinds).not_to include("message_received", "pet_status_changed", "info_requested", "info_received")
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
