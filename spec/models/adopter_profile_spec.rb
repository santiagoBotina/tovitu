require "rails_helper"

RSpec.describe AdopterProfile, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { build(:adopter_profile) }

    it { is_expected.to validate_presence_of(:user) }

    it "validates activity_level inclusion" do
      %w[very_calm mostly_calm balanced active very_active].each do |val|
        should allow_value(val).for(:activity_level)
      end
      should_not allow_value("invalid").for(:activity_level)
    end

    it "validates ideal_companion inclusion" do
      %w[calm_friend playful_companion affectionate_pet independent_pet social_pet].each do |val|
        should allow_value(val).for(:ideal_companion)
      end
    end

    it "validates pet_experience inclusion" do
      %w[first_time some_experience years_of_experience very_experienced].each do |val|
        should allow_value(val).for(:pet_experience)
      end
    end

    it "validates daily_time_available inclusion" do
      %w[less_than_1h 1_to_2h 2_to_4h more_than_4h].each do |val|
        should allow_value(val).for(:daily_time_available)
      end
    end

    it "validates personality inclusion" do
      %w[calm_thoughtful friendly_social adventurous_energetic organized_routine flexible_spontaneous].each do |val|
        should allow_value(val).for(:personality)
      end
    end

    it { is_expected.to validate_length_of(:adoption_priority).is_at_most(200).allow_blank }
  end
end
