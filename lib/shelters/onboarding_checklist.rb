module Shelters
  # Domain model for the shelter onboarding checklist.
  #
  # Single source of truth for what counts as a "done" onboarding step and for
  # the aggregate state of the checklist (completed? / dismissed?). Both the
  # shelter dashboard presenter and the checklist dismissal services read
  # completion from here so the conditions never drift apart.
  class OnboardingChecklist
    # Roles that count as a shelter's team members for the "staff" step.
    # Both spellings exist in User::ROLES: "staff" is produced by the invite
    # flow (InviteStaff / AcceptInvitation), while "shelter_staff" is a
    # registerable/legacy spelling treated as a shelter team role everywhere
    # else (auth, notification routing). shelter_admin (the owner) is
    # intentionally excluded — the step asks whether the shelter has built a
    # team beyond the founding admin.
    STAFF_ROLES = %w[staff shelter_staff].freeze

    STEPS = [
      { key: :add_pet,  done: ->(shelter) { shelter.pets.undiscarded.exists? } },
      { key: :policies, done: ->(shelter) { shelter.adoption_policies.values.any?(&:present?) } },
      { key: :staff,    done: ->(shelter) { shelter.users.undiscarded.where(role: STAFF_ROLES).exists? } },
      { key: :hours,    done: ->(shelter) { shelter.hours.present? } },
      { key: :profile,  done: ->(shelter) { shelter.description.present? } },
      { key: :publish,  done: ->(shelter) { shelter.active? } }
    ].freeze

    def initialize(shelter)
      @shelter = shelter
    end

    def completed?
      done_count == total_count
    end

    def done_count
      STEPS.count { |step| step[:done].call(@shelter) }
    end

    def total_count
      STEPS.size
    end

    def dismissed?
      @shelter.checklist_dismissed_at.present?
    end

    def step_done?(key)
      step = STEPS.find { |s| s[:key] == key }
      raise ArgumentError, "unknown checklist step: #{key}" unless step

      step[:done].call(@shelter)
    end
  end
end
