require "rails_helper"

RSpec.describe Ai::GenerateLifePreviewJob do
  subject(:job) { described_class.perform_later(pet.id) }

  let(:shelter) { create(:shelter) }
  let(:pet) { create(:pet, shelter: shelter) }

  describe "#perform" do
    context "when AI features are enabled" do
      before do
        allow(Ai::GenerateLifePreview).to receive(:call).and_return(
          Result.success(default_preview_response)
        )
      end

      it "updates the pet with preview data" do
        expect {
          described_class.perform_now(pet.id)
          pet.reload
        }.to change(pet, :life_preview_data).from(nil)
         .and change(pet, :life_preview_generated_at).from(nil)
         .and change(pet, :life_preview_version).from(0)
      end

      it "sets the preview version from the prompt file" do
        described_class.perform_now(pet.id)
        pet.reload
        expect(pet.life_preview_version).to eq(3)
      end

      it "passes the locale to the generation service" do
        expect(Ai::GenerateLifePreview).to receive(:call).with(
          pet: pet,
          personality_spec: pet.personality_spec,
          adopter_tips: pet.adopter_tips,
          locale: "es"
        ).and_return(Result.success(default_preview_response))

        described_class.perform_now(pet.id, "es")
      end

      it "persists the locale inside the stored preview data" do
        allow(Ai::GenerateLifePreview).to receive(:call).and_return(
          Result.success(default_preview_response.merge("locale" => "es"))
        )

        described_class.perform_now(pet.id, "es")
        pet.reload
        expect(pet.life_preview_data["locale"]).to eq("es")
      end
    end

    context "when AI features are disabled" do
      let(:shelter) { create(:shelter, :with_ai_disabled) }

      it "does not generate a preview" do
        expect(Ai::GenerateLifePreview).not_to receive(:call)
        described_class.perform_now(pet.id)
      end
    end

    context "when generation fails" do
      before do
        allow(Ai::GenerateLifePreview).to receive(:call).and_return(
          Result.failure("API error")
        )
      end

      it "raises an error" do
        expect {
          described_class.perform_now(pet.id)
        }.to raise_error(RuntimeError, "API error")
      end
    end
  end

  describe "#enqueue" do
    it "enqueues the job" do
      expect { job }.to change(ActiveJob::Base.queue_adapter.enqueued_jobs, :size).by(1)
    end
  end
end
