FactoryBot.define do
  factory :shelter do
    name { Faker::Company.unique.name }
    street { Faker::Address.street_address }
    city { Faker::Address.city }
    state { Faker::Address.state_abbr }
    zip { Faker::Address.zip_code }
    phone { Faker::PhoneNumber.phone_number }
    species_served { [ "dog" ] }
    status { "active" }

    trait :inactive do
      status { "inactive" }
    end

    trait :discarded do
      discarded_at { Time.current }
    end

    trait :with_ai_disabled do
      ai_features_enabled { false }
    end

    trait :with_admin do
      after(:create) do |shelter|
        create(:user, :verified, :shelter_admin, shelter: shelter, email: "admin@#{shelter.name.parameterize}.com")
      end
    end

    trait :with_staff do
      after(:create) do |shelter|
        create(:user, :verified, shelter: shelter)
      end
    end
  end
end
