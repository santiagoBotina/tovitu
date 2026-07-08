class DashboardController < ApplicationController
  before_action :require_authentication

  def index
    if current_user.shelter_user? && current_user.shelter_id.present?
      redirect_to shelter_dashboard_path(shelter_id: current_user.shelter_id) and return
    end

    @onboarding_complete = current_user.onboarding_completed?

    @adoption_requests = AdoptionRequest
      .where(adopter_id: current_user.id)
      .includes(:pet, :shelter)
      .order(updated_at: :desc)
      .limit(3)

    @total_requests_count = AdoptionRequest
      .where(adopter_id: current_user.id)
      .count

    @show_onboarding = !@onboarding_complete

    # Compute adoption readiness percentage
    @readiness_percent = compute_readiness

    # Fetch saved pets for top matches display
    @saved_pets = current_user.saved_pets
      .includes(:pet)
      .order(created_at: :desc)
      .limit(2)
      .map(&:pet)
  end

  private

  def compute_readiness
    base = 0
    # Profile completion: up to 40%
    if @onboarding_complete
      base += 40
    elsif current_user.adopter_profile
      step = current_user.adopter_profile.onboarding_step.to_f
      total_questions = Onboarding::Adopter::QuestionsData.count.to_f
      base += ((step / total_questions) * 40).to_i if total_questions > 0
    end
    # Active engagement: up to 35%
    base += 20 if @total_requests_count > 0
    base += 15 if @adoption_requests.any? { |r| %w[pending in_validation].include?(r.status) }
    # Saved pets: up to 25%
    saved_count = current_user.saved_pets.count
    base += [saved_count * 8, 25].min
    [base, 100].min
  end
end
