class NotificationsController < ApplicationController
  before_action :require_authentication

  def index
    authorize Notification
    @notifications = policy_scope(Notification)
                       .includes(:actor, :notifiable)
                       .recent

    if params[:kind].present? && Notification.kinds.key?(params[:kind])
      @notifications = @notifications.where(kind: Notification.kinds[params[:kind]])
    end

    @grouped = @notifications.group_by { |n| notification_group(n.created_at) }
  end

  def show
    @notification = Notification.find(params[:id])
    authorize @notification
    @notification.mark_as_read! unless @notification.read_at?
    redirect_to @notification.action_url.presence || adoption_requests_path
  end

  def mark_read
    @notification = Notification.find(params[:id])
    authorize @notification

    Notifications::MarkAsRead.call(notification_or_ids: @notification, recipient: current_user)

    head :ok
  end

  def mark_all_read
    authorize Notification

    Notifications::MarkAsRead::All.call(recipient: current_user)
    count = Notification.where(recipient: current_user, read_at: nil).count

    respond_to do |format|
      format.json { render json: { count: count } }
      format.html { redirect_back fallback_location: notifications_path, notice: t("notifications.index.mark_all_read_success") }
    end
  end

  def unread_count
    authorize Notification

    result = Notifications::GetUnreadCount.call(recipient: current_user)
    count = result.success? ? result.data : 0

    respond_to do |format|
      format.json { render json: { count: count } }
      format.turbo_stream { render turbo_stream: turbo_stream.replace("notification_badge", partial: "notifications/badge", locals: { count: count }) }
    end
  end

  private

  def notification_group(date)
    return t("notifications.index.today") if date.today?
    return t("notifications.index.yesterday") if date.yesterday?
    return t("notifications.index.this_week") if date > 1.week.ago
    t("notifications.index.older")
  end
end
