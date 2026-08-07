require "rails_helper"

RSpec.describe "Adopter Insight end-to-end" do
  include AiProviderStub

  it "submits a request, generates and persists insight + pet-fit, and presents the card" do
    shelter = create(:shelter)
    pet = create(:pet, shelter: shelter, species: "dog", size: "large")
    adopter = create(:user, :verified, :onboarding_completed)
    create(:individual_profile,
      user: adopter,
      activity_level: "active",
      personality: "adventurous_energetic",
      daily_time_available: "2_to_4h")
    create(:saved_pet, user: adopter, pet: pet)

    allow(Ai::Provider).to receive(:call) do |prompt:, system_prompt:|
      if system_prompt.include?("Adopter Insight Analyst")
        default_adopter_insight_response.to_json
      else
        default_pet_fit_response.to_json
      end
    end

    request = Adoptions::SubmitRequest.call(adopter: adopter, pet: pet, additional_answers: {
      interest_reason: "I love hiking!", home_description: "House with a fenced yard."
    }).data

    expect {
      Ai::GenerateAdopterInsightJob.perform_now(request_id: request.id)
    }.to change(AdopterInsight, :count).by(1)

    expect(adopter.adopter_insight.data["archetype"]).to eq("active_outdoors_partner")
    expect(request.reload.pet_fit_data["fit_indicators"]["energy"]["status"]).to eq("strong_fit")

    presenter = AdopterInsightPresenter.new(request: request, adopter: adopter)
    expect(presenter.ready?).to be(true)
    expect(presenter.archetype_label).to eq("Active Outdoors Partner")
    expect(presenter.fit_indicators.size).to eq(5)
    expect(presenter.verification_questions).to be_present
  end
end
