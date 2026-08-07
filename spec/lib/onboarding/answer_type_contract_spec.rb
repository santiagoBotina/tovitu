require "rails_helper"

# Guards the contract between the onboarding question data and the Stimulus
# controller that submits answers.
#
# Regression for the wizard bug: the DOM renders `data-type` from
# QuestionsData (underscored: "multi_select" / "single_select"), but
# onboarding_controller.js compared against hyphenated strings
# ("multi-select" / "single-select"). Every select answer fell through to ""
# and was silently skipped, so completion always failed with
# "Missing: 1, 2, 3, 4, 5, 6, 7" while the text question (8) saved.
RSpec.describe "Onboarding answer-type contract" do
  ONBOARDING_JS = Rails.root.join("app/javascript/controllers/onboarding_controller.js").read

  it "defines question types with underscores, matching the JS comparisons" do
    [ Onboarding::Individual::QuestionsData, Onboarding::Shelter::QuestionsData ].each do |data|
      types = data.all.map { |q| q[:type] }
      expect(types).to all(be_in(%w[multi_select single_select text]))
    end
  end

  it "compares against underscored types in the wizard controller" do
    expect(ONBOARDING_JS).to include('type === "multi_select"')
    expect(ONBOARDING_JS).to include('type === "single_select"')
  end

  it "does not compare against hyphenated types in the wizard controller" do
    expect(ONBOARDING_JS).not_to include('type === "multi-select"')
    expect(ONBOARDING_JS).not_to include('type === "single-select"')
  end
end
