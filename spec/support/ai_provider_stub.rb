module AiProviderStub
  def default_adopter_insight_response
    {
      "archetype" => "active_outdoors_partner",
      "archetype_diverges" => false,
      "commitment_signals" => [
        { "label" => "follow_through", "observation" => "Applied to 1 pet and followed the request to completion.", "kind" => "positive" },
        { "label" => "responsiveness", "observation" => "Responded to a follow-up within about 2 hours.", "kind" => "positive" }
      ],
      "confidence" => "medium",
      "based_on" => "onboarding answers, 2 saved pets, 1 request"
    }
  end

  def default_pet_fit_response
    {
      "fit_indicators" => {
        "energy" => { "status" => "strong_fit", "evidence" => "They report an active lifestyle and save high-energy dogs." },
        "time" => { "status" => "strong_fit", "evidence" => "They have 2-4 hours available daily." },
        "experience" => { "status" => "unknown", "evidence" => "" },
        "home_space" => { "status" => "strong_fit", "evidence" => "They describe a house with a fenced yard." },
        "household" => { "status" => "unknown", "evidence" => "" }
      },
      "summary" => "This applicant looks like a strong match for the pet: an active home with a fenced yard and time for daily exercise. Their pet experience is unknown, so a quick call is worthwhile.",
      "verification_questions" => [ "Have you owned a dog before?", "Who is home during the day?" ],
      "confidence" => "medium"
    }
  end
  def default_preview_response
    {
      "plan" => [
        { "week" => "Week 0 (Pre-Adoption)", "items" => [ "Prepare supplies", "Pet-proof your home", "Schedule vet appointment" ] },
        { "week" => "Week 1 (Arrival)", "items" => [ "Decompression protocol", "Establish feeding routine", "First vet check" ] },
        { "week" => "Week 2 (Settling In)", "items" => [ "Begin training routine", "Explore neighborhood", "Monitor adjustment" ] },
        { "week" => "Week 3 (Bonding)", "items" => [ "Strengthen bond through play", "Enrichment activities", "Identify personality quirks" ] },
        { "week" => "Week 4+ (Integration)", "items" => [ "Full integration", "Advanced training", "Long-term care planning" ] }
      ],
      "itinerary" => {
        "daily_routine" => "Morning: 30-min walk, breakfast. Midday: enrichment activity. Evening: 30-min walk, dinner. Bedtime: final potty break.",
        "feeding_guide" => "Feed 2 meals per day with high-quality dry food appropriate for age and size.",
        "exercise_needs" => "Requires 30-60 minutes of daily exercise including walks, playtime, and mental stimulation.",
        "grooming" => "Weekly brushing, monthly nail trims, dental care 2-3 times per week.",
        "vet_schedule" => "Initial wellness visit within first week, annual checkups, vaccinations as recommended."
      },
      "tips" => {
        "home_preparation" => [ "Remove toxic plants from reach", "Secure loose cords and wires", "Designate a quiet safe space with bed and water" ],
        "supplies" => [ "Food and water bowls", "Comfortable bed", "Crate for training", "Leash and collar with ID tags", "Food and treats" ],
        "family_preparation" => [ "Give the pet space to decompress for 24-48 hours", "Supervise all interactions with children", "Introduce other pets slowly in neutral territory" ],
        "lifestyle_adjustments" => [ "Expect 1-2 hours of dedicated pet time daily", "Arrange for mid-day potty breaks or dog walker", "Plan for reduced spontaneity in travel" ],
        "training_resources" => [ "Focus on positive reinforcement methods", "Consider a local training class for socialization", "Use puzzle toys for mental stimulation" ]
      }
    }
  end
end

RSpec.configure do |config|
  config.include AiProviderStub
end
