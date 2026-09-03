FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { "password123" }
    password_confirmation { "password123" }
    role { "individual" }

    trait :verified do
      verified_at { Time.current }
    end

    trait :onboarding_completed do
      onboarding_completed_at { Time.current }
    end

    trait :admin do
      role { "admin" }
    end

    trait :staff do
      role { "staff" }
    end

    trait :shelter_admin do
      role { "shelter_admin" }
      shelter_role { "owner" }
    end

    trait :shelter_staff do
      role { "shelter_staff" }
      shelter_role { "staff_member" }
    end

    trait :shelter_owner do
      role { "shelter_admin" }
      shelter_role { "owner" }
    end

    trait :shelter_administrator do
      role { "shelter_staff" }
      shelter_role { "administrator" }
    end

    trait :shelter_staff_member do
      role { "shelter_staff" }
      shelter_role { "staff_member" }
    end

    trait :discarded do
      discarded_at { Time.current }
    end
  end
end
