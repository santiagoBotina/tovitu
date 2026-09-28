module Adoptions
  module Evaluation
    # Verdict aggregation for the evaluation rules (REQ-49-6).
    #
    #   - Red (high_concern)  — any failed high-severity (red) rule.
    #   - Yellow (needs_review) — any failed warning (yellow) rule, or any rule
    #     that could not be evaluated because required data was missing
    #     (conservative: "couldn't verify" → yellow).
    #   - Green (pre_accept)  — at least one rule evaluated and all passed.
    #   - :none — no rules evaluated at all (neutral empty state).
    class Verdict
      HIGH_CONCERN = "high_concern"
      NEEDS_REVIEW = "needs_review"
      PRE_ACCEPT = "pre_accept"

      def self.call(results)
        return :none if results.empty?
        return HIGH_CONCERN if results.any? { |r| r.failed? && r.severity == "red" }

        if results.any? { |r| (r.failed? && r.severity == "yellow") || r.unevaluable? }
          return NEEDS_REVIEW
        end

        return PRE_ACCEPT if results.any?(&:passed?)

        :none
      end

      # Presentation order: failed red first, then failed yellow, then
      # unevaluable, then passed. Stable within groups.
      def self.order_results(results)
        results.sort_by do |result|
          group = if result.failed? && result.severity == "red"
                    0
          elsif result.failed?
                    1
          elsif result.unevaluable?
                    2
          else
                    3
          end
          [ group, results.index(result) ]
        end
      end

      def self.summary(verdict, results)
        case verdict
        when HIGH_CONCERN
          { "key" => "adoptions.evaluation.summaries.high_concern",
            "params" => { "count" => results.count { |r| r.failed? && r.severity == "red" } } }
        when NEEDS_REVIEW
          { "key" => "adoptions.evaluation.summaries.needs_review",
            "params" => {
              "failed_count" => results.count { |r| r.failed? && r.severity == "yellow" },
              "unverifiable_count" => results.count(&:unevaluable?)
            } }
        when PRE_ACCEPT
          { "key" => "adoptions.evaluation.summaries.pre_accept", "params" => {} }
        end
      end
    end
  end
end
