FactoryBot.define do
  factory :password_reset_token do
    user
    expires_at { 1.hour.from_now }
  end
end
