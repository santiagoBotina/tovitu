FactoryBot.define do
  factory :notification do
    association :recipient, factory: :user
    association :actor, factory: :user
    association :notifiable, factory: :adoption_request

    kind { "request_submitted" }
    title { "Request for #{Faker::Creature::Dog.name}" }
    body { "Your request has been sent for review." }
    metadata { {} }
    action_url { "/adoption_requests/1" }

    trait :unread do
      read_at { nil }
    end

    trait :read do
      read_at { Time.current }
    end

    trait :request_submitted do
      kind { "request_submitted" }
    end

    trait :request_accepted do
      kind { "request_accepted" }
    end

    trait :request_declined do
      kind { "request_declined" }
    end

    trait :request_withdrawn do
      kind { "request_withdrawn" }
    end
  end
end
