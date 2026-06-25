require "rails_helper"

RSpec.describe AdoptionTimelineEvent, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:adoption_application).touch(true) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:event_type) }
    it { is_expected.to validate_inclusion_of(:event_type).in_array(AdoptionTimelineEvent::EVENT_TYPES) }
  end

  describe "scopes" do
    let(:app) { create(:adoption_application) }
    let!(:first_event) { create(:adoption_timeline_event, adoption_application: app, created_at: 3.days.ago) }
    let!(:second_event) { create(:adoption_timeline_event, adoption_application: app, created_at: 1.day.ago) }

    it "chronological orders by created_at asc" do
      expect(AdoptionTimelineEvent.chronological).to eq([ first_event, second_event ])
    end

    it "reverse_chronological orders by created_at desc" do
      expect(AdoptionTimelineEvent.reverse_chronological).to eq([ second_event, first_event ])
    end

    it "since filters by created_at" do
      expect(AdoptionTimelineEvent.since(2.days.ago)).to include(second_event)
      expect(AdoptionTimelineEvent.since(2.days.ago)).not_to include(first_event)
    end
  end
end
