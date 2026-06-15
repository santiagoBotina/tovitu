FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { "password123" }
    password_confirmation { "password123" }
    role { "staff" }

    trait :verified do
      verified_at { Time.current }
    end

    trait :admin do
      role { "admin" }
    end

    trait :discarded do
      discarded_at { Time.current }
    end
  end
end
