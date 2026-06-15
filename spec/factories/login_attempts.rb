FactoryBot.define do
  factory :login_attempt do
    email { Faker::Internet.email }
    ip_address { Faker::Internet.ip_v4_address }
    attempted_at { Time.current }
    success { false }

    trait :successful do
      success { true }
    end
  end
end
