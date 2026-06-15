# Plan: AI

**Domain:** AI
**Priority:** 5 (core differentiator, differentiates Tovitu from basic pet listing platforms)
**Status:** Draft

---

## User Stories

1. As a **shelter staff member**, I want to **generate an AI life preview for a pet** so that adopters can visualize the pet's future personality and needs.
2. As a **prospective adopter**, I want to **see an AI life preview on a pet's profile** so that I can understand what owning this pet might be like.
3. As a **shelter staff member**, I want to **run a compatibility analysis between an applicant and a pet** so that I can make better adoption decisions.
4. As a **shelter admin**, I want to **batch-generate life previews for all my pets** so that I can efficiently enhance their profiles.
5. As a **prospective adopter**, I want to **see a compatibility score for my application** so that I understand how well I match with the pet.
6. As a **shelter staff member**, I want to **regenerate an AI preview with updated information** so that it stays accurate.

---

## Description

The AI domain is Tovitu's core differentiator — reducing failed adoptions by giving adopters a realistic preview of what life with a pet will be like, and helping shelters match pets with the right homes.

Two main AI features in MVP:

1. **Life Preview** — Given a pet's breed, age, size, personality traits, and medical notes, the AI generates a rich narrative describing what daily life with this pet might look like: energy levels, grooming needs, training difficulty, ideal home environment, common behavioral traits, and estimated costs. The life preview appears on the pet's public profile.

2. **Compatibility Analysis** — Given an adoption application and a pet's profile, the AI analyzes the match and produces a compatibility score (1-100) with a breakdown of strengths and concerns. This helps shelters triage applications and helps adopters self-assess.

Both features are provider-agnostic. The MVP uses Anthropic's Claude API, but the service objects wrap this behind an interface that could swap to OpenAI, Google, or a local model without changing business logic.

All prompts are stored in `config/prompts/` as YAML files — never hardcoded in Ruby.

---

## Acceptance Criteria

### AC1: Generate Life Preview
```
Given I am logged in as a shelter staff member
When I view a pet's management page
And I click "Generate AI Life Preview"
Then the system sends pet data to the AI provider
And a life preview text is generated
And the preview is saved to the pet record
And it appears on the public pet profile
And the generation is logged in the audit trail

Given a pet's life preview has been generated
When new information is added to the pet's profile
Then the existing preview shows a "needs update" indicator
And the staff can regenerate with updated data
```

### AC2: View Life Preview
```
Given I am viewing a pet's public profile
When the pet has an AI life preview
Then I see a "Life with [Pet Name]" section containing:
  - Sample daily routine description
  - Energy level and exercise needs
  - Grooming and care requirements
  - Training difficulty assessment
  - Ideal home environment
  - Estimated monthly cost range
  - Common behavioral traits for the breed/type
  - A note that "this is AI-generated and may not reflect the individual pet"

Given I am viewing a pet's public profile
When the pet does not have a life preview
Then no AI section is shown (graceful degradation)
```

### AC3: Batch Generate Previews
```
Given I am logged in as a shelter staff member
When I select multiple pets and click "Generate AI Previews"
Then a background job is queued for each selected pet
And I see a progress indicator
And when complete, I receive a notification
And each pet's profile is updated with its preview
```

### AC4: Compatibility Analysis
```
Given I am logged in as a shelter staff member
When I view an adoption application
Then I see a "Compatibility Analysis" section (if enabled for the shelter)
And the analysis includes:
  - An overall compatibility score (1-100)
  - Strengths (areas where the applicant matches the pet's needs)
  - Concerns (potential mismatches or risks)
  - Recommended questions for the shelter to ask the applicant

Given an application has been approved or rejected
When the staff views it
Then the compatibility analysis is preserved as a historical record
```

### AC5: Automatic Compatibility on Application Submission
```
Given a shelter has AI compatibility analysis enabled
When a new adoption application is submitted
Then a background job automatically generates a compatibility analysis
And the analysis is available when staff views the application
```

### AC6: AI Feature Toggle
```
Given I am a shelter admin
When I visit shelter settings
Then I can enable or disable AI features (life preview, compatibility)
And disabled features do not appear in the UI or trigger API calls

Given AI features are disabled
When an adopter views a pet profile
Then no AI sections are shown
And no API calls are made
```

---

## Business Rules

1. **Provider-agnostic** — all AI logic goes through `Ai::BaseProvider` interface. No Anthropic-specific code outside the adapter.
2. **Prompts in YAML** — stored in `config/prompts/`. Never inline prompts in Ruby code.
3. **Prompts are versioned** — each prompt YAML file has a `version` field. When prompts change, old previews are flagged as "stale".
4. **Async generation** — life preview and compatibility generation run as Sidekiq jobs. Never synchronous.
5. **Caching** — generated previews are cached on the pet record. Regeneration overwrites.
6. **Rate limiting** — respect AI provider rate limits. Queue jobs with appropriate throttling.
7. **Fallback** — if AI provider is unavailable, return a clear error, do not block the user flow.
8. **Opt-out** — shelters can opt out of AI features entirely.
9. **Disclaimers** — every AI-generated section must display "This content was generated by AI and may not be 100% accurate. Always consult with shelter staff."
10. **No PII in prompts** — never send applicant PII (name, email, phone, address) to the AI provider. Send only relevant attributes (pet experience, housing type, current pets, questionnaire answers).
11. **Token tracking** — log token usage per generation for cost tracking.
12. **Test mode** — in test/development, use a mock provider that returns deterministic responses.

---

## User Flow

### Life Preview Generation Flow
1. Staff clicks "Generate AI Life Preview" on pet management page
2. System queues `Ai::GenerateLifePreviewJob` with pet_id
3. Job executes:
   a. Loads pet data (name, species, breed, age, size, personality traits, medical notes, requirements)
   b. Loads prompt template from `config/prompts/life_preview.yml`
   c. Builds prompt with pet data substitutions
   d. Calls `Ai::Provider.new.generate(prompt)`
   e. Parses and validates AI response
   f. Saves result to `pet.life_preview` (text)
   g. Updates `pet.life_preview_generated_at` timestamp
   h. Creates audit log entry
4. Staff sees updated preview on page refresh (polling or Turbo Stream)

### Compatibility Analysis Flow
1. New adoption application is submitted
2. Event hook triggers `Ai::CompatibilityAnalysisJob`
3. Job executes:
   a. Loads application data and pet data
   b. Strips PII from application data
   c. Loads prompt template from `config/prompts/compatibility.yml`
   d. Builds prompt with application + pet data
   e. Calls AI provider
   f. Parses response (expects JSON: score, strengths[], concerns[], recommended_questions[])
   g. Saves to `adoption_application.compatibility_data` (jsonb)
   h. Creates audit log entry
4. Analysis appears on staff review page

---

## Edge Cases & Error States

| Edge Case | Handling |
|-----------|----------|
| AI provider returns error/timeout | Retry with exponential backoff (max 3 times). After failure, show "analysis unavailable" on UI. |
| AI response is malformed/incomplete | Validate response format. If invalid, retry with stricter prompt. If persistent, flag for manual review. |
| Token limit exceeded for large pets | Truncate pet description if it exceeds context window. Log warning. |
| Pet has insufficient data for meaningful preview | Check minimum data requirements before sending. If insufficient, skip with "add more pet details to generate preview". |
| AI generates inappropriate content | Implement content filtering on response. If flagged, reject and regenerate. |
| Shelter disables AI mid-generation | Check toggle at job execution time. If disabled, abort silently. |
| Concurrent generation for same pet | Lock: prevent duplicate jobs for same pet. If job already queued, show "generation in progress". |
| AI provider API key missing/expired | Disable AI features gracefully. Show "AI features unavailable" with contact admin message. |
| Batch job partially fails | Log per-pet failure. Report summary: "7 of 10 previews generated successfully. 2 pets had insufficient data, 1 pet failed." |

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Life preview generation rate | > 80% of pets have a preview |
| Life preview → application rate | +10% increase vs pets without preview |
| Compatibility analysis accuracy | > 85% staff satisfaction rating |
| AI feature opt-in rate (shelters) | > 90% |
| Average generation time | < 15 seconds per preview |
| Token cost per preview | < $0.05 |
| API error rate | < 2% of requests |

---

## Dependencies / Prerequisites

- Pets (Phase 3) — life preview requires pet data
- Adoptions (Phase 4) — compatibility analysis requires application data
- Sidekiq + Redis — async job processing
- Anthropic API key (in production)
- `config/prompts/` directory structure (already exists)
- `Ai::BaseProvider` adapter interface
- Token usage tracking (for cost monitoring)

---

## Open Questions / Risks

1. **AI hallucination risk** — life previews could make inaccurate claims about a pet. Mitigation: strong disclaimers, manual review option for shelters, feedback mechanism for adopters to report inaccurate previews.
2. **Cost at scale** — if every pet gets a life preview and every application gets compatibility analysis, costs could be significant. Mitigation: track token usage, set monthly budget caps, allow shelters to pay for premium AI features.
3. **Prompt injection via pet name/description** — a pet named "Ignore all previous instructions" could be used for prompt injection. Mitigation: sanitize inputs, use system prompts carefully, validate outputs.
4. **Bias in AI analysis** — AI could exhibit breed/age bias (e.g., recommending against "pit bull type" dogs). Mitigation: review prompts for bias, include diversity guidelines in system prompts.
5. **Structured output parsing** — AI responses need to be parsed reliably. Use JSON mode / function calling when available. Have fallback parsing.
6. **Regulatory compliance** — if AI is used for adoption decisions, there may be legal implications. Discussion: AI analysis is advisory only; final decisions are made by shelter staff.
7. **Cache invalidation** — when pet data changes, how quickly should life previews be flagged as stale? MVP: manual regeneration trigger. Future: auto-regenerate on significant changes.

---

## Technical Notes

### Prompt Management

Prompts stored as YAML in `config/prompts/`:
```yaml
# config/prompts/life_preview.yml
version: 1
system_prompt: |
  You are an expert pet behavior and care consultant. Given a pet's profile,
  generate a realistic and detailed "day in the life" preview...
user_prompt: |
  Pet Name: {{name}}
  Species: {{species}}
  Breed: {{breed}}
  ...
response_format: |
  Provide a narrative in the following sections:
  1. Daily Routine
  2. Energy & Exercise
  ...
```

### Models (Data)
```
Pet
  - life_preview (text, nullable)
  - life_preview_generated_at (datetime, nullable)
  - life_preview_stale (boolean, default: false)
  - ai_features_enabled (boolean, default: true) — inherited from shelter

AdoptionApplication
  - compatibility_data (jsonb, nullable)
    {
      "score": 85,
      "strengths": ["Has prior dog experience", "Has fenced yard"],
      "concerns": ["Works long hours", "Lives in apartment"],
      "recommended_questions": ["How will you exercise the dog during work hours?"]
    }
  - compatibility_generated_at (datetime, nullable)
```

### Service Objects
- `Ai::GenerateLifePreview` — orchestrates preview generation
- `Ai::CompatibilityAnalyzer` — orchestrates compatibility analysis
- `Ai::PromptBuilder` — builds prompts from templates + data
- `Ai::Provider` — adapter that wraps the actual AI API client

### Provider Interface
```
# lib/ai/base_provider.rb
class Ai::BaseProvider
  def generate(prompt, options = {})
    raise NotImplementedError
  end

  def generate_structured(prompt, schema, options = {})
    raise NotImplementedError
  end
end
```

### Jobs
- `Ai::GenerateLifePreviewJob` — Sidekiq job for single pet preview
- `Ai::BatchGenerateLifePreviewJob` — Sidekiq job that enqueues individual preview jobs
- `Ai::CompatibilityAnalysisJob` — Sidekiq job triggered on application submission

### Controllers
- `Shelters::AiSettingsController` — toggle AI features
- `Shelters::Pets::LifePreviewsController` — trigger/manage life previews
- `Shelters::AdoptionApplications::CompatibilityController` — trigger/review analysis

### Routes (Additions)
```
namespace :shelter do
  resources :pets do
    resource :life_preview, only: [:create, :update], controller: "pets/life_previews"
  end
  resources :adoption_applications do
    resource :compatibility, only: [:show, :create], controller: "adoption_applications/compatibility"
  end
  resource :ai_settings, only: [:edit, :update]
end
```

### Testing Notes
- Unit test each service object with a mock AI provider
- Test prompt building with various pet data scenarios
- Test malformed AI response handling
- Test that PII is stripped before sending to provider
- Test rate limiting and retry logic
- Test batch generation with mixed success/failure
- Test AI feature toggle — disabled shelters should never call the provider
