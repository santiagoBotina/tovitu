require "rails_helper"

RSpec.describe "pets/index", type: :view do
  let(:shelter) { create(:shelter) }
  let(:pet) { create(:pet, shelter: shelter, species: "rabbit", size: "small") }

  before do
    # signed_in? is a controller helper_method, not a view helper — define it
    # on the view so the page renders the signed-out save button path.
    view.singleton_class.define_method(:signed_in?) { false }
    assign(:presented_pets, [ PetPresenter.new(pet) ])
    assign(:intent, nil)
    assign(:reasons, nil)
    assign(:nl_error, false)
  end

  def render_index
    render
  end

  context "with default state" do
    before { render_index }

    it "renders the natural language search field with a visible label and placeholder" do
      expect(rendered).to include(I18n.t("pets.index.natural_language.label"))
      expect(rendered).to include(I18n.t("pets.index.natural_language.placeholder"))
      expect(rendered).to include(%(name="intent"))
      expect(rendered).to include(I18n.t("pets.index.natural_language.submit"))
    end

    it "renders all six species filter chips" do
      Pet::SPECIES.each do |species|
        expect(rendered).to include(I18n.t("pets.species.#{species}"))
      end
    end

    it "renders the species emoji next to the species label on pet cards" do
      expect(rendered).to include(Pet::SPECIES_EMOJI["rabbit"])
      expect(rendered).to include(I18n.t("pets.species.rabbit"))
    end
  end

  context "when a natural language intent is active" do
    before do
      controller.request.params[:intent] = "un perro tranquilo"
      assign(:intent, {
        "species" => [ "rabbit" ],
        "size" => [ "small" ],
        "age_category" => [],
        "sex" => [],
        "temperament" => [ "quiet" ],
        "living_situation" => [],
        "energy_level" => [],
        "keywords" => [ "quiet" ],
        "understood" => [ "Conejo", "Pequeño", "tranquilo" ],
        "valid" => true
      })
      render_index
    end

    it "shows what Tovitu understood as chips" do
      expect(rendered).to include(I18n.t("pets.index.natural_language.understood_title"))
      expect(rendered).to include("Conejo")
      expect(rendered).to include("Pequeño")
    end

    it "shows the results header above the grid" do
      expect(rendered).to include(I18n.t("pets.index.natural_language.search_title"))
      expect(rendered).to include(I18n.t("pets.index.natural_language.results_description"))
    end

    it "offers a clear link back to the plain browse page" do
      expect(rendered).to include(I18n.t("pets.index.natural_language.clear"))
      expect(rendered).to include(%(href="#{pets_path}"))
    end

    it "keeps the intent param in the species filter chip links" do
      expect(rendered).to include("intent=")
      expect(rendered).to include("species=rabbit")
    end
  end

  context "when result reasons are present" do
    before do
      assign(:reasons, {
        pet.id => {
          "matched" => { "species" => true, "size" => true, "age" => false, "sex" => false },
          "temperament" => [ "quiet" ]
        }
      })
      render_index
    end

    it "renders the reason chips on the matching card" do
      expect(rendered).to include(I18n.t("pets.index.natural_language.reasons_title"))
      expect(rendered).to include(I18n.t("pets.species.rabbit"))
      expect(rendered).to include(I18n.t("pets.sizes.small"))
      expect(rendered).to include(I18n.t("pets.index.natural_language.match_keyword", keyword: "quiet"))
    end
  end

  context "when result reasons use symbol keys" do
    before do
      assign(:reasons, {
        pet.id => {
          matched: { species: true, size: false, age: false, sex: false },
          temperament: [ "quiet" ]
        }
      })
      render_index
    end

    it "renders the reason chips without crashing" do
      expect(rendered).to include(I18n.t("pets.index.natural_language.reasons_title"))
      expect(rendered).to include(I18n.t("pets.species.rabbit"))
      expect(rendered).to include(I18n.t("pets.index.natural_language.match_keyword", keyword: "quiet"))
    end
  end

  context "when the intent is invalid" do
    before do
      assign(:intent, nil)
      assign(:nl_error, true)
      render_index
    end

    it "renders the friendly invalid banner" do
      expect(rendered).to include(CGI.escapeHTML(I18n.t("pets.index.natural_language.invalid_title")))
      expect(rendered).to include(CGI.escapeHTML(I18n.t("pets.index.natural_language.invalid_body")))
    end
  end

  context "when a natural language search returns no pets" do
    before do
      assign(:presented_pets, [])
      assign(:intent, {
        "species" => [ "hamster" ],
        "size" => [],
        "age_category" => [],
        "sex" => [],
        "temperament" => [],
        "living_situation" => [],
        "energy_level" => [],
        "keywords" => [],
        "understood" => [ "Hámster" ],
        "valid" => true
      })
      render_index
    end

    it "renders the NL-specific empty state with a browse-all action" do
      expect(rendered).to include(I18n.t("pets.index.natural_language.empty_title"))
      expect(rendered).to include(I18n.t("pets.index.natural_language.empty_body"))
      expect(rendered).to include(I18n.t("pets.index.natural_language.browse_all"))
      expect(rendered).not_to include(I18n.t("pets.index.no_results"))
    end
  end

  context "when no pets match the structured filters" do
    before do
      assign(:presented_pets, [])
      render_index
    end

    it "keeps the filter empty state for non-NL searches" do
      expect(rendered).to include(I18n.t("pets.index.no_results"))
      expect(rendered).to include(I18n.t("pets.index.no_results_body"))
      expect(rendered).not_to include(I18n.t("pets.index.natural_language.empty_title"))
    end
  end
end
