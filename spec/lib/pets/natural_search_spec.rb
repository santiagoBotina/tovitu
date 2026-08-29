require "rails_helper"

RSpec.describe Pets::NaturalSearch do
  let(:shelter) { create(:shelter) }
  let!(:dog) do
    create(:pet, shelter: shelter, species: "dog", size: "medium", age_category: "adult",
           sex: "male", description: "A calm and friendly dog", created_at: 3.days.ago)
  end
  let!(:cat) do
    create(:pet, shelter: shelter, species: "cat", size: "medium", age_category: "adult",
           sex: "male", description: "An independent cat", created_at: 2.days.ago)
  end
  let!(:rabbit) do
    create(:pet, shelter: shelter, species: "rabbit", size: "small", age_category: "young",
           sex: "female", description: "A quiet rabbit", created_at: 1.day.ago)
  end

  let(:pets) { Pet.where(shelter: shelter) }

  describe "#call" do
    context "with a species intent" do
      let(:intent) do
        {
          "species" => [ "dog" ], "size" => [], "age_category" => [], "sex" => [],
          "temperament" => [], "living_situation" => [], "energy_level" => [],
          "keywords" => [], "understood" => [ "A dog" ], "valid" => true
        }
      end

      it "ranks the matching species first" do
        result = described_class.call(pets: pets, intent: intent)
        expect(result.data["ordered_ids"].first).to eq(dog.id)
      end

      it "hard-excludes other species when one is explicitly requested" do
        result = described_class.call(pets: pets, intent: intent)
        expect(result.data["ordered_ids"]).to eq([ dog.id ])
        expect(result.data["ordered_ids"]).not_to include(cat.id, rabbit.id)
      end

      it "reports the species match in reasons" do
        result = described_class.call(pets: pets, intent: intent)
        expect(result.data["reasons"][dog.id]["matched"]["species"]).to be true
      end

      it "returns the candidate count of the constrained set" do
        result = described_class.call(pets: pets, intent: intent)
        expect(result.data["count"]).to eq(1)
      end

      it "returns an empty ordered list when no pet matches the requested species" do
        result = described_class.call(pets: pets, intent: intent.merge("species" => [ "bird" ]))
        expect(result.data["ordered_ids"]).to eq([])
        expect(result.data["count"]).to eq(0)
      end
    end

    context "when size, age, and text affinity combine" do
      let(:intent) do
        {
          "species" => [ "dog" ], "size" => [ "medium" ], "age_category" => [ "adult" ],
          "sex" => [], "temperament" => [ "calm" ], "living_situation" => [],
          "energy_level" => [], "keywords" => [ "calm dog" ],
          "understood" => [ "A calm medium dog" ], "valid" => true
        }
      end

      let!(:other_dog) do
        create(:pet, shelter: shelter, species: "dog", size: "large", age_category: "senior",
               sex: "female", description: "Energetic and playful", created_at: 4.days.ago)
      end

      it "ranks the pet matching more dimensions first" do
        result = described_class.call(pets: pets, intent: intent)
        expect(result.data["ordered_ids"].first).to eq(dog.id)
        expect(result.data["ordered_ids"].index(dog.id)).to be < result.data["ordered_ids"].index(other_dog.id)
      end

      it "records matched temperament tokens" do
        result = described_class.call(pets: pets, intent: intent)
        expect(result.data["reasons"][dog.id]["temperament"]).to include("calm")
      end
    end

    context "with accent-insensitive text matching" do
      let(:intent) do
        {
          "species" => [], "size" => [], "age_category" => [], "sex" => [],
          "temperament" => [ "carinoso" ], "living_situation" => [],
          "energy_level" => [], "keywords" => [], "understood" => [],
          "valid" => true
        }
      end

      let!(:calm_pet) do
        create(:pet, shelter: shelter, species: "dog", description: "Es un perro cariñoso",
               created_at: 5.days.ago)
      end

      it "matches tokens ignoring accents" do
        result = described_class.call(pets: pets, intent: intent)
        expect(result.data["reasons"][calm_pet.id]["temperament"]).to include("carinoso")
      end
    end

    context "with a contradictory phrase" do
      let(:intent) do
        {
          "species" => [ "dog" ], "size" => [ "large", "small" ], "age_category" => [],
          "sex" => [], "temperament" => [], "living_situation" => [],
          "energy_level" => [], "keywords" => [ "dog" ], "understood" => [ "A dog" ],
          "valid" => true
        }
      end

      it "does not raise" do
        expect { described_class.call(pets: pets, intent: intent) }.not_to raise_error
      end

      it "returns a successful Result" do
        expect(described_class.call(pets: pets, intent: intent)).to be_success
      end
    end

    context "with a blank intent" do
      let(:intent) { nil }

      it "returns pets ordered by created_at desc" do
        result = described_class.call(pets: pets, intent: intent)
        expect(result.data["ordered_ids"]).to eq([ rabbit.id, cat.id, dog.id ])
      end

      it "returns an empty reasons hash" do
        result = described_class.call(pets: pets, intent: intent)
        expect(result.data["reasons"]).to eq({})
      end

      it "returns the candidate count" do
        result = described_class.call(pets: pets, intent: intent)
        expect(result.data["count"]).to eq(3)
      end
    end

    context "with an invalid intent hash" do
      let(:intent) { { "valid" => false, "species" => [ "dog" ] } }

      it "treats it as a no-op ranking" do
        result = described_class.call(pets: pets, intent: intent)
        expect(result.data["ordered_ids"]).to eq([ rabbit.id, cat.id, dog.id ])
      end
    end

    context "with a symbol-keyed intent hash" do
      # The service contract is STRING keys (the hash produced by
      # Ai::ExtractSearchIntent). A symbol-keyed hash must not crash and must
      # not silently match on nil values.
      let(:intent) { { species: [ "dog" ], valid: true } }

      it "does not raise" do
        expect { described_class.call(pets: pets, intent: intent) }.not_to raise_error
      end

      it "treats it as a no-op ranking" do
        result = described_class.call(pets: pets, intent: intent)
        expect(result.data["ordered_ids"]).to eq([ rabbit.id, cat.id, dog.id ])
      end
    end

    context "when the text affinity cap is reached" do
      let(:intent) do
        {
          "species" => [ "dog" ], "size" => [], "age_category" => [], "sex" => [],
          "temperament" => (1..20).map { |i| "token#{i}" },
          "living_situation" => [], "energy_level" => [], "keywords" => [],
          "understood" => [], "valid" => true
        }
      end

      let!(:many_tokens) do
        create(:pet, shelter: shelter, species: "dog",
               description: (1..20).map { |i| "token#{i}" }.join(" "),
               created_at: 2.days.ago)
      end
      let!(:few_tokens) do
        create(:pet, shelter: shelter, species: "dog",
               description: (1..10).map { |i| "token#{i}" }.join(" "),
               created_at: 1.day.ago)
      end

      it "caps the text score so extra tokens do not dominate the ranking" do
        result = described_class.call(pets: pets, intent: intent)
        # Both pets hit the +40 text cap; species ties; tie-break is created_at desc.
        expect(result.data["ordered_ids"].index(few_tokens.id)).to be < result.data["ordered_ids"].index(many_tokens.id)
      end
    end

    context "when given an array of pets instead of a relation" do
      let(:intent) do
        {
          "species" => [ "dog" ], "size" => [], "age_category" => [], "sex" => [],
          "temperament" => [], "living_situation" => [], "energy_level" => [],
          "keywords" => [], "understood" => [], "valid" => true
        }
      end

      it "ranks the array the same way after constraining by species" do
        result = described_class.call(pets: [ cat, dog, rabbit ], intent: intent)
        expect(result.data["ordered_ids"]).to eq([ dog.id ])
        expect(result.data["count"]).to eq(1)
      end
    end
  end
end
