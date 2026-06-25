FactoryBot.define do
  factory :adoption_timeline_event do
    adoption_application
    event_type { "created" }
  end
end
