require "rails_helper"

RSpec.describe Notification, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:recipient).class_name("User") }
    it { is_expected.to belong_to(:actor).class_name("User").optional }
    it { is_expected.to belong_to(:notifiable) }
  end

  describe "validations" do
    subject { build(:notification) }

    it { is_expected.to validate_inclusion_of(:kind).in_array(Notification.kinds.keys) }
  end

  describe "enums" do
    it "defines the expected kinds" do
      expected = %w[
        request_submitted request_in_validation
        request_accepted request_declined request_withdrawn
        info_requested info_received message_received
        pet_status_changed welcome
      ]
      expect(Notification.kinds.keys).to match_array(expected)
    end
  end

  describe "scopes" do
    let!(:unread_notification) { create(:notification, :unread) }
    let!(:read_notification) { create(:notification, :read) }

    describe ".unread" do
      it "includes notifications without read_at" do
        expect(Notification.unread).to include(unread_notification)
      end

      it "excludes notifications with read_at set" do
        expect(Notification.unread).not_to include(read_notification)
      end
    end

    describe ".read" do
      it "includes notifications with read_at set" do
        expect(Notification.read).to include(read_notification)
      end

      it "excludes notifications without read_at" do
        expect(Notification.read).not_to include(unread_notification)
      end
    end

    describe ".recent" do
      it "returns notifications ordered by newest first" do
        create(:notification) # this one is now
        travel_to(1.day.ago) { create(:notification) }
        travel_to(3.days.ago) { create(:notification) }
        result = Notification.recent.to_a
        expect(result.first.created_at).to be > result.second.created_at
        expect(result.second.created_at).to be > result.third.created_at
      end
    end
  end

  describe "#mark_as_read!" do
    it "sets read_at to the current time" do
      notification = create(:notification, :unread)
      freeze_time do
        notification.mark_as_read!
        expect(notification.reload.read_at).to be_within(1.second).of(Time.current)
      end
    end

    it "does not change read_at if already read" do
      read_time = 1.hour.ago
      notification = create(:notification, read_at: read_time)
      expect { notification.mark_as_read! }
        .not_to change { notification.reload.read_at }
    end
  end

  describe "#read?" do
    it "returns true when read_at is set" do
      notification = build(:notification, :read)
      expect(notification).to be_read
    end

    it "returns false when read_at is nil" do
      notification = build(:notification, :unread)
      expect(notification).not_to be_read
    end
  end

  describe "#actor_name" do
    it "delegates to actor" do
      actor = build(:user, name: "Jane Doe")
      notification = build(:notification, actor: actor)
      expect(notification.actor_name).to eq("Jane Doe")
    end

    it "returns nil when actor is absent" do
      notification = build(:notification, actor: nil)
      expect(notification.actor_name).to be_nil
    end
  end
end
