FactoryBot.define do
  factory :notification_preference do
    association :user

    in_app { true }
    email { true }
    whatsapp { false }
    whatsapp_phone { nil }
    whatsapp_verified_at { nil }
    per_kind_overrides { {} }

    trait :whatsapp_opted_in do
      whatsapp { true }
      whatsapp_phone { "+15551234567" }
      whatsapp_verified_at { Time.current }
    end

    trait :whatsapp_opted_out do
      whatsapp { false }
      whatsapp_phone { nil }
      whatsapp_verified_at { nil }
    end

    trait :email_disabled do
      email { false }
    end

    trait :in_app_disabled do
      in_app { false }
    end
  end
end
