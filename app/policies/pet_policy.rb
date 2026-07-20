class PetPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    return true if record.undiscarded? && (record.status_available? || record.status_on_hold?)
    return false unless user.present?

    if record.shelter_id.present?
      user.shelter_id == record.shelter_id
    elsif record.publisher_id.present?
      user.id == record.publisher_id
    else
      false
    end
  end

  def create?
    return true if user.present? && user.individual?
    user.present? && user.shelter_id.present?
  end

  def update?
    return true if user.individual? && record.publisher_id == user.id
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
      if user.present? && user.individual?
        scope.undiscarded.where(publisher_id: user.id).or(scope.searchable)
      elsif user.present? && user.shelter_id.present?
        scope.undiscarded.where(shelter_id: user.shelter_id)
      else
        scope.searchable
      end
    end
  end
end
