FactoryBot.define do
  factory :adoption_request do
    association :pet
    association :adopter, factory: [:user, :verified, :onboarding_completed]
    shelter { pet.shelter }

    status { "pending" }
    additional_answers { {} }

    trait :in_validation do
      status { "in_validation" }
    end

    trait :accepted do
      status { "accepted" }
    end

    trait :declined do
      status { "declined" }
    end

    trait :withdrawn do
      status { "withdrawn" }
      withdrawn_at { Time.current }
    end

    trait :with_additional_answers do
      additional_answers do
        {
          interest_reason: "I've always wanted a dog like this!",
          home_description: "I live in a house with a fenced yard.",
          current_pets_details: "I have a cat who is friendly with dogs.",
          something_else: "I work from home."
        }
      end
    end

    trait :individual_publisher do
      shelter { nil }
      after(:build) do |request|
        request.pet.shelter = nil
        request.pet.publisher ||= build(:user, :verified, :onboarding_completed)
      end
    end
  end
end
