require "rails_helper"

RSpec.describe "Notifications" do
  let(:user) { create(:user, :verified) }

  before do
    post session_path, params: { session: { email: user.email, password: "password123" } }
  end

  describe "GET /notifications" do
    it "returns a successful response" do
      get notifications_path
      expect(response).to have_http_status(:ok)
    end

    it "displays the user's notifications" do
      notification = create(:notification, recipient: user)
      get notifications_path
      expect(response.body).to include(notification.title)
    end

    it "does not display other users' notifications" do
      other_user = create(:user)
      other_notification = create(:notification, recipient: other_user)
      get notifications_path
      expect(response.body).not_to include(other_notification.title)
    end

    it "filters by kind when param is present" do
      create(:notification, :request_accepted, recipient: user, title: "UniqueAccepted123")
      create(:notification, :request_submitted, recipient: user, title: "UniqueSubmitted456", read_at: Time.current)

      get notifications_path, params: { kind: "request_accepted" }
      expect(response.body).to include("UniqueAccepted123")
      expect(response.body).not_to include("UniqueSubmitted456")
    end

    it "groups notifications by date" do
      # Use Time.current (Rails time zone) so the "today" notification cannot
      # drift into "yesterday" when the system clock is ahead of the app zone.
      create(:notification, recipient: user, created_at: Time.current)
      create(:notification, recipient: user, created_at: 2.days.ago)
      get notifications_path
      expect(response.body).to include(I18n.t("notifications.index.today"))
      expect(response.body).to include(I18n.t("notifications.index.this_week"))
    end

    context "when unauthenticated" do
      before { delete session_path }

      it "redirects to root" do
        get notifications_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /notifications/:id" do
    let(:notification) { create(:notification, recipient: user, action_url: "/some/path") }

    it "marks the notification as read" do
      expect {
        get notification_path(notification)
      }.to change { notification.reload.read_at }.from(nil)
    end

    it "redirects to the notification's action_url" do
      get notification_path(notification)
      expect(response).to redirect_to("/some/path")
    end

    it "redirects to adoption_requests path when action_url is blank" do
      notification.update!(action_url: nil)
      get notification_path(notification)
      expect(response).to redirect_to(adoption_requests_path)
    end

    it "prevents access to other users' notifications" do
      other_notification = create(:notification)
      get notification_path(other_notification)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /notifications/:id/mark_read" do
    let(:notification) { create(:notification, :unread, recipient: user) }

    it "marks the notification as read" do
      expect {
        patch mark_read_notification_path(notification)
      }.to change { notification.reload.read_at }.from(nil)
    end

    it "returns no content" do
      patch mark_read_notification_path(notification)
      expect(response).to have_http_status(:ok)
    end

    it "prevents marking other users' notifications" do
      other_notification = create(:notification, :unread)
      patch mark_read_notification_path(other_notification)
      expect(other_notification.reload.read_at).to be_nil
    end
  end

  describe "PATCH /notifications/mark_all_read" do
    let!(:notifications) { create_list(:notification, 3, :unread, recipient: user) }

    it "marks all user's notifications as read" do
      expect {
        patch mark_all_read_notifications_path
      }.to change { user.notifications.unread.count }.from(3).to(0)
    end

    it "redirects back for HTML requests" do
      patch mark_all_read_notifications_path
      expect(response).to have_http_status(:redirect)
    end

    it "returns the remaining unread count as JSON when the client requests JSON" do
      patch mark_all_read_notifications_path, headers: { accept: "application/json" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq({ "count" => 0 })
    end
  end

  describe "GET /notifications/unread_count" do
    let!(:unread) { create_list(:notification, 2, :unread, recipient: user) }
    let!(:read_notification) { create(:notification, :read, recipient: user) }

    it "returns the unread count as JSON" do
      get unread_count_notifications_path, headers: { accept: "application/json" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq({ "count" => 2 })
    end

    it "returns Turbo Stream format" do
      get unread_count_notifications_path, headers: { accept: "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "notification bell URL injection" do
    # Regression for Bug 2.1b: the bell JS previously polled locale-less paths
    # (/notifications/unread_count) which did not match any route.
    it "renders locale-scoped notification URLs as data attributes on the bell" do
      get notifications_path
      expect(response.body).to include(
        %(data-notification-bell-unread-count-url-value="#{unread_count_notifications_path}")
      )
      expect(response.body).to include(
        %(data-notification-bell-mark-all-read-url-value="#{mark_all_read_notifications_path}")
      )
    end
  end
end
