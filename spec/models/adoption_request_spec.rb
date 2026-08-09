require "rails_helper"

RSpec.describe AdoptionRequest, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:pet) }
    it { is_expected.to belong_to(:adopter).class_name("User") }
    it { is_expected.to belong_to(:shelter).optional }
    it { is_expected.to belong_to(:reviewed_by).class_name("User").optional }
    it { is_expected.to have_many(:timeline_events).class_name("AdoptionRequestTimelineEvent").dependent(:destroy) }
  end

  describe "enums" do
    it "defines the expected statuses" do
      expected = %w[pending in_validation accepted declined withdrawn]
      expect(AdoptionRequest.statuses.keys).to match_array(expected)
    end
  end

  describe "validations" do
    subject { build(:adoption_request) }

    it "validates uniqueness of adopter_id scoped to pet_id for active requests" do
      request = create(:adoption_request)
      duplicate = build(:adoption_request, adopter: request.adopter, pet: request.pet)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:adopter_id]).to include(I18n.t("adoptions.requests.errors.duplicate"))
    end

    it "allows duplicate requests when previous was declined" do
      request = create(:adoption_request, :declined)
      new_request = build(:adoption_request, adopter: request.adopter, pet: request.pet)
      expect(new_request).to be_valid
    end

    it "allows duplicate requests when previous was withdrawn" do
      request = create(:adoption_request, :withdrawn)
      new_request = build(:adoption_request, adopter: request.adopter, pet: request.pet)
      expect(new_request).to be_valid
    end
  end

  describe "scopes" do
    let(:shelter) { create(:shelter) }
    let(:pet) { create(:pet, shelter: shelter) }
    let(:adopter) { create(:user, :verified, :onboarding_completed) }
    let!(:pending_request) { create(:adoption_request, pet: pet, adopter: adopter, shelter: shelter, status: :pending) }
    let!(:accepted_request) { create(:adoption_request, pet: create(:pet, shelter: shelter), adopter: create(:user, :verified, :onboarding_completed), shelter: shelter, status: :accepted) }
    let!(:declined_request) { create(:adoption_request, pet: create(:pet, shelter: shelter), adopter: create(:user, :verified, :onboarding_completed), shelter: shelter, status: :declined) }
    let!(:withdrawn_request) { create(:adoption_request, pet: create(:pet, shelter: shelter), adopter: create(:user, :verified, :onboarding_completed), shelter: shelter, status: :withdrawn) }

    describe ".active" do
      it "includes non-terminal statuses" do
        expect(AdoptionRequest.active).to include(pending_request, accepted_request)
      end

      it "excludes declined and withdrawn" do
        expect(AdoptionRequest.active).not_to include(declined_request, withdrawn_request)
      end
    end

    describe ".by_shelter" do
      it "filters by shelter" do
        expect(AdoptionRequest.by_shelter(shelter.id)).to all(have_attributes(shelter_id: shelter.id))
      end
    end

    describe ".by_adopter" do
      it "filters by adopter" do
        expect(AdoptionRequest.by_adopter(adopter.id)).to all(have_attributes(adopter_id: adopter.id))
      end
    end

    describe ".newest_first" do
      it "orders by created_at desc" do
        expect(AdoptionRequest.newest_first.first).to eq(withdrawn_request)
      end
    end

    describe ".with_additional_answers" do
      let!(:with_answers) { create(:adoption_request, :with_additional_answers) }

      it "includes requests with non-empty additional_answers" do
        expect(AdoptionRequest.with_additional_answers).to include(with_answers)
      end

      it "excludes requests with empty additional_answers" do
        expect(AdoptionRequest.with_additional_answers).not_to include(pending_request)
      end
    end

    describe ".pending_for_publisher" do
      let(:publisher) { create(:user, :verified, :onboarding_completed) }
      let(:pet) { create(:pet, :individual_listed, publisher: publisher) }
      let!(:pending_for_publisher) { create(:adoption_request, pet: pet, shelter: nil) }

      it "returns pending requests for pets owned by the publisher" do
        expect(AdoptionRequest.pending_for_publisher(publisher)).to include(pending_for_publisher)
      end

      it "does not include non-pending requests" do
        expect(AdoptionRequest.pending_for_publisher(publisher)).not_to include(accepted_request)
      end
    end
  end

  describe "#withdrawable?" do
    it "returns true when pending" do
      request = build(:adoption_request, status: :pending)
      expect(request).to be_withdrawable
    end

    it "returns true when in_validation" do
      request = build(:adoption_request, status: :in_validation)
      expect(request).to be_withdrawable
    end

    it "returns false when accepted" do
      request = build(:adoption_request, status: :accepted)
      expect(request).not_to be_withdrawable
    end

    it "returns false when declined" do
      request = build(:adoption_request, status: :declined)
      expect(request).not_to be_withdrawable
    end

    it "returns false when already withdrawn" do
      request = build(:adoption_request, status: :withdrawn)
      expect(request).not_to be_withdrawable
    end
  end

  describe "#available_for_review?" do
    it "returns true when pending" do
      request = build(:adoption_request, status: :pending)
      expect(request).to be_available_for_review
    end

    it "returns true when in_validation" do
      request = build(:adoption_request, status: :in_validation)
      expect(request).to be_available_for_review
    end

    it "returns false when accepted, declined, or withdrawn" do
      expect(build(:adoption_request, status: :accepted)).not_to be_available_for_review
      expect(build(:adoption_request, status: :declined)).not_to be_available_for_review
      expect(build(:adoption_request, status: :withdrawn)).not_to be_available_for_review
    end
  end

  describe "#decline_reasons" do
    it "returns reasons stored in the decline timeline-event metadata" do
      request = create(:adoption_request)
      request.record_timeline!(
        from_status: "pending",
        to_status: "declined",
        actor: request.adopter,
        metadata: { decline_reasons: [ "Not a fit", "Needs experience" ] }
      )
      expect(request.decline_reasons).to eq([ "Not a fit", "Needs experience" ])
    end

    it "returns nil when there is no decline event with reasons" do
      request = create(:adoption_request)
      expect(request.decline_reasons).to be_nil
    end

    it "ignores events without decline_reasons metadata" do
      request = create(:adoption_request)
      request.record_timeline!(from_status: nil, to_status: "pending", metadata: {})
      request.record_timeline!(
        from_status: "pending",
        to_status: "declined",
        metadata: { decline_reasons: [ "Only reason" ] }
      )
      expect(request.decline_reasons).to eq([ "Only reason" ])
    end
  end

  describe "#record_timeline!" do
    it "creates a timeline event with the given attributes" do
      request = create(:adoption_request)
      actor = create(:user)

      event = request.record_timeline!(
        from_status: nil,
        to_status: "pending",
        actor: actor,
        metadata: { source: "test" }
      )

      expect(event).to be_persisted
      expect(event.from_status).to be_nil
      expect(event.to_status).to eq("pending")
      expect(event.actor).to eq(actor)
      expect(event.metadata).to eq("source" => "test")
    end
  end

  describe "#responsible_party" do
    it "returns the shelter when present" do
      shelter = create(:shelter)
      request = create(:adoption_request, shelter: shelter)
      expect(request.responsible_party).to eq(shelter)
    end

    it "returns the publisher when no shelter" do
      publisher = create(:user, :verified, :onboarding_completed)
      pet = create(:pet, :individual_listed, publisher: publisher)
      request = create(:adoption_request, pet: pet, shelter: nil)
      expect(request.responsible_party).to eq(publisher)
    end
  end

  describe "#individual_publisher?" do
    it "returns true when shelter is nil and publisher exists" do
      publisher = create(:user, :verified, :onboarding_completed)
      pet = create(:pet, :individual_listed, publisher: publisher)
      request = create(:adoption_request, pet: pet, shelter: nil)
      expect(request).to be_individual_publisher
    end

    it "returns false when shelter is present" do
      request = create(:adoption_request)
      expect(request).not_to be_individual_publisher
    end
  end

  describe "#responsible_party_name" do
    it "returns shelter name when shelter is present" do
      shelter = create(:shelter, name: "Happy Paws")
      request = create(:adoption_request, shelter: shelter)
      expect(request.responsible_party_name).to eq("Happy Paws")
    end

    it "returns publisher name when no shelter" do
      publisher = create(:user, :verified, :onboarding_completed, name: "Jane Doe")
      pet = create(:pet, :individual_listed, publisher: publisher)
      request = create(:adoption_request, pet: pet, shelter: nil)
      expect(request.responsible_party_name).to eq("Jane Doe")
    end
  end

  describe "#responsible_party_email" do
    it "returns shelter staff email when shelter is present" do
      shelter = create(:shelter)
      admin = create(:user, :verified, :shelter_admin, shelter: shelter, email: "admin@example.com")
      request = create(:adoption_request, shelter: shelter)
      expect(request.responsible_party_email).to eq("admin@example.com")
    end

    it "returns publisher email when no shelter" do
      publisher = create(:user, :verified, :onboarding_completed, email: "publisher@example.com")
      pet = create(:pet, :individual_listed, publisher: publisher)
      request = create(:adoption_request, pet: pet, shelter: nil)
      expect(request.responsible_party_email).to eq("publisher@example.com")
    end
  end

  describe "#pet_fit_stale?" do
    let(:adopter) { create(:user, :verified, :onboarding_completed) }
    let(:pet) { create(:pet) }
    let!(:request) { create(:adoption_request, adopter: adopter, pet: pet, shelter: pet.shelter) }

    it "is false when the pet-fit was built from the current signal fingerprint" do
      insight = AdopterInsight.create!(adopter: adopter, signal_fingerprint: "abc", generated_at: Time.current)
      request.update!(pet_fit_signal_fingerprint: "abc")
      expect(request.pet_fit_stale?).to be(false)
    end

    it "is true when the adopter's signals changed after the pet-fit was generated" do
      AdopterInsight.create!(adopter: adopter, signal_fingerprint: "new-signals", generated_at: Time.current)
      request.update!(pet_fit_signal_fingerprint: "old-signals")
      expect(request.pet_fit_stale?).to be(true)
    end

    it "is false when no pet-fit was ever generated" do
      expect(request.pet_fit_stale?).to be(false)
    end

    it "is false when the adopter has no cached insight" do
      request.update!(pet_fit_signal_fingerprint: "abc")
      expect(request.pet_fit_stale?).to be(false)
    end
  end
end
