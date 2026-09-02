require "rails_helper"

RSpec.describe "Pets" do
  let(:shelter) { create(:shelter) }
  let(:pet) { create(:pet, shelter: shelter) }

  describe "GET /pets" do
    it "allows unauthenticated visitors to browse the pets index" do
      get pets_path
      expect(response).to have_http_status(:ok)
    end

    it "filters results by query" do
      create(:pet, name: "Beagle Buddy")
      create(:pet, name: "Whiskers")

      get pets_path, params: { query: "Beagle" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Beagle Buddy")
      expect(response.body).not_to include("Whiskers")
    end

    it "includes the exploration memory controller on the filter form" do
      get pets_path

      expect(response.body).to include("data-controller=\"exploration-memory\"")
      expect(response.body).to include("data-exploration-memory-mode-value=\"save\"")
      expect(response.body).to include("data-exploration-memory-signed-in-value=\"false\"")
    end

    it "uses the localStorage interest button for signed-out visitors" do
      pet # materialize before the request so the card renders
      get pets_path

      expect(response.body).to include("data-controller=\"pet-interest\"")
      expect(response.body).to include("data-pet-interest-id-value=\"#{pet.id}\"")
      expect(response.body).not_to include(pet_save_path(pet_id: pet.id))
    end

    it "uses the server-backed save button for signed-in visitors" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }
      pet # materialize before the request so the card renders

      get pets_path

      expect(response.body).to include(%(id="save-button-#{pet.id}"))
      expect(response.body).to include(pet_save_path(pet_id: pet.id))
      expect(response.body).not_to include("data-controller=\"pet-interest\"")
      # Exploration memory is gated off for signed-in users.
      expect(response.body).to include("data-exploration-memory-signed-in-value=\"true\"")
    end

    it "renders the age badge with the English age unit" do
      pet_with_birth = create(:pet, shelter: shelter, age_category: "adult", birth_date: 5.years.ago)
      get pets_path(locale: :en)

      expect(response.body).to include("Adult (5 years)")
    end

    it "renders the age badge with the Spanish age unit" do
      pet_with_birth = create(:pet, shelter: shelter, age_category: "adult", birth_date: 5.years.ago)
      get pets_path(locale: :es)

      expect(response.body).to include("Adulto (5 años)")
      expect(response.body).not_to include("years")
    end

    it "renders the age badge without a birth date using only the localized category" do
      pet_without_birth = create(:pet, shelter: shelter, age_category: "senior", birth_date: nil)
      get pets_path(locale: :es)

      expect(response.body).to include(I18n.t("pets.age_categories.senior", locale: :es))
    end

    it "renders the natural language search field with a visible label and placeholder" do
      get pets_path

      expect(response.body).to include(I18n.t("pets.index.natural_language.label"))
      expect(response.body).to include(I18n.t("pets.index.natural_language.placeholder"))
      expect(response.body).to include(%(name="intent"))
      expect(response.body).to include(I18n.t("pets.index.natural_language.submit"))
    end

    it "pre-fills the natural language field with the current intent" do
      allow(Ai::Provider).to receive(:call).and_return(default_search_intent_response.to_json)
      get pets_path, params: { intent: "un perro tranquilo para departamento" }

      expect(response.body).to include(%(value="un perro tranquilo para departamento"))
    end

    it "renders the understood panel, results header, and reasons for a valid intent" do
      allow(Ai::Provider).to receive(:call).and_return(default_search_intent_response.to_json)
      calm = create(:pet, shelter: shelter, species: "dog", size: "small",
                     personality_traits: [ "calm" ], description: "Great in an apartment")
      create(:pet, shelter: shelter, species: "bird")

      get pets_path, params: { intent: "un perro tranquilo para departamento" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("pets.index.natural_language.understood_title"))
      expect(response.body).to include(I18n.t("pets.index.natural_language.search_title"))
      expect(response.body).to include(calm.name)
      expect(response.body).to include(I18n.t("pets.index.natural_language.reasons_title"))
      expect(response.body).to include(I18n.t("pets.index.natural_language.match_keyword", keyword: "calm"))
    end

    it "excludes species the user did not describe" do
      allow(Ai::Provider).to receive(:call).and_return(default_search_intent_response.to_json)
      # Explicit bird name avoids a Faker collision with the dog's name, which
      # would otherwise make the negative assertion below flaky.
      bird = create(:pet, shelter: shelter, name: "Feathered Friend", species: "bird", created_at: 3.days.ago)
      dog = create(:pet, shelter: shelter, species: "dog", size: "small",
                   personality_traits: [ "calm" ], created_at: 1.day.ago)

      get pets_path, params: { intent: "un perro tranquilo para departamento" }

      expect(response.body).to include(dog.name)
      expect(response.body).not_to include(bird.name)
    end

    it "renders the friendly invalid banner and plain browse for an unreadable phrase" do
      allow(Ai::Provider).to receive(:call).and_return(default_invalid_search_intent_response.to_json)
      visible = create(:pet, shelter: shelter, name: "Still Visible")
      get pets_path, params: { intent: "asdfghjkl" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(CGI.escapeHTML(I18n.t("pets.index.natural_language.invalid_title")))
      expect(response.body).to include(visible.name)
      expect(response.body).not_to include(I18n.t("pets.index.natural_language.search_title"))
    end

    it "falls back to plain browse without crashing when the AI provider fails" do
      allow(Ai::Provider).to receive(:call).and_raise(Ai::ProviderError, "boom")
      create(:pet, shelter: shelter, name: "Graceful Pet")

      get pets_path, params: { intent: "un perro tranquilo" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Graceful Pet")
      expect(response.body).to include(CGI.escapeHTML(I18n.t("pets.index.natural_language.invalid_title")))
    end

    it "renders the distinct natural-language empty state when nothing ranks" do
      allow(Ai::Provider).to receive(:call).and_return(default_search_intent_response.to_json)

      get pets_path, params: { intent: "un conejo gigante de tres patas" }

      expect(response.body).to include(I18n.t("pets.index.natural_language.empty_title"))
      expect(response.body).to include(I18n.t("pets.index.natural_language.browse_all"))
      expect(response.body).not_to include(I18n.t("pets.index.no_results"))
    end

    it "renders all six species filter chips" do
      get pets_path

      Pet::SPECIES.each do |species|
        expect(response.body).to include(I18n.t("pets.species.#{species}"))
      end
    end

    it "renders the species emoji next to the species label on pet cards" do
      rabbit = create(:pet, shelter: shelter, species: "rabbit")
      get pets_path

      expect(response.body).to include(Pet::SPECIES_EMOJI["rabbit"])
      expect(response.body).to include(I18n.t("pets.species.rabbit"))
    end

    it "renders legacy 'other' species pets without breaking" do
      legacy = create(:pet, shelter: shelter, species: "other")
      get pets_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(legacy.name)
      expect(response.body).to include(Pet::SPECIES_EMOJI["other"])
    end

    it "combines a natural-language intent with structured filters (filters constrain, NL ranks)" do
      allow(Ai::Provider).to receive(:call).and_return(default_search_intent_response.to_json)
      # Explicit names avoid Faker collisions between the two dogs (and the cat),
      # which would make the ranking assertion below non-deterministic.
      dog = create(:pet, shelter: shelter, name: "Calm Apartment Dog", species: "dog", size: "small",
                   personality_traits: [ "calm" ], description: "Great in an apartment")
      other_dog = create(:pet, shelter: shelter, name: "Energetic Large Dog", species: "dog", size: "large",
                        personality_traits: [ "energetic" ])
      cat = create(:pet, shelter: shelter, name: "Quiet Cat", species: "cat", size: "small",
                  personality_traits: [ "calm" ])

      get pets_path, params: { intent: "un perro tranquilo para departamento", species: "dog" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(dog.name)
      expect(response.body).to include(other_dog.name)
      expect(response.body).not_to include(cat.name)
      # The species-matching, size-matching dog ranks first within the constrained set.
      expect(response.body.index(dog.name)).to be < response.body.index(other_dog.name)
    end

    it "escapes a malicious intent value echoed into the search field" do
      allow(Ai::Provider).to receive(:call).and_return(default_invalid_search_intent_response.to_json)
      get pets_path, params: { intent: %q{<script>alert(1)</script>" onfocus="alert(2)} }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("&lt;script&gt;alert(1)&lt;/script&gt;")
      expect(response.body).not_to include("<script>alert(1)</script>")
    end

    it "treats a whitespace-only intent as plain browse without calling the AI provider" do
      create(:pet, shelter: shelter, name: "Whitespace Pet")
      expect(Ai::Provider).not_to receive(:call)

      get pets_path, params: { intent: "   \n\t  " }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Whitespace Pet")
      expect(response.body).not_to include(I18n.t("pets.index.natural_language.invalid_title"))
    end

    it "handles a very long intent phrase without crashing" do
      allow(Ai::Provider).to receive(:call).and_return(default_search_intent_response.to_json)
      dog = create(:pet, shelter: shelter, species: "dog", size: "small",
                   personality_traits: [ "calm" ])
      long_phrase = "quiero un perro tranquilo para departamento " * 30

      get pets_path, params: { intent: long_phrase }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(dog.name)
    end

    it "paginates natural-language results in ranked order" do
      allow(Ai::Provider).to receive(:call).and_return(default_search_intent_response.to_json)
      best = create(:pet, shelter: shelter, species: "dog", size: "small",
                    personality_traits: [ "calm" ], description: "Great in an apartment", name: "Best Match")
      middle = create(:pet, shelter: shelter, species: "dog", size: "small",
                     personality_traits: [ "calm" ], name: "Middle Match")
      worst = create(:pet, shelter: shelter, species: "dog", size: "large",
                    personality_traits: [ "energetic" ], name: "Worst Match")

      get pets_path, params: { intent: "un perro tranquilo para departamento", per_page: 2 }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(best.name)
      expect(response.body).to include(middle.name)
      expect(response.body).not_to include(worst.name)
    end

    it "does not crash on abusive per_page values in natural-language search" do
      allow(Ai::Provider).to receive(:call).and_return(default_search_intent_response.to_json)
      create(:pet, shelter: shelter, species: "dog", size: "small", personality_traits: [ "calm" ])

      [ "0", "-5", "abc", "999999" ].each do |per_page|
        get pets_path, params: { intent: "un perro tranquilo", per_page: per_page }
        expect(response).to have_http_status(:ok), "per_page=#{per_page} should not crash"
      end
    end

    it "does not crash on abusive per_page values in plain browse" do
      create(:pet, shelter: shelter, name: "Browse Pet")

      [ "0", "-5", "abc", "999999" ].each do |per_page|
        get pets_path, params: { per_page: per_page }
        expect(response).to have_http_status(:ok), "per_page=#{per_page} should not crash"
      end
    end

    it "preserves the intent param when a species filter chip is clicked" do
      allow(Ai::Provider).to receive(:call).and_return(default_search_intent_response.to_json)
      get pets_path, params: { intent: "un perro tranquilo" }

      expect(response.body).to include(%(species=dog))
      expect(response.body).to include(CGI.escape("un perro tranquilo"))
    end
  end

  describe "GET /pets/:id" do
    it "allows unauthenticated visitors to view an available pet profile" do
      get pet_path(pet)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(pet.name)
      expect(response.body).to include(I18n.t("pets.show.apply_to_adopt"))
    end

    it "links back to the homepage when arriving from a featured pet card" do
      get pet_path(pet, back_to: root_path)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(href="#{root_path}"))
      expect(response.body).to include(CGI.escapeHTML(I18n.t("shared.back_to_home")))
      expect(response.body).not_to include(%(href="#{pets_path}"))
    end

    it "links back to the pets listing by default" do
      get pet_path(pet)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(href="#{pets_path}"))
      expect(response.body).to include(I18n.t("pets.show.back_to_pets"))
    end

    it "links back to the provided back_to path when arriving from an adoption request" do
      request_path = adoption_request_path(id: 123)
      get pet_path(pet, back_to: request_path)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(href="#{request_path}"))
      expect(response.body).not_to include(%(href="#{pets_path}"))
    end

    it "falls back to the pets listing for an unsafe back_to value" do
      get pet_path(pet, back_to: "https://evil.com")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(href="#{pets_path}"))
      expect(response.body).not_to include("evil.com")
    end

    it "renders the labeled save button for signed-out visitors" do
      get pet_path(pet)

      expect(response.body).to include(%(id="save-button-#{pet.id}-label"))
      expect(response.body).to include("data-controller=\"pet-interest\"")
      expect(response.body).to include(CGI.escapeHTML(I18n.t("pets.show.save_to_favorites")))
      expect(response.body).not_to include(pet_save_path(pet_id: pet.id))
    end

    it "renders both save controls for signed-in visitors" do
      user = create(:user, :verified, :onboarding_completed)
      post session_path, params: { session: { email: user.email, password: "password123" } }

      get pet_path(pet)

      expect(response.body).to include(%(id="save-button-#{pet.id}"))
      expect(response.body).to include(%(id="save-button-#{pet.id}-label"))
      expect(response.body).to include(pet_save_path(pet_id: pet.id))
      expect(response.body).to include(CGI.escapeHTML(I18n.t("pets.show.save_to_favorites")))
    end

    it "renders the age badge on the pet profile in English" do
      pet_with_birth = create(:pet, shelter: shelter, age_category: "adult", birth_date: 5.years.ago)
      get pet_path(pet_with_birth, locale: :en)

      expect(response.body).to include("Adult (5 years)")
    end

    it "renders the age badge on the pet profile in Spanish" do
      pet_with_birth = create(:pet, shelter: shelter, age_category: "adult", birth_date: 5.years.ago)
      get pet_path(pet_with_birth, locale: :es)

      expect(response.body).to include("Adulto (5 años)")
      expect(response.body).not_to include("years")
    end
  end
end
