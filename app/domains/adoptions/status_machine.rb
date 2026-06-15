module Adoptions
  module StatusMachine
    TRANSITIONS = {
      "pending"          => %w[under_review approved rejected withdrawn].freeze,
      "under_review"     => %w[approved rejected awaiting_response].freeze,
      "awaiting_response" => %w[under_review rejected].freeze,
      "approved"         => %w[completed cancelled withdrawn expired].freeze,
      "rejected"         => %w[].freeze,
      "completed"        => %w[].freeze,
      "withdrawn"        => %w[].freeze,
      "cancelled"        => %w[].freeze,
      "expired"          => %w[].freeze
    }.freeze

    TERMINAL_STATUSES = %w[rejected completed withdrawn cancelled expired].freeze
    ACTIVE_STATUSES   = %w[pending under_review awaiting_response].freeze
    HOLD_STATUSES     = %w[approved].freeze

    class << self
      def allowed_transitions(from_status)
        TRANSITIONS.fetch(from_status, [])
      end

      def transition_allowed?(from_status, to_status)
        allowed_transitions(from_status).include?(to_status)
      end

      def terminal?(status)
        TERMINAL_STATUSES.include?(status)
      end

      def active?(status)
        ACTIVE_STATUSES.include?(status)
      end

      def on_hold?(status)
        HOLD_STATUSES.include?(status)
      end

      def human_status_name(status)
        I18n.t("adoptions.statuses.#{status}", default: status.humanize)
      end

      def human_statuses
        TRANSITIONS.keys.index_with { |s| human_status_name(s) }
      end
    end
  end
end
