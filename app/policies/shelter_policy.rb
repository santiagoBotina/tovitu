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

  def edit?
    user.present? && user.shelter_admin? && user.shelter_id == record.id
  end

  def update?
    edit?
  end

  def dashboard?
    user.present? && user.shelter_id == record.id
  end

  def staff_index?
    user.present? && user.shelter_admin? && user.shelter_id == record.id
  end

  def staff_create?
    staff_index?
  end

  def staff_destroy?
    staff_index?
  end

  def policies_edit?
    user.present? && user.shelter_admin? && user.shelter_id == record.id
  end

  def policies_update?
    policies_edit?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.active.undiscarded
    end
  end
end
