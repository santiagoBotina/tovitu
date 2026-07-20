require "rails_helper"

RSpec.describe Notifications::MarkAsRead do
  let(:recipient) { create(:user) }
  let(:notification) { create(:notification, :unread, recipient: recipient) }

  describe "#call" do
    context "with a single notification" do
      it "marks the notification as read" do
        expect {
          described_class.call(notification_or_ids: notification, recipient: recipient)
        }.to change { notification.reload.read_at }.from(nil)
      end

      it "returns success with count of 1" do
        result = described_class.call(notification_or_ids: notification, recipient: recipient)
        expect(result).to be_success
        expect(result.data[:count]).to eq(1)
      end

      it "does not mark notifications belonging to other users" do
        other_user = create(:user)
        result = described_class.call(notification_or_ids: notification, recipient: other_user)
        expect(result.data[:count]).to eq(0)
        expect(notification.reload.read_at).to be_nil
      end
    end

    context "with an array of notification IDs" do
      let(:notifications) { create_list(:notification, 3, :unread, recipient: recipient) }

      it "marks all given notifications as read" do
        ids = notifications.map(&:id)
        expect {
          described_class.call(notification_or_ids: ids, recipient: recipient)
        }.to change { Notification.unread.count }.by(-3)
      end

      it "returns success with correct count" do
        ids = notifications.map(&:id)
        result = described_class.call(notification_or_ids: ids, recipient: recipient)
        expect(result.data[:count]).to eq(3)
      end
    end

    context "with a single ID" do
      it "accepts an integer ID" do
        result = described_class.call(notification_or_ids: notification.id, recipient: recipient)
        expect(result.data[:count]).to eq(1)
        expect(notification.reload.read_at).to be_present
      end
    end
  end

  describe Notifications::MarkAsRead::All do
    let!(:unread_notifications) { create_list(:notification, 3, :unread, recipient: recipient) }
    let!(:other_notification) { create(:notification, :unread) }

    it "marks all notifications as read for the recipient" do
      expect {
        described_class.call(recipient: recipient)
      }.to change { recipient.notifications.unread.count }.from(3).to(0)
    end

    it "does not mark other users' notifications" do
      described_class.call(recipient: recipient)
      expect(other_notification.reload.read_at).to be_nil
    end

    it "returns success with correct count" do
      result = described_class.call(recipient: recipient)
      expect(result).to be_success
      expect(result.data[:count]).to eq(3)
    end

    it "handles zero unread notifications gracefully" do
      Notification.where(recipient: recipient).update_all(read_at: Time.current)
      result = described_class.call(recipient: recipient)
      expect(result.data[:count]).to eq(0)
    end
  end
end
