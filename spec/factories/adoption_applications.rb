FactoryBot.define do
  factory :adoption_application do
    pet
    shelter
    applicant_name { Faker::Name.name }
    applicant_email { Faker::Internet.unique.email }
    token { SecureRandom.urlsafe_base64(32) }
    status { "pending" }
  end
end
