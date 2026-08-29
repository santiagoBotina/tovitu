module Gamification
  # Computes the adopter's "Adoption Journey" — a lightweight, honest set of
  # progress signals derived entirely from existing models (no points, levels,
  # or leaderboards). It powers:
  #
  #   * the stepped readiness indicator on the dashboard,
  #   * the "Your journey" milestone list,
  #   * the data-driven sidebar label,
  #   * the "what's missing" onboarding nudge.
  #
  # All criteria are documented here so product can tune thresholds without
  # touching views. Milestones are personal progress, never competition.
  class Journey
    # Ordered journey stages. Each stage has a key, a human label (i18n), and
    # a predicate that decides whether the user has reached it. The current
    # stage is the last stage whose predicate is true.
    STAGES = [
      {
        key: :getting_started,
        reached: ->(ctx) { true }
      },
      {
        key: :building_profile,
        reached: ->(ctx) { ctx.onboarding_complete? || ctx.profile_progress.positive? }
      },
      {
        key: :discovering_matches,
        reached: ->(ctx) { ctx.onboarding_complete? && ctx.saved_pet_count.positive? }
      },
      {
        key: :ready_to_adopt,
        reached: ->(ctx) { ctx.onboarding_complete? && ctx.active_request_count.positive? }
      }
    ].freeze

    # Milestones shown in the "Your journey" card. Each has a key, an i18n
    # label, an icon name (used by the view), and a predicate. `hint` is the
    # i18n key for the "what to do next" line shown while the milestone is
    # still locked.
    MILESTONES = [
      {
        key: :profile_starter,
        icon: "check",
        done: ->(ctx) { ctx.onboarding_complete? },
        hint: "hint_profile"
      },
      {
        key: :first_saved_pet,
        icon: "heart",
        done: ->(ctx) { ctx.saved_pet_count.positive? },
        hint: "hint_saved_pet"
      },
      {
        key: :first_application,
        icon: "paper_plane",
        done: ->(ctx) { ctx.request_count.positive? },
        hint: "hint_application"
      },
      {
        key: :active_applicant,
        icon: "clock",
        done: ->(ctx) { ctx.active_request_count.positive? },
        hint: "hint_active"
      },
      {
        key: :publisher,
        icon: "paw",
        done: ->(ctx) { ctx.published_pet_count.positive? },
        hint: "hint_publisher"
      }
    ].freeze

    # The sidebar label reflects the current journey stage so it is honest and
    # data-driven rather than a hardcoded "Animal Ally".
    SIDEBAR_LABEL_STAGE = {
      getting_started: :label_getting_started,
      building_profile: :label_building_profile,
      discovering_matches: :label_discovering_matches,
      ready_to_adopt: :label_ready_to_adopt
    }.freeze

    def initialize(user)
      @user = user
    end

    # The current journey stage (a STAGES entry).
    def current_stage
      STAGES.reverse.find { |stage| stage[:reached].call(context) } || STAGES.first
    end

    # All stages with a `reached` flag, for the stepped indicator.
    def stages
      STAGES.map do |stage|
        stage.merge(reached: stage[:reached].call(context))
      end
    end

    # All milestones with a `done` flag, for the "Your journey" card.
    def milestones
      MILESTONES.map do |milestone|
        milestone.merge(done: milestone[:done].call(context))
      end
    end

    def completed_milestone_count
      milestones.count { |m| m[:done] }
    end

    def total_milestone_count
      MILESTONES.size
    end

    # The first milestone that is not yet done, or nil when all are complete.
    def next_milestone
      milestones.find { |m| !m[:done] }
    end

    # i18n key for the sidebar label, e.g. "Ready to adopt".
    def sidebar_label_key
      SIDEBAR_LABEL_STAGE[current_stage[:key]]
    end

    # i18n key for the "next step" line under the readiness meter.
    def next_step_key
      if !onboarding_complete?
        :next_complete_profile
      elsif saved_pet_count.zero?
        :next_save_pet
      elsif active_request_count.zero?
        :next_submit_request
      else
        :next_await_review
      end
    end

    # The dashboard journey card adapts to where the user is. The variant
    # drives the explanation sentence, the achieved-milestones summary, and the
    # single primary CTA (all presentation-only — never points/levels/boards).
    def card_variant
      return :active_applicant if active_request_count.positive?
      return :fresh if !onboarding_complete? && saved_pet_count.zero? && request_count.zero?

      :mid_journey
    end

    # i18n key suffix for the journey-card CTA label.
    def card_cta_key
      case card_variant
      when :fresh           then :complete_profile
      when :active_applicant then :see_requests
      else :browse_pets
      end
    end

    # Route helper name for the journey-card CTA (resolved by the view).
    def card_cta_path
      case card_variant
      when :fresh           then :profile_onboarding_path
      when :active_applicant then :adoption_requests_path
      else :pets_path
      end
    end

    # The single most important missing action, used by the onboarding nudge.
    # Returns an i18n key + the path to the completion step.
    #
    # Note: the dashboard nudge only renders while onboarding is incomplete, so
    # in that context this always returns `complete_profile`. The `save_pet` /
    # `submit_request` branches are kept as a general "next best action" for
    # completed profiles (e.g. future nudges or empty states).
    def missing_step
      return { key: :complete_profile, path: :profile_onboarding_path } unless onboarding_complete?
      return { key: :save_pet, path: :pets_path } if saved_pet_count.zero?
      return { key: :submit_request, path: :pets_path } if active_request_count.zero?

      nil
    end

    private

    def context
      @context ||= Context.new(@user)
    end

    def onboarding_complete?
      context.onboarding_complete?
    end

    def saved_pet_count
      context.saved_pet_count
    end

    def request_count
      context.request_count
    end

    def active_request_count
      context.active_request_count
    end

    # Lightweight value object that batches the queries needed to evaluate all
    # stage/milestone predicates in a single pass.
    class Context
      def initialize(user)
        @user = user
      end

      def onboarding_complete?
        @user.onboarding_completed?
      end

      def profile_progress
        return @profile_progress if defined?(@profile_progress)
        return @profile_progress = 0 if onboarding_complete?

        profile = @user.individual_profile
        return @profile_progress = 0 unless profile

        step = profile.onboarding_step.to_f
        total = Onboarding::Individual::QuestionsData.count.to_f
        return @profile_progress = 0 if total.zero?

        @profile_progress = (step / total * 100).to_i
      end

      def saved_pet_count
        @saved_pet_count ||= @user.saved_pets.count
      end

      def request_count
        @request_count ||= @user.adoption_requests.count
      end

      def active_request_count
        @active_request_count ||= @user.adoption_requests
          .where(status: %w[pending in_validation])
          .count
      end

      def published_pet_count
        @published_pet_count ||= @user.published_pets.kept.count
      end
    end
  end
end
