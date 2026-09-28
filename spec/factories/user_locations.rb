FactoryBot.define do
  factory :user_location do
    association :user
    city { Faker::Address.city }
    region { Faker::Address.state }
    country { "United States" }
    latitude { 30.2672 }
    longitude { -97.7431 }
    source { "manual" }

    trait :device do
      source { "device" }
      latitude { 30.27 }
      longitude { -97.74 }
    end
  end
end
