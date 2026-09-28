module Adoptions
  module Evaluation
    # Collects the current adopter signals the evaluation rules read. This is
    # the single source of truth for what the evaluation can see — all values
    # come from real stored data, never inferred (plan 25 honesty rule).
    class Signals
      def self.call(request:)
        new(request: request).call
      end

      def initialize(request:)
        @request = request
        @adopter = request.adopter
        @profile = @adopter.individual_profile
      end

      def call
        {
          account_age_days: (Time.current.to_date - @adopter.created_at.to_date).to_i,
          email_verified: @adopter.verified_at.present?,
          age_years: @profile&.age_years,
          profile_completeness: completeness,
          pet_experience: @profile&.pet_experience,
          daily_time_available: @profile&.daily_time_available,
          adoption_priority_present: @profile&.adoption_priority.present?,
          home_environment: @profile&.home_environment,
          other_pets: @profile&.other_pets,
          additional_answers_present: @request.additional_answers.present?,
          prior_decline_same_pet: prior_decline_same_pet?
        }
      end

      private

      attr_reader :request, :adopter, :profile

      def completeness
        return nil if profile.blank?

        {
          answered: profile.onboarding_answer_count,
          total: profile.total_onboarding_questions,
          fraction: profile.profile_completeness
        }
      end

      def prior_decline_same_pet?
        adopter.adoption_requests
               .where(pet_id: request.pet_id)
               .where.not(id: request.id)
               .where(status: %w[declined withdrawn])
               .exists?
      end
    end
  end
end
