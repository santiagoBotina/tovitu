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

  # Umbrella rule for managing shelter settings (info, staff, adoption policies).
  # Admin-only: shelter owners can manage their own shelter; staff cannot.
  def manage?
    user.present? && user.shelter_admin? && user.shelter_id == record.id
  end

  def edit?
    manage?
  end

  def update?
    manage?
  end

  def dashboard?
    user.present? && user.shelter_id == record.id
  end

  def staff_index?
    manage?
  end

  def staff_create?
    manage?
  end

  def staff_destroy?
    manage?
  end

  def policies_edit?
    manage?
  end

  def policies_update?
    manage?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.active.undiscarded
    end
  end
end
