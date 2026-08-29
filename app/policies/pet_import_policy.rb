# Authorization for shelter batch pet imports. Only shelter staff can start,
# view, and poll imports; all records are scoped to the current user's shelter.
class PetImportPolicy < ApplicationPolicy
  def index?
    shelter_staff?
  end

  def create?
    shelter_staff?
  end

  def new?
    shelter_staff?
  end

  def show?
    shelter_staff? && record.shelter_id == user.shelter_id
  end

  def status?
    shelter_staff?
  end

  def template?
    shelter_staff?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.shelter_id.present? ? scope.where(shelter_id: user.shelter_id) : scope.none
    end
  end

  private

  def shelter_staff?
    user.present? && user.shelter_id.present?
  end
end
