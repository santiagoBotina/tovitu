require "rails_helper"

RSpec.describe PetForm do
  let(:shelter) { create(:shelter) }

  def form_attributes(overrides = {})
    {
      name: "Tweety",
      species: "bird",
      age_category: "adult",
      sex: "male",
      size: "small",
      description: "A cheerful companion"
    }.merge(overrides)
  end

  describe "species validation" do
    it "accepts every species in Pet::SPECIES" do
      Pet::SPECIES.each do |species|
        form = described_class.new(form_attributes(species: species))
        form.valid?
        expect(form.errors[:species]).to be_empty, "expected #{species} to be a valid species"
      end
    end

    it "rejects a species outside the supported set" do
      form = described_class.new(form_attributes(species: "ferret"))
      form.valid?
      expect(form.errors[:species]).to be_present
    end

    it "rejects a blank species" do
      form = described_class.new(form_attributes(species: ""))
      form.valid?
      expect(form.errors[:species]).to be_present
    end
  end
end
