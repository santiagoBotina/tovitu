module Adoptions
  module Evaluation
    # Immutable result of evaluating a single rule. Evidence is stored as a
    # locale key + params reference so the snapshot stays localized at render
    # time (REQ-49-7). `passed` is true/false for evaluated rules and nil for
    # unevaluable rules ("couldn't verify" because required data is missing).
    RuleResult = Data.define(:rule_type, :severity, :source, :passed, :unevaluable,
                             :evidence, :policy_text, :params, :label_key) do
      def failed?
        passed == false
      end

      def passed?
        passed == true
      end

      def unevaluable?
        unevaluable == true
      end

      # Stable hash persisted on the snapshot. Keys mirror the service-object
      # contracts used elsewhere in the domain (string keys, JSON-safe).
      def to_h_snapshot
        {
          "rule" => rule_type,
          "severity" => severity,
          "source" => source,
          "passed" => passed,
          "unevaluable" => unevaluable?,
          "evidence" => evidence,
          "policy_text" => policy_text,
          "params" => params,
          "label_key" => label_key
        }
      end
    end
  end
end
