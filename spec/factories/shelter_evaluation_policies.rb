FactoryBot.define do
  factory :shelter_evaluation_policy do
    shelter
    content { "Applicants must have previous pet experience" }
    status { "translated" }

    trait :not_evaluated do
      status { "not_evaluated" }
      reason { "unsupported_data" }
    end

    trait :failed do
      status { "failed" }
    end

    trait :draft do
      status { "draft" }
    end
  end

  factory :shelter_evaluation_rule do
    policy factory: :shelter_evaluation_policy
    rule_type { "pet_experience_min" }
    params { { "level" => "some_experience" } }
    severity { "yellow" }
    enabled { false }
  end
end
