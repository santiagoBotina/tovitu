require "rails_helper"

# End-to-end regression for the onboarding wizard: every question must persist
# through the JSON PATCH contract the Stimulus controller uses, and completion
# must succeed with all answers present.
#
# Regression: the controller compared `data-type` against hyphenated strings,
# so select answers were never saved and completion failed with
# "Missing: 1, 2, 3, 4, 5, 6, 7" (text question 8 always saved).
RSpec.describe "Onboarding wizard completion", type: :request do
  let(:user) { create(:user, :verified) }

  before do
    post session_path, params: { session: { email: user.email, password: "password123" } }
  end

  def patch_answer(question_number, answer)
    patch onboarding_individual_questions_path,
          params: { question_number: question_number, answer: answer }.to_json,
          headers: { "Content-Type" => "application/json" }
  end

  def post_completion
    post onboarding_individual_completion_path, params: { skip: "false" }
  end

  it "saves every answer and completes onboarding" do
    patch_answer(1, %w[going_for_walks outdoor_adventures])
    patch_answer(2, "active")
    patch_answer(3, "playful_companion")
    patch_answer(4, "some_experience")
    patch_answer(5, %w[daily_companion more_activity])
    patch_answer(6, "2_to_4h")
    patch_answer(7, "adventurous_energetic")
    patch_answer(8, "A loving home for a dog")

    profile = user.individual_profile.reload
    expect(profile.weekend_activity).to eq(%w[going_for_walks outdoor_adventures])
    expect(profile.activity_level).to eq("active")
    expect(profile.ideal_companion).to eq("playful_companion")
    expect(profile.pet_experience).to eq("some_experience")
    expect(profile.adoption_goals).to eq(%w[daily_companion more_activity])
    expect(profile.daily_time_available).to eq("2_to_4h")
    expect(profile.personality).to eq("adventurous_energetic")
    expect(profile.adoption_priority).to eq("A loving home for a dog")

    post_completion
    expect(response).to redirect_to("/en/pets")
    expect(user.reload).to be_onboarding_completed
  end

  it "does not regress to the 'Missing: 1..7' failure when all questions are answered" do
    answers = {
      1 => %w[going_for_walks],
      2 => "active",
      3 => "playful_companion",
      4 => "some_experience",
      5 => %w[daily_companion],
      6 => "2_to_4h",
      7 => "adventurous_energetic",
      8 => "A loving home"
    }
    answers.each { |qnum, answer| patch_answer(qnum, answer) }
    post_completion

    expect(response.status).to eq(302)
    expect(response.headers["Location"]).not_to include("onboarding")
  end

  it "flashes the profile-starter milestone on first completion" do
    answers = {
      1 => %w[going_for_walks],
      2 => "active",
      3 => "playful_companion",
      4 => "some_experience",
      5 => %w[daily_companion],
      6 => "2_to_4h",
      7 => "adventurous_energetic",
      8 => "A loving home"
    }
    answers.each { |qnum, answer| patch_answer(qnum, answer) }
    post_completion

    expect(flash[:notice]).to eq(I18n.t("gamification.milestone_unlocked.profile_starter"))
  end

  it "does not flash the profile-starter milestone when the wizard is skipped" do
    post onboarding_individual_completion_path, params: { skip: "true" }

    expect(flash[:notice]).to eq(I18n.t("flash.onboarding.individual.skipped"))
    expect(flash[:notice]).not_to eq(I18n.t("gamification.milestone_unlocked.profile_starter"))
  end

  it "does not flash the milestone a second time after onboarding is complete" do
    answers = {
      1 => %w[going_for_walks],
      2 => "active",
      3 => "playful_companion",
      4 => "some_experience",
      5 => %w[daily_companion],
      6 => "2_to_4h",
      7 => "adventurous_energetic",
      8 => "A loving home"
    }
    answers.each { |qnum, answer| patch_answer(qnum, answer) }
    post_completion

    # Second submission via profile-settings flow: no milestone, just the
    # preferences-updated notice (early-return path).
    post onboarding_individual_completion_path, params: { skip: "false", from_profile: "true" }

    expect(flash[:notice]).to eq(I18n.t("flash.onboarding.preferences_updated"))
    expect(flash[:notice]).not_to eq(I18n.t("gamification.milestone_unlocked.profile_starter"))
  end
end
