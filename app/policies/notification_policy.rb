class NotificationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    record.recipient_id == user.id
  end

  def mark_read?
    show?
  end

  def mark_all_read?
    index?
  end

  def unread_count?
    index?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.where(recipient_id: user.id)
    end
  end
end
