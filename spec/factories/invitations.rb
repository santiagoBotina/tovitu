FactoryBot.define do
  factory :invitation do
    email { Faker::Internet.unique.email }
    association :shelter
    association :created_by, factory: :user
    token { SecureRandom.urlsafe_base64(32) }
    expires_at { 7.days.from_now }

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :accepted do
      accepted_at { Time.current }
    end
  end
end
