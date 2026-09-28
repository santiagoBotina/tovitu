FactoryBot.define do
  factory :adoption_request_evaluation do
    adoption_request
    verdict { "pre_accept" }
    summary { { "key" => "adoptions.evaluation.summaries.pre_accept", "params" => {} } }
    rules do
      [
        { "rule" => "email_verified", "severity" => "red", "source" => "system",
          "passed" => true, "unevaluable" => false,
          "evidence" => { "key" => "adoptions.evaluation.evidence.email_verified" },
          "params" => {}, "label_key" => "adoptions.evaluation.rules.email_verified.label" }
      ]
    end
    version { 1 }
    evaluated_at { Time.current }

    trait :high_concern do
      verdict { "high_concern" }
      summary do
        { "key" => "adoptions.evaluation.summaries.high_concern", "params" => { "count" => 1 } }
      end
    end

    trait :needs_review do
      verdict { "needs_review" }
      summary do
        { "key" => "adoptions.evaluation.summaries.needs_review",
          "params" => { "failed_count" => 0, "unverifiable_count" => 1 } }
      end
    end
  end
end
