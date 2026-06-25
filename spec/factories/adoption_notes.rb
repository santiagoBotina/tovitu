FactoryBot.define do
  factory :adoption_note do
    adoption_application
    user
    content { Faker::Lorem.paragraph }
  end
end
