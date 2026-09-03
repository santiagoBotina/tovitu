class ShelterPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def new?
    user.present? && user.verified? && user.shelter_id.nil?
  end

  def create?
    new?
  end

  # Umbrella rule for managing shelter settings (profile/info) and admin
  # utilities (checklist dismiss/restore). Owner-only per the permission
  # matrix (BR-46-2).
  def manage?
    user.present? && user.shelter_owner? && user.shelter_id == record.id
  end

  def edit?
    manage?
  end

  def update?
    manage?
  end

  # Requires an active shelter membership (or a platform admin/staff account
  # attached to the shelter). A user with only a stray `shelter_id` and no
  # `shelter_role` is not granted the dashboard.
  def dashboard?
    user.present? && user.shelter_id == record.id &&
      (user.shelter_member? || user.admin? || user.staff?)
  end

  # Viewing the staff list is granted to owner + administrator; all staff
  # management actions (invite, change role, remove, cancel invitations)
  # are owner-only (BR-46-2, DP-1).
  def staff_index?
    user.present? && user.shelter_id == record.id &&
      (user.shelter_owner? || user.shelter_administrator?)
  end

  def staff_create?
    manage?
  end

  def staff_destroy?
    manage?
  end

  def staff_change_role?
    manage?
  end

  def invitations_cancel?
    manage?
  end

  def policies_edit?
    manage_policies?
  end

  def policies_update?
    manage_policies?
  end

  # Managing adoption policies is granted to owner + administrator.
  def manage_policies?
    user.present? && user.shelter_id == record.id &&
      (user.shelter_owner? || user.shelter_administrator?)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.active.undiscarded
    end
  end
end
