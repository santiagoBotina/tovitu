FactoryBot.define do
  factory :pet do
    shelter
    name { Faker::Creature::Dog.name }
    species { "dog" }
    breed { "Mixed" }
    age_category { "adult" }
    sex { "male" }
    status { "available" }

    trait :with_personality_spec do
      personality_spec { "Friendly and energetic. Loves belly rubs but nervous around strangers. Favorite activity is fetch." }
    end

    trait :with_adopter_tips do
      adopter_tips { "Needs a quiet home. Working on leash reactivity. Best suited for experienced dog owners." }
    end

    trait :discarded do
      discarded_at { Time.current }
      status { "removed" }
    end

    trait :individual_listed do
      shelter { nil }
      association :publisher, factory: [ :user, :verified, :onboarding_completed ]
    end

    trait :with_life_preview do
      life_preview_data do
        {
          "plan" => [
            { "week" => "Week 0 (Pre-Adoption)", "items" => [ "Prepare supplies", "Pet-proof your home", "Schedule vet appointment" ] },
            { "week" => "Week 1 (Arrival)", "items" => [ "Decompression protocol", "Establish feeding routine", "First vet check" ] }
          ],
          "itinerary" => {
            "daily_routine" => "Morning walk, feeding, playtime, evening walk.",
            "feeding_guide" => "2 meals per day, high-quality dry food.",
            "exercise_needs" => "30-60 minutes daily exercise.",
            "grooming" => "Weekly brushing, monthly bath.",
            "vet_schedule" => "Initial visit within first week, annual checkups."
          },
          "tips" => {
            "home_preparation" => [ "Pet-proofing advice", "Create a safe space" ],
            "supplies" => [ "Food bowls", "Bed", "Crate", "Leash" ],
            "family_preparation" => [ "Introduce slowly to children", "Supervise interactions" ],
            "lifestyle_adjustments" => [ "Plan for schedule changes", "Arrange pet sitter" ],
            "training_resources" => [ "Positive reinforcement", "Local training classes" ]
          }
        }
      end
      life_preview_generated_at { Time.current }
      life_preview_version { 2 }
    end
  end
end
