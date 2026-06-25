require "rails_helper"

RSpec.describe ShelterProfile, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:shelter).optional }
  end

  describe "validations" do
    subject { build(:shelter_profile) }

    it { is_expected.to validate_presence_of(:user) }

    it "validates organization_type inclusion" do
      %w[small_rescue independent_shelter large_shelter ngo_foundation foster_based].each do |val|
        should allow_value(val).for(:organization_type)
      end
      should_not allow_value("invalid").for(:organization_type)
    end

    it "validates pet_count_range inclusion" do
      %w[under_20 20_to_50 50_to_100 over_100].each do |val|
        should allow_value(val).for(:pet_count_range)
      end
    end

    it "validates adoption_involvement inclusion" do
      %w[basic_screening interviews extensive_matching long_term_support].each do |val|
        should allow_value(val).for(:adoption_involvement)
      end
    end

    it { is_expected.to validate_length_of(:approval_philosophy).is_at_most(200).allow_blank }
  end
end
