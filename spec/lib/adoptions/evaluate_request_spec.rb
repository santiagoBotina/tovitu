require "rails_helper"

RSpec.describe Adoptions::EvaluateRequest do
  let(:shelter) { create(:shelter) }
  let(:pet) { create(:pet, shelter: shelter) }
  let(:adopter) do
    create(:user, :verified, :onboarding_completed,
           created_at: 30.days.ago, onboarding_completed_at: 30.days.ago)
  end
  let(:profile) do
    create(:individual_profile, user: adopter, pet_experience: "some_experience",
      daily_time_available: "2_to_4h", personality: "calm_thoughtful",
      activity_level: "active", adoption_priority: "companion",
      date_of_birth: 30.years.ago.to_date, home_environment: "house_with_fenced_yard",
      other_pets: "no_other_pets")
  end
  let(:request) { create(:adoption_request, pet: pet, adopter: adopter, shelter: shelter) }

  before { profile }

  describe "#call" do
    it "produces a pre-accept verdict when all rules pass" do
      result = described_class.call(request: request)
      expect(result).to be_success
      expect(result.data).to be_pre_accept
    end

    it "persists a snapshot with verdict, summary, rules, version and evaluated_at" do
      result = described_class.call(request: request)
      snapshot = request.reload.policy_evaluation
      expect(snapshot).to be_present
      expect(snapshot.verdict).to eq("pre_accept")
      expect(snapshot.summary).to be_a(Hash)
      expect(snapshot.rules).to be_an(Array)
      expect(snapshot.version).to eq(Adoptions::Evaluation::VERSION)
      expect(snapshot.evaluated_at).to be_present
    end

    it "never changes the request status (all verdicts leave the request pending)" do
      expect { described_class.call(request: request) }.not_to change { request.reload.status }
      expect(request.reload).to be_pending
    end

    it "never notifies the adopter of a decision (REQ-49-12)" do
      expect(Notifications::Deliver).not_to receive(:call)

      described_class.call(request: request)
    end

    it "replaces the snapshot on re-run (REQ-49-14)" do
      first = described_class.call(request: request).data
      adopter.update!(created_at: 1.day.ago)
      second = described_class.call(request: request).data

      expect(request.reload.policy_evaluation.id).to eq(second.id)
      expect(second).to be_high_concern
      expect(first.id).not_to eq(second.id)
    end

    context "red verdict (high concern)" do
      it "flags an account younger than 3 days" do
        adopter.update!(created_at: 1.day.ago)
        expect(described_class.call(request: request).data).to be_high_concern
      end

      it "flags an unverified email" do
        adopter.update!(verified_at: nil)
        snapshot = described_class.call(request: request).data
        expect(snapshot).to be_high_concern
        rule = snapshot.rules.find { |r| r["rule"] == "email_verified" }
        expect(rule["passed"]).to be false
      end

      it "flags an under-18 adopter (DOB present)" do
        profile.update!(date_of_birth: 17.years.ago.to_date)
        snapshot = described_class.call(request: request).data
        expect(snapshot).to be_high_concern
        rule = snapshot.rules.find { |r| r["rule"] == "adopter_age_min" }
        expect(rule["passed"]).to be false
        expect(rule["evidence"]["params"]["years"]).to eq(17)
      end
    end

    context "yellow verdict (needs review)" do
      it "reports missing DOB as 'couldn't verify' (unevaluable) -> needs review" do
        profile.update!(date_of_birth: nil)
        snapshot = described_class.call(request: request).data
        expect(snapshot).to be_needs_review
        rule = snapshot.rules.find { |r| r["rule"] == "adopter_age_min" }
        expect(rule["unevaluable"]).to be true
        expect(rule["passed"]).to be_nil
        expect(rule["evidence"]["key"]).to eq("adoptions.evaluation.evidence.adopter_age_missing")
      end

      it "flags a prior declined request for the same pet" do
        create(:adoption_request, pet: pet, adopter: adopter, shelter: shelter, status: :declined)
        snapshot = described_class.call(request: request).data
        expect(snapshot).to be_needs_review
        rule = snapshot.rules.find { |r| r["rule"] == "no_prior_decline_same_pet" }
        expect(rule["passed"]).to be false
      end

      it "flags an incomplete profile below the completeness threshold" do
        profile.update!(activity_level: nil, personality: nil, pet_experience: nil,
                        daily_time_available: nil, adoption_priority: nil)
        snapshot = described_class.call(request: request).data
        rule = snapshot.rules.find { |r| r["rule"] == "profile_completeness_min" }
        expect(rule["passed"]).to be false
        expect(snapshot).to be_needs_review
      end
    end

    context "shelter rules (REQ-49-5)" do
      let(:policy) { create(:shelter_evaluation_policy, shelter: shelter, content: "We require a fenced yard") }
      let!(:rule) do
        create(:shelter_evaluation_rule, policy: policy,
               rule_type: "home_fenced_yard_required", severity: "red", enabled: true)
      end

      it "evaluates enabled shelter rules with a source of shelter" do
        snapshot = described_class.call(request: request).data
        shelter_rule = snapshot.rules.find { |r| r["rule"] == "home_fenced_yard_required" }
        expect(shelter_rule["source"]).to eq("shelter")
        expect(shelter_rule["passed"]).to be true
        expect(shelter_rule["policy_text"]).to eq("We require a fenced yard")
      end

      it "fails a shelter rule when the adopter's home has no fenced yard" do
        profile.update!(home_environment: "apartment_or_condo")
        snapshot = described_class.call(request: request).data
        shelter_rule = snapshot.rules.find { |r| r["rule"] == "home_fenced_yard_required" }
        expect(shelter_rule["passed"]).to be false
        expect(shelter_rule["severity"]).to eq("red")
        expect(snapshot).to be_high_concern
      end

      it "reports missing home data as unevaluable for a shelter rule" do
        profile.update!(home_environment: nil)
        snapshot = described_class.call(request: request).data
        shelter_rule = snapshot.rules.find { |r| r["rule"] == "home_fenced_yard_required" }
        expect(shelter_rule["unevaluable"]).to be true
      end

      it "does not evaluate disabled shelter rules" do
        rule.update!(enabled: false)
        snapshot = described_class.call(request: request).data
        expect(snapshot.rules.none? { |r| r["rule"] == "home_fenced_yard_required" }).to be true
      end

      it "ignores shelter rules of an unknown rule type" do
        rule.update!(rule_type: "unknown_rule")
        snapshot = described_class.call(request: request).data
        expect(snapshot.rules.none? { |r| r["source"] == "shelter" }).to be true
      end
    end

    context "individual publisher request (REQ-49-9)" do
      let(:publisher) { create(:user, :verified, :onboarding_completed) }
      let(:pet) { create(:pet, :individual_listed, publisher: publisher) }
      let(:request) { create(:adoption_request, pet: pet, adopter: adopter, shelter: nil) }

      it "evaluates system rules only" do
        snapshot = described_class.call(request: request).data
        expect(snapshot.rules.map { |r| r["source"] }.uniq).to eq([ "system" ])
      end
    end

    it "orders results: failed red first, then failed yellow, then passed" do
      adopter.update!(created_at: 1.day.ago)
      create(:adoption_request, pet: pet, adopter: adopter, shelter: shelter, status: :declined)
      snapshot = described_class.call(request: request).data
      rules = snapshot.rules

      failed_red = rules.select { |r| r["passed"] == false && r["severity"] == "red" }
      failed_yellow = rules.select { |r| r["passed"] == false && r["severity"] == "yellow" }
      passed = rules.select { |r| r["passed"] == true }

      expect(failed_red).not_to be_empty
      expect(failed_yellow).not_to be_empty
      expect(passed).not_to be_empty
      expect(rules.index(failed_red.first)).to be < rules.index(failed_yellow.first)
      expect(rules.index(failed_yellow.first)).to be < rules.index(passed.first)
    end
  end
end
