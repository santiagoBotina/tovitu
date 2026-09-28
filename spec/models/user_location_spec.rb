require "rails_helper"

RSpec.describe UserLocation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    subject { build(:user_location) }

    it { is_expected.to validate_presence_of(:city) }
    it { is_expected.to validate_inclusion_of(:source).in_array(UserLocation::SOURCES) }
  end

  describe "source predicates" do
    it "is device when source is device" do
      location = build(:user_location, :device)
      expect(location).to be_device
      expect(location).not_to be_manual
    end

    it "is manual when source is manual" do
      location = build(:user_location, source: "manual")
      expect(location).to be_manual
      expect(location).not_to be_device
    end
  end
end
