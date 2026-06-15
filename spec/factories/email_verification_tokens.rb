FactoryBot.define do
  factory :email_verification_token do
    user
    expires_at { 24.hours.from_now }
  end
end
