class PetPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    return true if record.status_available? && record.undiscarded?
    return false unless user.present? && user.shelter_id.present?

    user.shelter_id == record.shelter_id
  end

  def create?
    user.present? && user.shelter_id.present?
  end

  def update?
    user.present? && user.shelter_id.present? && user.shelter_id == record.shelter_id
  end

  def destroy?
    update?
  end

  def bulk_update?
    user.present? && user.shelter_id.present?
  end

  def manage_photos?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.present? && user.shelter_id.present?
        scope.undiscarded.where(shelter_id: user.shelter_id)
      else
        scope.searchable
      end
    end
  end
end
