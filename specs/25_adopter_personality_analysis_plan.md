# Plan: Adopter Personality Analysis (AI-Powered Adopter Insights)

**Domain:** AI, Adoptions
**Priority:** 1 (core differentiator — strengthens matching, the heart of Tovitu)
**Status:** Draft
**Date:** 2026-08-06
**Extends:** `5_ai_plan.md` (compatibility analysis), `18_adoption_requests_integration_plan.md` (request review UX)
**Lead:** AI Agent (analysis pipeline, prompts, archetype taxonomy). Product owns this spec; Spec/Data agents own technical design.

---

## 1. Overview

### Problem

When a shelter or an individual publisher receives an adoption request, they must decide whether this person is the right home for their pet. Today they can only see:

1. **Raw, self-reported onboarding answers** (activity level, experience, personality) — a single snapshot taken at sign-up, easily stale, and self-flattering.
2. **Four free-text answers** to the request form questions.
3. **Contact basics** (name, email, member-since).

They cannot see the *richer* picture that already exists inside Tovitu: what this person actually **does** on the platform — which pets they save, how they apply, how they follow through, how quickly they respond. That behavioral evidence is more truthful than a one-time self-report, but it is invisible today.

At the same time, adopters should never feel interrogated. The onboarding is already at a good length; we must not bolt on a longer questionnaire.

### Vision

Tovitu compiles a **derived, AI-synthesized picture of each adopter** — their lifestyle, personality tendencies, commitment patterns, and how they match a given pet — from signals that cost the adopter **zero extra effort**. Shelters and individual publishers see an **insight card** (not raw data) that helps them pick the best candidate and confirm genuine fit. The adopter's experience is essentially unchanged.

### What this is NOT

- ❌ Not a longer onboarding or a new interrogation wizard.
- ❌ Not a way to leak private information (contact details, exact location, raw behavioral logs) to shelters.
- ❌ Not an automated decision-maker. The AI is advisory; the human (shelter/publisher) always decides.
- ❌ Not a "creepy tracker" — adopters are informed, insights are estimates, and control is given in Phase 3.

---

## 2. Guiding Principles

| # | Principle | Meaning |
|---|-----------|---------|
| 1 | **Zero added friction (adopter)** | No new required steps. All collection is passive or embedded in interactions the adopter is already doing. Any optional micro-question is ≤ 4 taps, skippable, and benefit-framed. |
| 2 | **Insight over raw data (shelter)** | Shelters see synthesized conclusions ("high commitment signal"), never event logs ("viewed 14 pets on Tuesday"). |
| 3 | **Privacy-preserving by design** | No PII in AI prompts (extends rule 10 of `5_ai_plan.md`). Insights are labeled as estimates with confidence. Adopters are told what the platform does with their activity. |
| 4 | **Advisory only** | AI never approves or rejects. It informs and suggests questions to verify. Final decisions stay with people. |
| 5 | **Progressive profiling** | Insight deepens as the adopter uses the platform. Sparse data → partial card, clearly labeled, never fabricated. |
| 6 | **AI-agent led, provider-agnostic** | Prompts in `config/prompts/`, analysis behind `Ai::*` service objects, async jobs, token tracking, graceful failure (all per `5_ai_plan.md` and AI_AGENT rules). |
| 7 | **Reuse before invent** | The 8 onboarding answers, the 4 request-form answers, `saved_pets`, and request timeline events already exist. Exploit them before adding any new collection. |

---

## 3. The Signal Inventory

Everything below is **what we can compile** about an adopter. The first three groups cost nothing new; the fourth adds deliberate, tiny, optional collection; the fifth is the output.

### A. Existing structured onboarding (self-reported)
| Signal | Where it lives today | What it suggests |
|--------|----------------------|------------------|
| weekend_activity (multi) | adopter profile | Lifestyle rhythm |
| activity_level (5-point) | adopter profile | Energy match with pet |
| ideal_companion (5 options) | adopter profile | What they want from a pet |
| pet_experience (4-point) | adopter profile | Skill/confidence |
| adoption_goals (multi) | adopter profile | Motivation |
| daily_time_available (4-point) | adopter profile | Time match |
| personality (5 options) | adopter profile | **Self-reported** personality (label as such — see §6.1) |
| adoption_priority (free text ≤200) | adopter profile | Values/priorities |

### B. Request-time answers (self-reported, per pet)
| Signal | Where it lives today | What it suggests |
|--------|----------------------|------------------|
| interest_reason (free text) | `adoption_request.additional_answers` | Genuine interest in THIS pet |
| home_description (free text) | `adoption_request.additional_answers` | Home/space suitability |
| current_pets_details (free text) | `adoption_request.additional_answers` | Existing household pets |
| something_else (free text) | `adoption_request.additional_answers` | Extra context |

### C. Passive behavioral signals (already persisted — currently invisible)
| Signal | Where it lives today | What it suggests |
|--------|----------------------|------------------|
| Saved pets (count, type, energy profile of saved pets) | `saved_pets` | Preferences, intent level |
| Adoption requests submitted (count, pets applied to) | `adoption_requests` | Motivation, follow-through |
| Request lifecycle behavior (withdrawn vs. followed through; statuses) | request timeline events | Reliability, genuine intent |
| Response latency (time between "needs info"/status change and adopter action) | derived from existing timestamps | Responsiveness, engagement |
| Application pattern (applies to 1 pet at a time vs. many at once) | derived from request history | Focus vs. shotgun behavior (synthesize non-judgmentally) |
| Account tenure + onboarding completion speed | user record | Engagement |

### D. Contextual micro-signals (Phase 2 — deliberate, frictionless)
| Signal | Where it would appear | What it suggests | Friction guardrail |
|--------|----------------------|------------------|-------------------|
| 3–4 single-tap yes/no questions tailored to the PET (e.g., "I have a fenced yard", "I can commit to 1+ hour of daily exercise") | Inside the existing adoption request form, as an optional "Quick match check" | Home/space/energy fit specifics | ≤ 4 questions, optional, one tap each, deduped (never asked twice), skippable entirely, never blocks submission |
| Saved-pet contextual question (optional) | At the moment of saving a pet (Phase 2 stretch) | Preference signal at peak interest moment | One optional question, dismissible, frequency-capped |

### E. Derived AI output (what the shelter/publisher sees)
See §6.1. This is the product surface: **Adopter Insight Card** + **Pet-Fit Summary**.

> **Product decision:** For MVP (Phase 1), signals A + B + C are sufficient to deliver real value with **zero** new adopter-facing UI. Phase 2 (D) exists to enrich sparse profiles, not to gate the feature.

---

## 4. Scope & Phasing

### Phase 1 — Insight from existing data (P0, must have)
- Build the AI analysis pipeline (AI agent): ingest onboarding + request answers + passive behavioral signals → produce the **Adopter Insight Profile** and **Pet-Fit Summary**.
- Surface the **Adopter Insight Card** on the request review page for **both** shelters (`shelter/adoption_requests/show`) and individual publishers (`my/adoption_requests/show`) — the page where they already decide.
- Async generation (job) on request submission; cached per adopter; refresh on new signals.
- Adopter-facing change: **zero** — only a one-line transparency mention in the request form ("Tovitu shows the shelter a summary of your profile and activity to help you find the right match").
- Insufficient-data behavior: partial card with honest "not enough activity yet" states; fallback to today's static summary when AI is unavailable.

### Phase 2 — Contextual micro-signals (P1, should have)
- Add the optional, pet-contextual **"Quick match check"** (≤ 4 single-tap questions) inside the request form (§3.D).
- Add saved-pet contextual question (optional, frequency-capped).
- Add the minimal additional instrumentation required to compute response latency where timestamps are insufficient (technical design owned by Data agent — prefer deriving from existing events).
- Re-run AI insights as the new signals arrive.

### Phase 3 — Transparency, consent & integration (P2, nice to have)
- **Adopter-facing "Your match profile"**: adopters can view the same insight summary about themselves (benefit: self-awareness, trust, and a gentle nudge to enrich it).
- **Consent & control**: pause insight generation; redact derived insights on request/account deletion.
- **Integration with compatibility scoring** (`Ai::CompatibilityAnalyzer` from `5_ai_plan.md`): the Adopter Insight Profile becomes a first-class input to per-request compatibility scores, replacing/augmenting the raw-profile-only input.
- Post-adoption pulse (one question after acceptance/meeting) feeding both insight freshness and post-adoption support.

**Out of scope (post-MVP):** cross-platform behavioral tracking; third-party data enrichment; automated accept/reject logic; insights based on private messaging content.

---

## 5. User Stories

1. As a **shelter staff member**, I want to **see an AI summary of an applicant's lifestyle, personality, and commitment signals when I review their request**, so that I can pick the best candidate faster and with more confidence.
2. As an **individual publisher**, I want to **see the same insight summary for people applying to my pet**, so that I can decide fairly even though I'm not a professional shelter.
3. As a **shelter staff member**, I want to **see how this applicant matches THIS specific pet** (energy, time, experience, home space) with strengths and concerns, so that I know what to verify before approving.
4. As a **shelter staff member**, I want **suggested verification questions** for uncertain areas, so that I can confirm fit without guessing.
5. As an **adopter**, I want the platform to **not burden me with extra questions**, so that applying to a pet stays fast and effortless.
6. As an **adopter**, I want to **know that my activity helps shelters understand what kind of home I'd provide**, so that I feel informed rather than surveilled.
7. As an **adopter** (Phase 3), I want to **see my own match profile and control whether insights are generated**, so that I stay in control of how I'm represented.
8. As a **shelter staff member**, I want to **know how confident the AI is** in each insight and **why it says so**, so that I don't over-trust it.

---

## 6. Product Requirements

### 6.1 The Adopter Insight Card (what shelters & publishers see)

A single, scannable card on the request review page. Content blocks, in order:

1. **Archetype badge** — a friendly, memorable label derived from ALL evidence, not just the self-reported `personality` field. Playful naming aligned with the brand and with the shelter-personality precedent (`Onboarding::Shelter::Personality`).
   - Example set (AI agent owns the taxonomy; must be i18n'd): "Active Outdoors Partner", "Homebody Companion", "First-Time Parent", "Experienced Guardian", "Family Builder", "Routine Keeper", "Spontaneous Spirit", "The Social House".
   - **Critical product rule:** when the evidence differs from the adopter's self-reported personality, show both, clearly labeled: "How they describe themselves: Calm and thoughtful" vs. "What their activity suggests: Active Outdoors Partner — worth confirming." Never silently override the person's self-report.
2. **Fit indicators** — per dimension, a status chip: `Strong fit` / `Possible mismatch` / `Unknown`:
   - Energy match · Time match · Experience match · Home/space match · Household compatibility (existing pets/children implied by answers).
   - Each chip carries a tooltip/expandable line with the evidence behind it ("They save high-energy dogs and applied to two others like this one").
3. **Commitment signals** — synthesized, non-judgmental observations:
   - Follow-through ("Applied to 1 pet in 3 weeks and followed the request to completion" vs. "Applied to 6 pets in one week — worth confirming genuine interest in this one").
   - Responsiveness ("Responded to the follow-up request within ~2 hours").
   - Account tenure/engagement level.
4. **Pet-Fit Summary** (per-request) — 2–4 sentences: why this person looks like a good (or risky) match for THIS pet, plus **2–3 suggested verification questions** for the shelter to ask (reuses the `recommended_questions` concept from `5_ai_plan.md`).
5. **Confidence & provenance footer** — overall confidence (High/Medium/Low), what data the insight is based on ("Based on: onboarding answers, 3 saved pets, 1 request, follow-up response time"), and the AI disclaimer per `5_ai_plan.md` rule 9.
6. **Feedback affordance (Phase 2)** — thumbs up/down on the card ("Was this insight accurate?") to measure quality and improve prompts. Lightweight, no modal.

Design note: follows DESIGN.md — bento card, bold colors, WCAG AA. It is an *enhancement* to the existing review page, not a new page.

### 6.2 Frictionless micro-signals (Phase 2)

**"Quick match check"** inside the existing adoption request form:

- Rendered as a small, optional, collapsible section titled with benefit framing: "Quick match check — helps the shelter see you're a great fit" (i18n, en/es).
- Questions are **single-tap yes/no**, **≤ 4 per request**, **all optional**, **skippable**, and **never block submission**.
- Questions are **pet-contextual**: selected from a product-owned library based on the pet's attributes (e.g., energy, size, yard needs, children/family, other pets). Examples:
  - "I have a fenced yard" — Yes / No
  - "I can commit to 1+ hours of daily exercise" — Yes / Usually / No
  - "There is someone home during the day" — Yes / No
  - "I'm open to a pet with special needs" — Yes / No
- **Dedupe:** a question is never shown twice to the same adopter (progressive profiling; answers accumulate into the adopter's evidence base).
- Copy guardrails: questions must feel like "help me match you better", never like a test or a background check. No question may imply judgment ("Are you sure you have time?" is banned).

**Saved-pet moment (stretch):** one optional single-tap question when saving a pet, frequency-capped (e.g., once per week max), dismissible.

### 6.3 Behavioral instrumentation

- **Phase 1: derive, don't track.** Saved pets, request lifecycle, and response latency are computed from existing persisted data. No new adopter-facing tracking.
- **Phase 2:** only add a minimal signal store where existing data has gaps (e.g., latency windows), owned technically by Data/Spec agents. Aggregation only — never raw event streams surfaced to shelters.
- Privacy weight is tracked per signal (see §8, Business Rules) so we can show adopters exactly what's used.

### 6.4 Adopter transparency (Phase 1 minimal + Phase 3 full)

- **Phase 1:** one short, benefit-framed line in the request form and in the onboarding completion message: "Tovitu shows shelters a summary of your profile and activity to help you find the right match." Nothing else changes for adopters.
- **Phase 3:** adopters can view their own insight summary and pause generation. Pausing stops new analysis and hides insights from shelters for new requests (existing cached insights are also withdrawn within 24h).

---

## 7. Acceptance Criteria

### AC1: Adopter Insight Card on request review (Phase 1)
```
Given I am a shelter staff member viewing an adoption request (pending or in_validation)
When the page loads
Then I see an "Adopter Insight" card in the adopter section
And the card shows an archetype badge, fit indicators, commitment signals,
    a pet-fit summary, suggested verification questions, and a confidence/provenance footer
And the card is labeled as AI-generated and advisory
And no PII beyond what is already shown today is exposed (no raw event logs, no extra contact info)

Given I am an individual publisher viewing a request for my pet
Then I see the same Adopter Insight card (shared component/partial)
```

### AC2: Zero new adopter friction (Phase 1)
```
Given an adopter submits a request
Then they encounter no new required fields, no new steps, and no new pages
And they see only a one-line transparency note
And the request submission completion rate does not regress vs. baseline
```

### AC3: Insight generation pipeline (Phase 1)
```
Given a new adoption request is submitted
When the request is created
Then a background job generates the Adopter Insight Profile (if not fresh) and the Pet-Fit Summary asynchronously
And the card appears when ready (progressive load, no blocking)
And generation failure does not block the request or the review page (fallback to today's static summary)

Given a signal changes (new saved pet, new request, onboarding completed)
When the insight is stale or older than the refresh threshold
Then it is regenerated asynchronously (deduped, no duplicate jobs)
```

### AC4: Insufficient data honesty
```
Given an adopter has very few signals (e.g., just completed onboarding, no activity)
Then the card shows only what is supported by evidence
And low-confidence sections display "Not enough activity yet" instead of fabricated conclusions
And overall confidence is labeled Low
And no AI claim is made about areas with no evidence
```

### AC5: Self-report vs. behavior handled correctly
```
Given the AI-derived archetype differs from the adopter's self-reported personality
Then the card shows both, labeled "How they describe themselves" and "What their activity suggests"
And it is phrased as "worth confirming", never as a contradiction or accusation
```

### AC6: Optional micro-questions (Phase 2)
```
Given an adopter is filling the adoption request form
When the pet has attributes that trigger the Quick match check
Then up to 4 single-tap optional questions appear in a collapsible, benefit-framed section
And each question can be skipped individually or the whole section dismissed
And submission is possible with 0 answers
And no question is ever shown twice to the same adopter

Given an adopter has answered some micro-questions
When they are used in analysis
Then they are labeled as evidence in the provenance footer
```

### AC7: Privacy & consent (Phase 2/3)
```
Given an adopter pauses insight generation (Phase 3)
Then no new insights are generated
And insights for existing requests are withdrawn within 24 hours
And no AI prompt ever contains the adopter's name, email, phone, or exact address (asserted by test)

Given an adopter account is deleted
Then derived insights are deleted/redacted
```

### AC8: AI quality feedback (Phase 2)
```
Given a shelter sees an Adopter Insight card
Then they can rate the insight as accurate/not accurate (one tap, no modal)
And ratings are aggregated as a quality metric without exposing individual raters
```

---

## 8. Edge Cases & Error States

| Edge case | Handling |
|-----------|----------|
| Adopter is brand new, no behavior | Partial card, Low confidence, "not enough activity yet" states, fallback to static onboarding summary |
| AI provider down / times out | Retry with backoff (per `5_ai_plan.md`); card falls back to today's static summary; request flow never blocked |
| AI output malformed | Validate response shape; retry; on persistent failure show fallback + log for review |
| Prompt injection via free-text answers | Treat adopter text strictly as data, never instructions; sanitize before prompt build (extends `5_ai_plan.md` open question 3) |
| Behavioral contradiction (self-reports calm, saves high-energy dogs) | Surface as "worth confirming" with evidence, both labels shown (AC5) |
| Adopter applies to many pets at once | Synthesize non-judgmentally ("applied to several pets — confirm genuine interest in this one"); never shame or expose counts as raw numbers unless helpful |
| Withdrawn requests | Weighted down / excluded from commitment signals; flagged only if pattern is extreme |
| Data sparsity at MVP scale | Insights clearly labeled as estimates; quality improves as signals accumulate; feedback loop (AC8) drives prompt tuning |
| Bias risk (breed/age/gender/name bias in analysis) | Fairness guidelines in system prompt; exclude demographics from analysis inputs; review prompt against bias (extends `5_ai_plan.md` open question 4) |
| Insights stale after long inactivity | TTL refresh + "based on activity up to [date]" in provenance; re-run on next significant signal |
| Adopter deletes/pauses | Withdraw insights per AC7 within 24h |
| Cost at scale | Per-analysis budget + token tracking (per `5_ai_plan.md` rule 11); insights cached per adopter so one analysis serves many requests |
| Localization | All card labels, archetypes, micro-questions, and disclaimers in `config/locales/*.yml` (en/es); prompts reference locale-neutral keys |
| Two shelters view same adopter concurrently | Cached adopter insight is shared (read-only); pet-fit summary is per-request |

---

## 9. Business Rules (product-level)

1. **Insight ≠ raw data.** Shelters see only AI-synthesized conclusions with evidence summaries — never raw behavioral event streams or logs.
2. **No PII in analysis.** The AI prompt never receives name, email, phone, or exact address. Only non-identifying attributes and aggregated behavioral features.
3. **Advisory only.** AI never approves/rejects. Decisions remain with the shelter/publisher. Card carries the standard AI disclaimer.
4. **Honesty over completeness.** When evidence is insufficient, show less — never fabricate. Confidence labels are mandatory on every card.
5. **Self-report precedence.** The adopter's own answers are always shown alongside (never hidden by) AI-derived conclusions when they conflict.
6. **Transparency.** Adopters are informed that activity informs matching (Phase 1 note; Phase 3 full view + control).
7. **Friction caps (Phase 2).** ≤ 4 micro-questions per request, single-tap, optional, deduped per adopter, never required.
8. **Weighting sanity.** Passive signals (C) and optional answers (D) are always optional-by-nature inputs — no signal may be treated as a hard gate or used to auto-reject.
9. **Cache & refresh.** Adopter insight is cached per adopter (not per request) and refreshed asynchronously on signal change or TTL; pet-fit summary is per-request.
10. **Reuse before invent.** New collection (D) is only added where A/B/C leave meaningful gaps.

---

## 10. Success Metrics

| Metric | Target |
|--------|--------|
| Adopter request submission completion rate (friction check) | No regression vs. baseline (Phase 1 gate) |
| Insight card visibility rate (% of request reviews where the card is viewed/expanded) | > 60% |
| Shelter-reported insight accuracy (via card feedback) | ≥ 80% "accurate" |
| Shelter time-to-decision on a request | −20% vs. baseline |
| Shelter confidence in decisions (periodic survey) | ≥ 4/5 |
| AI analysis success rate | > 98% (fallback rate < 2%) |
| Cost per analysis | < $0.05 (cached per adopter to amortize) |
| Adoption requests → accepted for profiles rated "strong fit" vs. "possible mismatch" | Strong-fit conversions measurably higher (validates signal value) |
| Adopter opt-out rate (Phase 3) | < 5% (validates trust/UX) |
| Long-term: post-adoption returns/re-homing | Decreasing trend (lagging indicator) |

---

## 11. Dependencies / Prerequisites

- `5_ai_plan.md` foundations: `Ai::Provider`, async jobs, prompt versioning, token tracking (partially built — `Ai::Provider` and `config/prompts/` exist; `CompatibilityAnalyzer` is a stub to be completed in this feature).
- Adoption request review pages for both shelters and individual publishers (exist).
- Adopter profile + onboarding data (exist).
- `saved_pets` and request timeline events (exist).
- **Note for AI Agent:** current `Ai::Provider` points at OpenAI while AGENTS.md/5_ai_plan state Anthropic. Resolve provider direction before building (keep provider-agnostic interface regardless).
- i18n (en/es) for all new user-facing strings.
- Sidekiq/Redis for async generation (in planned stack).

---

## 12. Open Questions / Handoff to AI Agent

The AI Agent owns these decisions (product requirements above constrain them):

1. **Archetype taxonomy** — final archetype set, naming, and the evidence → archetype mapping rules. Must be playful, i18n-friendly, and empirically grounded (not just re-stated Q7 personality).
2. **Signal weighting** — how much each signal group (A/B/C/D) contributes; how contradictions are resolved; how "possible mismatch" vs. "unknown" is decided.
3. **Prompt architecture** — one prompt for the Adopter Insight Profile + one for the Pet-Fit Summary (or a combined structured-output prompt); JSON output schema (archetype, fit indicators, commitment signals, pet-fit summary, verification questions, confidence).
4. **Fairness guardrails** — explicit exclusions (no demographics), anti-bias guidelines, and a review checklist for prompt changes.
5. **Refresh thresholds** — TTL, minimum signal delta to trigger regeneration, dedupe/locking rules for concurrent jobs.
6. **Insufficient-data thresholds** — minimum evidence level before each section renders vs. shows "not enough activity yet".
7. **Provider decision** — OpenAI vs. Anthropic resolution (flagged above), while keeping `Ai::BaseProvider`-style abstraction.
8. **Interaction with `CompatibilityAnalyzer`** — exact interface so the Adopter Insight Profile can feed per-request compatibility scoring in Phase 3 without duplication.

**Handoff to Spec/Data agents:** technical design for the (minimal) Phase 2 signal instrumentation, the cached insight storage, and job orchestration — constrained by the business rules above.

---

## 13. Relationship to Existing Plans

| Existing plan | Relationship |
|---------------|--------------|
| `5_ai_plan.md` | ➕ **Extended.** Adds adopter-side personality analysis as the input layer to compatibility analysis; reuses provider/prompt/job/async conventions and AI rules. |
| `7_auth_and_onboarding_plan.md` | 🔗 **Consumes.** Uses the 8 onboarding answers (esp. `personality`) as self-reported evidence; adds the Phase 1 transparency note to onboarding copy. |
| `18_adoption_requests_integration_plan.md` | 🔗 **Enhances.** Surfaces the Insight Card on both request review pages; adds the optional Quick match check to the request form. |
| `17_individual_publishing_plan.md` | 🔗 **Enhances.** Individual publishers get the same insight card (fairness: non-professional publishers need it most). |
| `14_dashboard_views_plan.md` | 🔗 **Optional future surface.** Compact insight could appear in request list views later. |
| `16_design_unification_plan.md` | 🔗 **Constrains.** Card follows DESIGN.md / Playground Standard. |

---

## 14. Rejected Alternatives

| Alternative | Why rejected |
|-------------|--------------|
| Longer onboarding questionnaire (10–15 questions) | Directly contradicts the friction goal and the 7/8-question <2min design principle. Signals must come from context and behavior, not interrogation. |
| Raw behavior feeds for shelters (show every saved pet / view / event) | Privacy-hostile and overwhelming. Shelters need synthesized insight, not logs; raw feeds would erode adopter trust and violate the "insight over raw data" principle. |
| Standalone "Adopter Insights" page requiring navigation | Adds a click to the decision path. The card belongs exactly where the decision happens (request review). |
| Onboarding the AI as a chatbot asking adopters questions | Novel but high-friction, high-cost, and risks feeling like surveillance; out of scope for MVP. Contextual single-tap questions achieve similar richness with far less burden. |
| Third-party personality tests (Big Five quiz, etc.) | External dependency, license/cost, and heavy UX. The platform already has rich first-party evidence. |
| Show AI analysis only to shelters, not individual publishers | Unfair: individual publishers have the least screening experience and need the most help. Both review surfaces get the card. |
| Auto-approve/reject based on insight score | Violates the advisory principle and creates legal/ethical risk. AI informs; humans decide. |
