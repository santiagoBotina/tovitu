module Ai
  module Adopter
    # Compiles the PII-free evidence base for an adopter from data that is
    # already persisted (onboarding answers + passive behavioral signals).
    #
    # Business rules enforced here:
    #   - Rule 2: no name, email, phone, or exact address ever leaves this object.
    #   - Rule 10: reuse existing data before inventing new collection.
    class SignalCollector < ApplicationService
      def initialize(adopter:)
        @adopter = adopter
        super()
      end

      def call
        payload = {
          profile: profile_signals,
          behavior: behavior_signals
        }
        payload[:fingerprint] = fingerprint_for(payload)
        payload
      end

      private

      attr_reader :adopter

      def profile_signals
        profile = adopter.individual_profile
        return {} if profile.blank?

        {
          weekend_activity: Array(profile.weekend_activity),
          activity_level: profile.activity_level,
          ideal_companion: profile.ideal_companion,
          pet_experience: profile.pet_experience,
          adoption_goals: Array(profile.adoption_goals),
          daily_time_available: profile.daily_time_available,
          personality: profile.personality,
          adoption_priority: sanitize_text(profile.adoption_priority)
        }.compact
      end

      def behavior_signals
        requests = adopter.adoption_requests
        saved = adopter.saved_pets.includes(:pet)

        {
          account_age_days: (Time.current.to_date - adopter.created_at.to_date).to_i,
          onboarding_completed: adopter.onboarding_completed?,
          saved_pets_count: saved.size,
          saved_pets: saved.limit(8).map do |saved_pet|
            {
              species: saved_pet.pet.species,
              size: saved_pet.pet.size,
              personality_traits: Array(saved_pet.pet.personality_traits).first(3)
            }
          end,
          requests_count: requests.size,
          active_requests_count: requests.active.size,
          withdrawn_requests_count: requests.withdrawn.size,
          requests_last_30_days: requests.where(created_at: 30.days.ago..).count,
          unique_species_applied_to: requests.joins(:pet).distinct.pluck("pets.species"),
          followed_through_ratio: followed_through_ratio(requests),
          avg_response_hours: average_response_hours(requests)
        }
      end

      # Fraction of the adopter's completed requests that were not withdrawn by
      # them (accepted / accepted+withdrawn). Declined requests are excluded:
      # rejection is the shelter's decision, not evidence of adopter follow-through.
      def followed_through_ratio(requests)
        accepted = requests.where(status: :accepted).count
        withdrawn = requests.where(status: :withdrawn).count
        return nil if (accepted + withdrawn).zero?

        (accepted.to_f / (accepted + withdrawn)).round(2)
      end

      # Derived response latency: average hours from request creation to the
      # adopter's own next action on that request (today: withdrawal). Derived
      # from existing timestamps only — no new instrumentation.
      def average_response_hours(requests)
        withdrawn = requests.withdrawn.where.not(withdrawn_at: nil)
        return nil if withdrawn.empty?

        hours = withdrawn.map { |r| (r.withdrawn_at - r.created_at) / 1.hour }
        (hours.sum / hours.size).round(1)
      end

      def sanitize_text(text)
        Ai::Sanitizer.text(text)
      end

      def fingerprint_for(payload)
        Digest::SHA256.hexdigest(payload.to_json)
      end
    end
  end
end
