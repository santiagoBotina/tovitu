# Specification: Adopter Personality Analysis

**Domain:** AI, Adoptions
**Priority:** 1 (core differentiator)
**Status:** Approved (Phase 1 implementation)
**Source plan:** `specs/25_adopter_personality_analysis_plan.md`
**Owner:** AI Agent (pipeline, prompts, taxonomy). Views/shared partial owned by Frontend after first pass; storage/job orchestration coordinated with Data/Spec agents.

---

## Overview

Tovitu compiles a derived, AI-synthesized picture of each adopter from signals that cost the adopter zero extra effort. Shelters and individual publishers see an **Adopter Insight Card** on the request review page (the page where they already decide). The adopter's experience is unchanged except for a one-line transparency note.

Phase 1 scope (this specification): insight from existing data (onboarding answers, request answers, passive behavioral signals). Phase 2 (micro-questions) and Phase 3 (consent & control) are explicitly out of scope.

---

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Storage | New `adopter_insights` table (cached per adopter) + `pet_fit_data`/`pet_fit_generated_at`/`pet_fit_version` columns on `adoption_requests` | Insight is cached per adopter (rule 9); pet-fit summary is per-request |
| Two-prompt split | `adopter_insight.yml` (identity/archetype/commitment) + `pet_fit_summary.yml` (pet-relative fit) | Caching boundary: the per-adopter profile must not depend on the pet |
| Provider | Keep `Ai::Provider` unchanged (OpenAI-backed HTTParty today) | Plan open question #7; interface stays provider-agnostic so a swap to Anthropic only changes `Ai::Provider` internals |
| Archetype taxonomy | Single source in `Ai::Adopter::Archetype` (stable keys + English meanings for the model); UI labels in `config/locales/*.yml` | Mirrors `Onboarding::Shelter::Personality` precedent; prompts reference locale-neutral keys |
| Freshness | SHA-256 fingerprint of the adopter signal payload + TTL (24h default) | Cheap staleness check; no duplicate work when signals haven't changed |
| Dedupe/locking | Row lock (`with_lock`) on `AdopterInsight` + fingerprint check inside the job | Prevents duplicate concurrent generation |
| Honesty | Statuses `strong_fit`/`possible_mismatch`/`unknown`; unknown when evidence is missing | Business rule 4: never fabricate |
| Self-report precedence | Adopter's `personality` is always stored and rendered alongside the AI archetype when they differ | Business rule 5 / AC5 |
| PII | `Ai::Adopter::SignalCollector` never includes name/email/phone/address | Business rule 2; asserted by test |
| Adopter-facing change | One-line transparency note in the request form only | AC2 |

---

## Data Model

### `adopter_insights`
| Column | Type | Notes |
|--------|------|-------|
| adopter_id | bigint FK → users | unique index |
| data | jsonb | Adopter Insight Profile JSON (see schema below) |
| version | integer | prompt version at generation time |
| signal_fingerprint | string | SHA-256 of signal payload |
| generated_at | datetime | |

### `adoption_requests` (added columns)
| Column | Type | Notes |
|--------|------|-------|
| pet_fit_data | jsonb | Pet-Fit Summary JSON |
| pet_fit_generated_at | datetime | |
| pet_fit_version | integer | prompt version at generation time |

---

## Adopter Insight Profile JSON (cached per adopter)

```json
{
  "archetype": "active_outdoors_partner",
  "self_reported_personality": "adventurous_energetic",
  "archetype_diverges": false,
  "commitment_signals": [
    { "label": "follow_through", "observation": "Applied to 1 pet over 3 weeks and followed it to completion.", "kind": "positive" }
  ],
  "confidence": "medium",
  "provenance": {
    "sources": ["onboarding_answers", "saved_pets", "requests", "response_time"],
    "based_on": "onboarding answers, 2 saved pets, 1 request, ~2h response time",
    "activity_up_to": "2026-08-06"
  }
}
```

### Archetype keys (stable, i18n-friendly)
`active_outdoors_partner`, `homebody_companion`, `first_time_parent`, `experienced_guardian`, `family_builder`, `routine_keeper`, `spontaneous_spirit`, `social_house`. If evidence is insufficient the analyzer must return `null` and the card shows "not enough activity yet".

### `commitment_signals[].kind`
`positive` | `neutral` | `attention` (non-judgmental framing).

### Confidence
`high` | `medium` | `low`.

---

## Pet-Fit Summary JSON (per request)

```json
{
  "fit_indicators": {
    "energy": { "status": "strong_fit", "evidence": "They report an active lifestyle and save high-energy dogs." },
    "time": { "status": "possible_mismatch", "evidence": "..." },
    "experience": { "status": "unknown", "evidence": "Not enough activity yet." },
    "home_space": { "status": "strong_fit", "evidence": "..." },
    "household": { "status": "unknown", "evidence": "..." }
  },
  "summary": "2-4 sentences on how this person matches THIS pet.",
  "verification_questions": ["...", "..."],
  "confidence": "medium"
}
```

### Fit dimensions
`energy`, `time`, `experience`, `home_space`, `household`. Statuses: `strong_fit` | `possible_mismatch` | `unknown`. `unknown` must be used whenever evidence is absent — never inferred.

---

## Service Objects (lib/ai/adopter/)

| Service | Responsibility |
|---------|----------------|
| `Archetype` | Taxonomy: stable keys, English meanings for prompts, label lookup for UI |
| `SignalCollector` | Compiles onboarding (A) + behavioral (C) evidence for an adopter, PII-free, with an SHA-256 fingerprint |
| `InsightAnalyzer` | Calls provider with `adopter_insight.yml`; validates/normalizes the Adopter Insight Profile JSON |
| `PetFitAnalyzer` | Calls provider with `pet_fit_summary.yml`; validates/normalizes the Pet-Fit Summary JSON |
| `Analysis` | Orchestrator: freshness check → insight (cache) → pet-fit (per request) → persist both |

### Freshness rules
- Insight is regenerated when `signal_fingerprint` differs or `generated_at` is older than `AdopterInsight::TTL` (24h).
- Pet-fit is regenerated per request; existing `pet_fit_data` is reused only when the request's signal payload fingerprint matches (same answers + same insight fingerprint).
- The job checks freshness inside a row lock and no-ops when fresh (dedupe).

---

## Jobs

### `Ai::GenerateAdopterInsightJob`
- `perform(request_id)` → loads request, delegates to `Ai::Adopter::Analysis`.
- Enqueued from:
  - `AdoptionRequest#after_create_commit` (primary path)
  - `SavedPet#after_commit on :create` (signal refresh)
- Failure raises (ActiveJob retries with backoff); the card degrades to a fallback state without blocking the request flow.

---

## Presentation

### `AdopterInsightPresenter`
Wraps the combined data (insight + pet-fit + request). Exposes:
- `archetype_label`, `self_report_label`, `diverges?`
- `fit_indicators` → array of `{ key, label, status, status_label, evidence }`
- `commitment_signals`, `summary`, `verification_questions`
- `confidence_label`, `based_on`, `activity_up_to`
- `ready?` (data present), `loading?` (job likely still running), `empty?` (no data / failed)

### Shared partial `app/views/adoption_requests/_adopter_insight_card.html.erb`
Rendered on both `shelter/adoption_requests/show` and `my/adoption_requests/show`. Always labeled AI-generated + advisory. States:
1. Ready — full card (archetype badge, fit chips, commitment signals, pet-fit summary, verification questions, confidence/provenance footer)
2. Loading — "Preparing the adopter insight…" (non-blocking; card appears when ready)
3. Unavailable — graceful note; the existing static profile summary remains the source of truth

---

## Transparency note (Phase 1)
One benefit-framed line on `adoption_requests/new`: "Tovitu shows the shelter a summary of your profile and activity to help you find the right match."

---

## Out of Scope (this iteration)
- Phase 2: "Quick match check" micro-questions, saved-pet contextual question, latency instrumentation, feedback affordance.
- Phase 3: adopter-facing "Your match profile", consent/pause, compatibility scoring integration, post-adoption pulse.
- Completing `Ai::CompatibilityAnalyzer` (stub) — the Adopter Insight Profile is shaped so it can feed it in Phase 3 without duplication.

---

## Phase 2/3 Hookup (documented, not implemented)

The stored JSON shapes were chosen so these land without migration.

### Feedback affordance (Phase 2)
Plan §6.1.6 requires thumbs up/down on the card ("Was this insight accurate?"), aggregated without exposing raters.

- **Storage:** a `pet_fit_feedback` jsonb column on `adoption_requests` would hold `{ "accurate": true, "created_by": "<reviewer id>", "created_at": "<iso>" }`. Per-reviewer unique is guaranteed by the reviewer id + request id (no new table needed).
- **Route:** `POST /shelter/adoption_requests/:id/insight_feedback` (or the `my` equivalent) — one tap, no modal, Turbo frame swap.
- **Aggregation:** a query/service counting `accurate` ratio per prompt version (`pet_fit_version` / insight `version`) feeds the plan's success metric "shelter-reported insight accuracy ≥ 80%".

### Compatibility scoring integration (Phase 3)
Plan open question #8: the Adopter Insight Profile becomes a first-class input to per-request compatibility scoring.

- **Interface:** `Ai::CompatibilityAnalyzer.call(request:, insight:)` where `insight` is the cached `AdopterInsight.data`. It should consume `fit_indicators` (already pet-relative) + `confidence` and produce the plan's `5_ai_plan` score shape: `{ score, strengths[], concerns[], recommended_questions[] }` — reusing the pet-fit's `verification_questions` as `recommended_questions` avoids duplication.
- **No migration:** the compatibility output can be stored in a `compatibility_data` jsonb column (mirroring the `5_ai_plan` technical note) and regenerated per request alongside the pet-fit.
- **Cache rule:** the per-adopter insight cache (rule 9) already amortizes cost; compatibility stays per-request.

### Consent & control (Phase 3)
Pausing generation maps to `AdopterInsight` deletion/withdrawal; the `AdopterInsight` row is the single source of truth the card and `pet_fit_stale?` consult, so hiding insights = removing/flagging that row (already `dependent: :destroy` on the user for AC7).
