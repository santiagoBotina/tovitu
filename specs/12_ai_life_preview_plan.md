# Plan: AI Life Preview

**Domain:** AI
**Priority:** 5 (core differentiator)
**Status:** Draft
**Depends on:** Pets (Phase 3), AI infrastructure (Phase 5 base), Adoption applications (Phase 4)

---

## Overview

The **Life Preview** feature generates a personalized, AI-powered visualization for potential adopters showing what life with a specific pet would be like. It appears on the pet's public profile page and includes a week-by-week preparation plan, a daily itinerary, and actionable preparation tips.

This extends the existing AI Life Preview infrastructure (`lib/ai/generate_life_preview.rb`, `config/prompts/life_preview.yml`) from a generic "day in the life" narrative to a structured, shelter-informed three-part output: **Plan**, **Itinerary**, and **Tips**.

The feature also adds a new shelter input mechanism — **pet personality specs** and **adopter tips** — which the AI uses as first-class inputs. When shelter staff provides this data, it enriches the generation. When absent, the system falls back to basic pet profile data (breed, species, age, description, personality traits).

---

## Current State

### What exists today

| Asset | Status | Notes |
|-------|--------|-------|
| `specs/5_ai_plan.md` | ✅ Draft | Comprehensive AI strategy covering life preview + compatibility analysis |
| `lib/ai/generate_life_preview.rb` | ✅ Stub | `raise NotImplementedError` — takes `household_info`, `housing_info`, `lifestyle_info` |
| `lib/ai/prompt_builder.rb` | ✅ Implemented | Loads YAML prompts from `config/prompts/`, interpolates `{{variables}}` |
| `lib/ai/compatibility_analyzer.rb` | ✅ Stub | Separate feature |
| `config/prompts/life_preview.yml` | ✅ Exists | Current prompt is adopter-personalized ("Given adopter household, housing, lifestyle, pet details → daily routine, space, financial, time, challenges") |
| `app/views/pets/show.html.erb` | ✅ Exists | Pet profile with: photos, description, medical notes, requirements, compatibility grid, health, shelter sidebar, apply CTA. **No AI section yet.** |
| `app/presenters/pet_presenter.rb` | ✅ Exists | Has `personality_traits_list`, `requirements_list`, `species_label`, etc. |
| Pet model | ✅ Complete | Columns: `personality_traits` (jsonb), `description`, `breed`, `species`, `medical_notes`, `requirements`, `good_with_*` booleans. **No `personality_spec` or `adopter_tips` columns.** |
| Pet migration (`20260615000008`) | ✅ Complete | Schema matches above |
| Shelter model | ✅ Complete | No AI feature toggle yet |
| `Ai::BaseProvider` interface | ❌ Missing | Referenced in `specs/5_ai_plan.md` but not yet implemented |
| Sidekiq jobs for AI | ❌ Missing | Referenced in plan but not implemented |
| AI feature toggle on shelter | ❌ Missing | Referenced in plan but not implemented |

### Key observations

1. The existing `lib/ai/generate_life_preview.rb` is scoped to **adopter-specific personalization** (takes household/housing/lifestyle info). The new feature also needs a **pet-centric generation** that works without adopter info (visible on the public profile).
2. The existing `config/prompts/life_preview.yml` prompt focuses on adopter matching. We need a new pet-centric prompt variant.
3. No database columns exist for shelter-provided personality specs or adopter tips — these must be added.
4. The pet profile view has no AI section and no mechanism to display dynamically loaded content.
5. No lifecycle management (generation, caching, staleness) is implemented.

---

## Requirements

### R1: Life Impact Preview on Pet Profile Page

The pet profile page shall display a "Life with [Pet Name]" section containing three sub-sections:

#### 1. Plan: Week-by-Week Preparation & Integration Timeline

A structured timeline covering the first ~4 weeks after adoption:

| Week | Content |
|------|---------|
| **Week 0 (Pre-Adoption)** | Supplies checklist (bowls, bedding, crate, food, leash, ID tag, etc.), home preparation (pet-proofing, designated spaces), scheduling vet appointment |
| **Week 1 (Arrival)** | First 24–48 hours decompression protocol, introducing the pet to its new environment, establishing a feeding/watering routine, first vet check |
| **Week 2 (Settling In)** | Beginning a training/behavior routine, introducing house rules, exploring the neighborhood (for dogs) or vertical spaces (for cats), monitoring adjustment |
| **Week 3 (Bonding)** | Strengthening the bond through play, enrichment activities, socialization exercises, identifying personality quirks |
| **Week 4+ (Integration)** | Full integration into household routines, advanced training (if applicable), scheduling follow-up vet visit, planning for long-term care |

#### 2. Itinerary: Daily Routines, Feeding Schedules, Vet Visits

- **Sample daily schedule** (hour-by-hour or block-by-block): morning routine, workday care (if adopter works outside home), evening routine, bedtime
- **Feeding guide**: recommended food type/quantity/frequency based on species, breed, age, size
- **Exercise/activity requirements**: daily minimums, types of activities suited to the pet
- **Grooming needs**: frequency, tools needed, professional grooming estimates
- **Vet care schedule**: initial visit, vaccination boosters, spay/neuter follow-ups (if applicable), ongoing preventive care (heartworm, flea/tick, dental)

#### 3. Tips for Preparation

Actionable advice organized by category:
- **Home preparation**: pet-proofing, creating safe zones, removing hazards
- **Supply shopping**: essential items checklist with notes on what to look for
- **Family preparation**: introducing the pet to children, other pets, household members
- **Lifestyle adjustments**: time commitment expectations, schedule changes, travel planning
- **Training resources**: recommended approaches (positive reinforcement, crate training, litter box training), local trainer recommendations, online resources

### R2: Shelter-Provided Personality Specs & Tips

Shelters can optionally provide additional pet-specific context that feeds into the AI generation:

| Field | Type | Description |
|-------|------|-------------|
| `personality_spec` | `text` (nullable) | Free-text personality specification — shelter's detailed assessment of the pet's temperament, quirks, preferences, fears, favorite activities, etc. |
| `adopter_tips` | `text` (nullable) | Free-text tips — shelter's advice for potential adopters (e.g., "Needs a quiet home", "Loves belly rubs but not being picked up", "Working on leash reactivity") |

**Behavior when fields are populated:**
- The AI prompt incorporates these as first-class inputs
- The generated plan, itinerary, and tips should reference and reflect the shelter's specific advice
- The output should feel personalized to the individual pet, not generic breed-level advice

**Behavior when fields are empty:**
- The AI falls back to breed-level knowledge, species-typical behavior, and basic profile info (description, personality_traits, medical_notes, requirements, compatibility flags)
- The output is still useful but less specific to the individual pet

### R3: Tone — 90% Positive, 10% Realistic

The AI output must adhere to a strict tone policy:

- **90% positive/focus on the positive**: Highlight the joys, rewards, and wonderful aspects of living with the pet. Emphasize how preparation leads to a successful adoption. Use encouraging, warm, and supportive language.
- **10% realistic/constructive**: Acknowledge genuine challenges (e.g., "This breed requires significant daily exercise", "Some cats take longer to adjust to new homes") but always frame them as manageable with proper preparation. Never be alarmist or discouraging.
- **No breed discrimination**: Avoid blanket negative statements about breeds. Frame traits neutrally (e.g., "Requires experienced handling" instead of "Aggressive").
- **Empowerment-focused**: Every challenge mentioned must be paired with a corresponding solution or preparation tip.

**Prompt engineering enforcement:**
- The system prompt will include explicit tone instructions with the 90/10 ratio requirement
- A response format specification will require the output to include sections and balanced perspective
- The prompt will include guardrails against overly negative or overly generic content

---

## Proposed Approach

### Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Pet Profile Page                    │
│  ┌─────────────────────────────────────────────────┐ │
│  │  Existing sections (photos, description, etc.)   │ │
│  ├─────────────────────────────────────────────────┤ │
│  │  Life Preview Section (Turbo Frame, lazy load)   │ │
│  │  ┌───────────────────────────────────────────┐   │ │
│  │  │ ★ Plan (Week-by-week timeline)            │   │ │
│  │  │ ★ Itinerary (Daily routines, care)        │   │ │
│  │  │ ★ Tips (Preparation advice)               │   │ │
│  │  │ ─ Generated by AI · Always verify w/ shelter│   │ │
│  │  └───────────────────────────────────────────┘   │ │
│  └─────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘

                    ▲ Turbo Frame GET /pets/:id/life_preview
                    │
┌─────────────────────────────────────────────────────┐
│              LifePreviewsController                   │
│  - Checks cache (pet.life_preview_data)              │
│  - Returns JSON or renders partial                   │
└──────────────┬──────────────────────────────────────┘
               │ if no cached preview or stale
               ▼
┌─────────────────────────────────────────────────────┐
│        Ai::GenerateLifePreviewJob (Sidekiq)           │
│  - Loads pet data + shelter personality/tips          │
│  - Builds prompt via Ai::PromptBuilder                │
│  - Calls Ai::Provider (Anthropic adapter)              │
│  - Parses structured response                         │
│  - Saves to pet.life_preview_data (jsonb)              │
│  - Updates pet.life_preview_generated_at              │
└─────────────────────────────────────────────────────┘
```

### AI Service Object: `Ai::GenerateLifePreview`

**Existing file:** `lib/ai/generate_life_preview.rb`
**Action:** Rewrite from stub to full implementation.

The new service object will support two modes:

1. **Pet-centric mode** (public profile): Takes a `Pet` record and optional shelter-provided personality/tips. Generates plan + itinerary + tips.
2. **Adopter-aware mode** (future): Takes a `Pet` + adopter context (household, living situation). Personalizes the plan for the specific adopter.

For this phase, we implement **mode 1** only.

```ruby
# lib/ai/generate_life_preview.rb
module Ai
  class GenerateLifePreview < ApplicationService
    def initialize(pet:, personality_spec: nil, adopter_tips: nil)
      @pet = pet
      @personality_spec = personality_spec  # shelter-provided free text
      @adopter_tips = adopter_tips          # shelter-provided free text
      super()
    end

    def call
      prompt = Ai::PromptBuilder.call(
        prompt_name: "life_preview",
        variables: prompt_variables
      )
      response = Ai::Provider.call(prompt: prompt, format: :structured)
      parsed = parse_response(response)
      Result.success(parsed)
    rescue Ai::ProviderError => e
      Result.failure(e.message)
    end

    private

    def prompt_variables
      {
        pet_name: pet.name,
        species: pet.species,
        breed: pet.breed.presence || "Mixed",
        age: pet.age_display,
        size: pet.size_label || "Unknown",
        description: pet.description.presence || "No description provided.",
        personality_traits: pet.personality_traits_list.join(", "),
        medical_notes: pet.medical_notes.presence || "None noted.",
        requirements: pet.requirements_list.join(", "),
        good_with_children: pet.good_with_children? ? "Yes" : "No",
        good_with_dogs: pet.good_with_dogs? ? "Yes" : "No",
        good_with_cats: pet.good_with_cats? ? "Yes" : "No",
        spayed_neutered: pet.spayed_neutered? ? "Yes" : "No",
        vaccinated: pet.vaccinated? ? "Yes" : "No",
        special_needs: pet.special_needs? ? "Yes" : "No",
        personality_spec: personality_spec.presence || "Not provided by shelter.",
        adopter_tips: adopter_tips.presence || "Not provided by shelter."
      }
    end

    def parse_response(response)
      JSON.parse(response)
    rescue JSON::ParserError
      raise Ai::ProviderError, "Malformed response from AI provider"
    end

    attr_reader :pet, :personality_spec, :adopter_tips
  end
end
```

### Prompt Engineering

**New prompt file:** `config/prompts/life_preview.yml` (overwrite existing)

```yaml
version: 2
system_prompt: |
  You are Tovitu's AI Pet Adoption Advisor. Your role is to help potential adopters
  visualize what life with a specific pet would be like.

  ## Tone Guidelines (CRITICAL)
  - 90% of the content must be positive, encouraging, and focused on the rewards of adoption.
  - 10% may acknowledge realistic challenges, but ALWAYS pair each challenge with a
    practical solution or preparation tip.
  - Never use alarmist language. Never make blanket negative statements about a breed.
  - Frame everything constructively: "this pet thrives with X" instead of "this pet is bad at Y".
  - Empower the adopter by emphasizing that preparation leads to a successful adoption.

  ## Content Structure
  Generate a JSON response with exactly three sections:

  1. "plan": A week-by-week timeline (Weeks 0 through 4+) covering preparation, arrival,
     settling in, bonding, and integration. Each week should have 3-5 bullet points.

  2. "itinerary": A daily life overview containing:
     - "daily_routine": A sample day broken into time blocks
     - "feeding_guide": Recommended feeding approach for this pet
     - "exercise_needs": Daily activity requirements
     - "grooming": Care and grooming needs
     - "vet_schedule": Recommended veterinary care timeline

  3. "tips": An array of preparation tips organized into categories:
     - "home_preparation": Pet-proofing and setup advice
     - "supplies": Essential items checklist
     - "family_preparation": Introducing to household members/pets
     - "lifestyle_adjustments": Time, schedule, and routine changes
     - "training_resources": Recommended training approaches and resources

  ## Disclaimers
  - End with a brief note: "This preview is AI-generated and based on the available
    information about this pet. Always verify specific needs with shelter staff."

user_prompt: |
  Generate a Life Preview for the following pet:

  **Basic Info**
  - Name: {{pet_name}}
  - Species: {{species}}
  - Breed: {{breed}}
  - Age: {{age}}
  - Size: {{size}}

  **Personality & Behavior**
  - Personality traits: {{personality_traits}}
  - Good with children: {{good_with_children}}
  - Good with dogs: {{good_with_dogs}}
  - Good with cats: {{good_with_cats}}

  **Health**
  - Medical notes: {{medical_notes}}
  - Spayed/Neutered: {{spayed_neutered}}
  - Vaccinated: {{vaccinated}}
  - Special needs: {{special_needs}}

  **Shelter's Description**
  {{description}}

  **Home Requirements**
  {{requirements}}

  **Shelter-Provided Personality Spec (if available)**
  {{personality_spec}}

  **Shelter-Provided Adopter Tips (if available)**
  {{adopter_tips}}

  Respond with a JSON object containing "plan", "itinerary", and "tips" as described.
  Remember the 90/10 tone guideline: 90% positive and encouraging, 10% realistic challenges
  with paired solutions.

response_format: json
```

**Key design decisions:**
- `version: 2` — enables cache staleness detection (if version changes, all cached previews become stale)
- Structured JSON output — makes parsing reliable and enables the view to render sections independently
- Shelter-provided fields at the bottom of the prompt — if empty, AI uses preceding data as fallback
- Tone instructions embedded in system prompt with explicit ratio

### Caching Strategy

Life previews are expensive to generate (~$0.03–0.10 per call). Caching is essential.

**Approach:** Store generated previews directly on the `pets` record as a JSONB column.

| Column | Type | Purpose |
|--------|------|---------|
| `life_preview_data` | `jsonb`, nullable | Cached generated output `{ plan: [...], itinerary: {...}, tips: [...] }` |
| `life_preview_generated_at` | `datetime`, nullable | Timestamp of last successful generation |
| `life_preview_version` | `integer`, default: 0 | Tracks which prompt version generated this preview |

**Cache lifecycle:**
1. **On create/update** (pet profile saved): set `life_preview_stale = true` (or clear preview) to force regeneration
2. **On view** (public profile): if `life_preview_data` is present AND `life_preview_version` matches current prompt version, display cached version — no API call
3. **On view** (if stale/missing): return placeholder/loading state; enqueue background job for generation
4. **On regeneration**: shelter staff can manually trigger regeneration; overwrites cached data
5. **Version bump**: when `config/prompts/life_preview.yml` version changes, all existing previews with older version are considered stale

**Avoiding thundering herd:** Use a locking mechanism (e.g., `with_lock` or Redis atomic check) to prevent duplicate jobs.

### UI Component

**Location on pet profile page:** Insert between the "Home Requirements" section and the "Compatibility" section.

**Behavior:**
- Lazy-loaded via a Turbo Frame with `src` pointing to a new endpoint
- **Loading state:** Skeleton placeholder with gentle pulse animation (3 card outlines)
- **Loaded state:** Three expandable/accordion cards: Plan, Itinerary, Tips
- **Error state:** Collapsed with "Life preview unavailable" message + small retry link
- **Empty state:** If no preview data exists and generation hasn't been triggered yet, show nothing (graceful degradation)
- **Stale state:** Show cached preview with a subtle "This preview may be out of date" banner

**Stimulus controller:** `life_preview_controller.js` for lazy-loading, accordion toggles

### Data Model Changes

```ruby
class AddLifePreviewToPets < ActiveRecord::Migration[8.1]
  def change
    add_column :pets, :life_preview_data, :jsonb
    add_column :pets, :life_preview_generated_at, :datetime
    add_column :pets, :life_preview_version, :integer, default: 0
    add_column :pets, :personality_spec, :text
    add_column :pets, :adopter_tips, :text
    add_column :shelters, :ai_features_enabled, :boolean, default: true
  end
end
```

### Routes

```ruby
resources :pets, only: [:index, :show] do
  resource :life_preview, only: [:show], controller: "life_previews"
end
```

### Controller

```ruby
class LifePreviewsController < ApplicationController
  def show
    @pet = Pet.undiscarded.find(params[:pet_id])
    authorize @pet, :show?

    if @pet.life_preview_data.present? && !preview_stale?
      render json: @pet.life_preview_data
    else
      generate_async
      render json: { status: "generating" }, status: :accepted
    end
  end
end
```

### Sidekiq Job

```ruby
module Ai
  class GenerateLifePreviewJob < ApplicationJob
    queue_as :ai

    def perform(pet_id)
      pet = Pet.find(pet_id)
      return unless pet.shelter.ai_features_enabled?

      result = Ai::GenerateLifePreview.call(
        pet: pet,
        personality_spec: pet.personality_spec,
        adopter_tips: pet.adopter_tips
      )

      if result.success?
        pet.update!(
          life_preview_data: result.data,
          life_preview_generated_at: Time.current,
          life_preview_version: current_prompt_version
        )
      else
        raise result.error
      end
    end
  end
end
```

---

## UI/UX Considerations

### Placement on Pet Profile Page

```
┌──────────────────────────────────────────────┐
│  Photos                                      │
├──────────────────────────────────────────────┤
│  Name, Species, Breed, Status               │
│  Age | Size | Sex | Species                  │
│  Personality Traits (chips)                  │
├──────────────────────────────────────────────┤
│  Description                                 │
├──────────────────────────────────────────────┤
│  Medical Notes                               │
├──────────────────────────────────────────────┤
│  Home Requirements                           │
├──────────────────────────────────────────────┤
│  ★ Life with [Pet Name] (NEW)               │
│  ┌─────────────────────────────────────────┐ │
│  │  📋 Week-by-Week Plan (accordion)      │ │
│  │  📅 Daily Itinerary (accordion)        │ │
│  │  💡 Preparation Tips (accordion)       │ │
│  │  ⓘ AI-generated disclaimer            │ │
│  └─────────────────────────────────────────┘ │
├──────────────────────────────────────────────┤
│  Compatibility (Good with kids/dogs/cats)    │
├──────────────────────────────────────────────┤
│  Health & Care                               │
└──────────────────────────────────────────────┘
  Sidebar: Shelter info, Apply CTA
```

### Visual Design

- **Section header:** "Life with [Pet Name]" — large, friendly typography with a small sparkle/AI icon
- **Accordion cards:** White card with subtle shadow, expandable with smooth animation
- **Loading state:** Three skeleton cards with pulse animation (~80px tall)
- **Error state:** Minimal — small text "We couldn't generate a life preview right now." with "Try again" link
- **Disclaimer:** Small muted text below cards: "This content was generated by AI and may not be 100% accurate. Always consult with shelter staff."

---

## Risks & Unknowns

| Risk | Impact | Mitigation |
|------|--------|------------|
| API cost at scale | High | Cache aggressively (JSONB on pet record). Only generate on first view. |
| Latency on first view | Medium | Show loading state immediately. Use Sidekiq async + Turbo polling. |
| Prompt quality | High | Iterate with real pet profiles. Add preview feedback mechanism. Version prompts. |
| AI hallucination | High | Shelter-provided fields ground the output. Disclaimer on all output. |
| Structured output parsing | Medium | Use Claude's JSON mode. Robust fallback parsing. Retry on failure. |
| Breed bias | Medium | Explicit anti-bias instructions in system prompt. |
| Concurrent generation collisions | Low | Redis lock per pet_id. |

---

## Acceptance Criteria

### AC1: Shelter Provides Personality Spec & Tips
- Shelter staff sees "Personality Spec" and "Adopter Tips" text fields when editing a pet
- Saved data persists and appears on edit page reload
- AI output references shelter-provided info when present
- AI output falls back to basic profile data when absent

### AC2: Life Preview Displays on Public Profile
- "Life with [Pet Name]" section appears on pet profile with cached preview
- Section contains Plan (week-by-week), Itinerary (daily routine/feeding/exercise/grooming/vet), Tips (preparation categories)
- AI-generated disclaimer at bottom
- Loading state shown during generation
- Error state shown on failure with retry link
- No section rendered when shelter has AI disabled

### AC3: Tone Compliance
- Output is ~90% positive, 10% realistic
- Challenges paired with solutions
- No breed-discriminatory language
- Encouraging and empowering overall tone

### AC4: Caching & Staleness
- Cached preview served on repeat views (no new API call)
- Preview marked stale when pet data updated
- Preview marked stale when prompt version changes
- Regeneration triggered on next view after staleness

### AC5: Generation Management (Shelter)
- Shelter staff sees preview status (generated/not generated/stale)
- Can manually trigger regeneration
- Can delete current preview

### AC6: Edge Cases
- AI still generates useful preview from species/breed/age/size alone when no description or traits exist
- Only one generation job per pet (no duplicates)
- Job retries with exponential backoff on failure (max 3)

---

## File Change Summary

### New Files

| File | Purpose |
|------|---------|
| `db/migrate/20260624000001_add_life_preview_to_pets.rb` | Add lifecycle columns + shelter input columns |
| `db/migrate/20260624000002_add_ai_features_to_shelters.rb` | Add `ai_features_enabled` to shelters |
| `app/controllers/life_previews_controller.rb` | Serve cached preview or trigger generation |
| `app/jobs/ai/generate_life_preview_job.rb` | Sidekiq job for async generation |
| `app/javascript/controllers/life_preview_controller.js` | Stimulus controller for lazy-loading + accordion |
| `app/views/pets/_life_preview.html.erb` | Life Preview section partial (Turbo Frame target) |
| `app/views/pets/_life_preview_loading.html.erb` | Skeleton loading state |
| `app/views/pets/_life_preview_error.html.erb` | Error state partial |
| `lib/ai/provider.rb` | AI provider adapter |
| `lib/ai/base_provider.rb` | Abstract base class for providers |
| `spec/lib/ai/generate_life_preview_spec.rb` | Service object unit tests |
| `spec/jobs/ai/generate_life_preview_job_spec.rb` | Job tests |
| `spec/requests/life_previews_spec.rb` | Request specs for endpoint |
| `spec/system/life_preview_spec.rb` | System spec for UI behavior |

### Modified Files

| File | Change |
|------|--------|
| `config/prompts/life_preview.yml` | Rewrite from v1 to v2 (structured JSON, 90/10 tone, plan/itinerary/tips) |
| `lib/ai/generate_life_preview.rb` | Replace stub with full implementation |
| `app/models/pet.rb` | Add `personality_spec`, `adopter_tips` access; lifecycle helpers |
| `app/models/shelter.rb` | Add `ai_features_enabled` scope/helper |
| `app/views/pets/show.html.erb` | Insert Life Preview Turbo Frame |
| `app/presenters/pet_presenter.rb` | Add delegation methods for preview state |
| `config/routes.rb` | Add nested `life_preview` route |
| `config/locales/pets/en.yml` | i18n strings for life preview section |
| `config/locales/pets/es.yml` | Spanish translations |
| `spec/factories/pets.rb` | Add traits for new columns |
| `spec/factories/shelters.rb` | Add `ai_features_enabled` trait |
| `spec/support/ai_provider_stub.rb` | Stub/mock for AI provider in tests |

---

## Implementation Order

1. **Migration & Model** — Add columns, update models
2. **Prompts** — Rewrite `config/prompts/life_preview.yml`
3. **AI Provider** — Create `Ai::BaseProvider` + `Ai::Provider`
4. **Service Object** — Rewrite `lib/ai/generate_life_preview.rb`
5. **Sidekiq Job** — Create `Ai::GenerateLifePreviewJob`
6. **Controller & Routes** — Create `LifePreviewsController` + route
7. **Shelter Form** — Add `personality_spec` and `adopter_tips` to shelter pet form
8. **View Partial** — Create `_life_preview.html.erb` with accordion layout
9. **Stimulus Controller** — Create lazy-loading behavior
10. **Pet Profile Integration** — Insert Turbo Frame into `show.html.erb`
11. **i18n** — Add all user-facing strings
12. **Testing** — Service object specs, request specs, factory updates
13. **Final QA** — Manual review of output quality, edge cases, error states

---

## Future Considerations (Out of Scope)

- Adopter-aware personalization (incorporate questionnaire answers)
- Multi-language generation
- PDF export of life preview
- Shelter review & approval workflow before preview goes live
- Batch generation for all pets
- Feedback loop (adopters/shelters rate helpfulness)
- Auto-regeneration webhook on pet data changes
