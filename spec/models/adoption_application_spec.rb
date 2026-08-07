require "rails_helper"

RSpec.describe AdoptionApplication, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:pet).touch(true) }
    it { is_expected.to belong_to(:shelter).touch(true) }
    it { is_expected.to belong_to(:reviewed_by).class_name("User").optional }
    it { is_expected.to have_many(:adoption_notes).dependent(:destroy) }
    it { is_expected.to have_many(:adoption_timeline_events).dependent(:destroy) }
  end

  describe "validations" do
    subject { create(:adoption_application) }

    it { is_expected.to validate_presence_of(:applicant_name) }
    it { is_expected.to validate_presence_of(:applicant_email) }
    it { is_expected.to validate_presence_of(:token) }
    it { is_expected.to validate_uniqueness_of(:token) }
    it { is_expected.to validate_inclusion_of(:housing_type).in_array(AdoptionApplication::HOUSING_TYPES).allow_blank }

    it "validates email format" do
      app = build(:adoption_application, applicant_email: "invalid")
      app.valid?
      expect(app.errors[:applicant_email]).to be_present
    end

    it "validates rejection_reason required when rejected" do
      app = build(:adoption_application, status: :rejected, rejection_reason: nil)
      app.valid?
      expect(app.errors[:rejection_reason]).to be_present
    end
  end

  describe "scopes" do
    let(:shelter) { create(:shelter) }
    let(:pet) { create(:pet, shelter: shelter) }
    let!(:pending_app) { create(:adoption_application, pet: pet, shelter: shelter, status: :pending) }
    let!(:approved_app) { create(:adoption_application, pet: pet, shelter: shelter, status: :approved) }
    let!(:rejected_app) { create(:adoption_application, pet: pet, shelter: shelter, status: :rejected, rejection_reason: "Not a good fit") }
    let!(:withdrawn_app) { create(:adoption_application, pet: pet, shelter: shelter, status: :withdrawn) }
    let(:other_shelter) { create(:shelter) }

    it "active includes pending, under_review, awaiting_response" do
      expect(AdoptionApplication.active).to include(pending_app)
      expect(AdoptionApplication.active).not_to include(approved_app, rejected_app, withdrawn_app)
    end

    it "closed includes finalized statuses" do
      expect(AdoptionApplication.closed).to include(approved_app, rejected_app, withdrawn_app)
      expect(AdoptionApplication.closed).not_to include(pending_app)
    end

    it "by_shelter" do
      expect(AdoptionApplication.by_shelter(shelter.id)).to include(pending_app)
    end

    it "by_pet" do
      expect(AdoptionApplication.by_pet(pet.id)).to include(pending_app)
    end

    it "by_email" do
      expect(AdoptionApplication.by_email(pending_app.applicant_email)).to include(pending_app)
    end
  end

  describe "#discard! / #undiscard! / #discarded?" do
    it "marks as discarded" do
      app = create(:adoption_application)
      app.discard!
      expect(app).to be_discarded
    end

    it "restores a discarded application" do
      app = create(:adoption_application, discarded_at: Time.current)
      app.undiscard!
      expect(app).not_to be_discarded
    end
  end

  describe "#reference_number" do
    it "returns a reference string" do
      app = build(:adoption_application, token: "abc123")
      expect(app.reference_number).to be_a(String)
      expect(app.reference_number).not_to be_empty
    end
  end

  describe "email normalization" do
    it "downcases email before validation" do
      app = create(:adoption_application, applicant_email: "TEST@Example.COM")
      expect(app.applicant_email).to eq("test@example.com")
    end
  end
end
