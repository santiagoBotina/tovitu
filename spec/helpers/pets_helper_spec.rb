require "rails_helper"

RSpec.describe PetsHelper do
  include PetsHelper

  let(:shelter) { create(:shelter) }

  describe "#pet_species_options" do
    it "returns an option for every supported species" do
      options = pet_species_options
      expect(options.map(&:last)).to eq(Pet::SPECIES)
    end

    it "localizes the species labels" do
      I18n.with_locale(:es) do
        options = pet_species_options
        expect(options.find { |_, value| value == "rabbit" }.first).to eq("Conejo")
      end
    end
  end

  describe "#life_preview_icon_path" do
    it "returns the dog icon for dogs" do
      pet = create(:pet, shelter: shelter, species: "dog")
      expect(life_preview_icon_path(pet)).to eq("/icons/dog.svg")
    end

    it "returns the cat icon for cats" do
      pet = create(:pet, shelter: shelter, species: "cat")
      expect(life_preview_icon_path(pet)).to eq("/icons/cat.svg")
    end

    it "returns nil for every other species so the view falls back to the species emoji" do
      %w[bird rabbit hamster other].each do |species|
        pet = create(:pet, shelter: shelter, species: species)
        expect(life_preview_icon_path(pet)).to be_nil, "expected nil icon for #{species}"
      end
    end
  end

  describe "#life_preview_tip_category_label" do
    it "localizes known tip categories" do
      expect(life_preview_tip_category_label("supplies")).to eq("Supplies")
      expect(life_preview_tip_category_label("home_preparation")).to eq("Home preparation")
    end

    it "localizes known tip categories in Spanish" do
      I18n.with_locale(:es) do
        expect(life_preview_tip_category_label("supplies")).to eq("Suministros")
        expect(life_preview_tip_category_label("home_preparation")).to eq("Preparación del hogar")
      end
    end

    it "falls back to a humanized label for unknown categories" do
      expect(life_preview_tip_category_label("my_custom_category")).to eq("My custom category")
    end
  end

  describe "#life_preview_time_block_style" do
    it "maps morning periods to the morning icon" do
      style = life_preview_time_block_style("morning", 0)
      expect(style[:icon]).to eq("☀️")
    end

    it "maps Spanish time periods" do
      expect(life_preview_time_block_style("mañana", 0)[:icon]).to eq("☀️")
      expect(life_preview_time_block_style("noche", 0)[:icon]).to eq("🌙")
    end

    it "cycles through the palette for unknown periods so icons stay varied" do
      first = life_preview_time_block_style("something_unknown", 0)
      second = life_preview_time_block_style("something_unknown", 1)
      expect(first[:icon]).not_to eq(second[:icon])
    end
  end

  describe "#life_preview_sorted_daily_routine" do
    it "orders English time periods chronologically" do
      routine = { "night" => "Sleep", "morning" => "Walk", "afternoon" => "Play", "midday" => "Lunch" }
      ordered = life_preview_sorted_daily_routine(routine)
      expect(ordered.map(&:first)).to eq([ "morning", "midday", "afternoon", "night" ])
    end

    it "orders Spanish time periods chronologically" do
      routine = { "Noche" => "Dormir", "Mañana" => "Paseo", "Tarde" => "Juego", "Mediodía" => "Comida" }
      ordered = life_preview_sorted_daily_routine(routine)
      expect(ordered.map(&:first)).to eq([ "Mañana", "Mediodía", "Tarde", "Noche" ])
    end

    it "keeps unknown periods at the end in their original order" do
      routine = { "night" => "Sleep", "morning" => "Walk", "custom_thing" => "X", "another" => "Y" }
      ordered = life_preview_sorted_daily_routine(routine)
      expect(ordered.map(&:first)).to eq([ "morning", "night", "custom_thing", "another" ])
    end

    it "returns non-hash routines unchanged" do
      routine = "A simple string routine"
      expect(life_preview_sorted_daily_routine(routine)).to eq(routine)
    end
  end

  describe "#parse_daily_routine" do
    it "passes through a hash routine" do
      routine = { "morning" => "Walk" }
      expect(parse_daily_routine(routine)).to eq(routine)
    end

    it "normalizes an array of time-prefixed strings into a hash" do
      entries = [
        "6:00 PM: Verificar que Peanut tenga agua fresca",
        "8:00 PM: Pasar tiempo observándolo jugar"
      ]
      expect(parse_daily_routine(entries)).to eq({
        "6:00 PM" => "Verificar que Peanut tenga agua fresca",
        "8:00 PM" => "Pasar tiempo observándolo jugar"
      })
    end

    it "splits on the clock separator, not the clock's own colon" do
      parsed = parse_daily_routine([ "6:30 PM: Interactuar con Peanut" ])
      expect(parsed).to eq({ "6:30 PM" => "Interactuar con Peanut" })
    end

    it "handles JSON-encoded arrays" do
      json = '["7:00 AM: Breakfast", "9:00 PM: Bedtime"]'
      expect(parse_daily_routine(json)).to eq({
        "7:00 AM" => "Breakfast",
        "9:00 PM" => "Bedtime"
      })
    end

    it "keeps entries without a time prefix under a numbered label" do
      parsed = parse_daily_routine([ "Just a note about feeding" ])
      expect(parsed.values).to eq([ "Just a note about feeding" ])
      expect(parsed.keys.first).to start_with(I18n.t("pets.show.daily_routine"))
    end

    it "returns a plain string routine unchanged" do
      routine = "Morning walk, feeding, playtime, evening walk."
      expect(parse_daily_routine(routine)).to eq(routine)
    end

    it "returns nil for blank input" do
      expect(parse_daily_routine(nil)).to be_nil
      expect(parse_daily_routine("")).to be_nil
    end
  end
end
