require "rails_helper"

RSpec.describe Notifications::GetUnreadCount do
  let(:recipient) { create(:user) }

  describe "#call" do
    it "returns 0 when there are no notifications" do
      result = described_class.call(recipient: recipient)
      expect(result.data).to eq(0)
    end

    it "counts only unread notifications" do
      create(:notification, :unread, recipient: recipient)
      create(:notification, :read, recipient: recipient)
      result = described_class.call(recipient: recipient)
      expect(result.data).to eq(1)
    end

    it "counts only the recipient's notifications" do
      create(:notification, :unread, recipient: recipient)
      create(:notification, :unread)  # belongs to a different user
      result = described_class.call(recipient: recipient)
      expect(result.data).to eq(1)
    end

    it "returns success" do
      result = described_class.call(recipient: recipient)
      expect(result).to be_success
    end
  end
end
