# Plan: Adoption Policy Auto-Evaluation — Advisory Request Screening with Natural-Language Shelter Policies

**Domain:** Adoptions, AI, Shelter Tools
**Priority:** 1 (High) — reduces shelter time-to-decision and flags risky applicants before humans review
**Status:** Draft
**Tracks:** Epic "Adoption Request Intelligence" (Story 1 — Policy Evaluation)

---

## Overview

Shelters today review every adoption request by hand. They must open each request, read the adopter's profile, mentally compare it against their policies, and decide. High-volume shelters and low-signal requests (brand-new accounts, sparse profiles) make this slow and error-prone. Meanwhile, shelters express their requirements as **natural-language policies** ("Applicants must have a fenced yard", "We prefer adopters with previous pet experience"), which today are displayed to adopters but never screened against.

This plan adds an **automatic evaluation layer** that runs when an adoption request is received — "antifraud middleware" for adoptions. It evaluates the adopter's profile against a combination of:

1. **System rules** (platform-owned, e.g. account younger than 3 days; unverified email; profile below a completeness threshold), and
2. **Shelter rules** derived from the shelter's own natural-language policies (e.g. "we prefer experienced adopters" → `pet_experience` rule).

Each request receives a verdict with three levels, shown as a red/yellow/green badge:

- **Red — High concern:** at least one high-severity rule failed (e.g. account too new, unverified email). Strongly suggests the shelter should decline, but the shelter decides.
- **Yellow — Needs review:** at least one warning-severity rule failed, or a rule could not be verified because data was missing.
- **Green — Pre-accept:** all evaluated rules passed. A recommendation to approve — **never** an acceptance.

**The verdicts are advisory only. The final decision is always made by the shelter.** No request is ever automatically accepted, declined, or changed status by the evaluation. The evaluation is decision support: it tells the shelter *what to look at* and *why*, and the shelter makes the call with the existing accept/decline/validate actions.

To make more policies evaluable, this plan also adds **three structured adopter data points** collected during onboarding — **date of birth** (age rules), **home environment** (fenced-yard rules), and **other pets** (household rules). Policies that reference anything still not supported are honestly marked "not auto-evaluated" and never silently affect a verdict.

The natural-language-to-rules translation is done by an AI service at **policy-save time** (not per request), so request-time evaluation is deterministic, fast, and cheap — no LLM call in the submission path.

---

## Current State (confirmed in code)

- **Adoption requests** are created via `Adoptions::SubmitRequest` with status `pending`, then reviewed manually by the responsible party. Statuses: `pending`, `in_validation`, `accepted`, `declined`, `withdrawn`. Valid transitions are enforced in `Adoptions::ProcessRequest::VALID_TRANSITIONS`. Review decisions (validate/accept/decline) are already fully human-driven.
- **Shelter policies** are stored on `Shelter#adoption_policies` (jsonb) as a **fixed set of keys** (`adoption_fee`, `minimum_age`, `fee_description`, `home_visit_required`, `fenced_yard_required`, `vet_reference_required`, `other_requirements`). They are presentation-only today: shown to adopters, never evaluated. There is no multi-policy CRUD and no natural-language policy field.
- **Request review UI** is `shelter/adoption_requests/show.html.erb` (pet card, adopter card, shared adopter-insight card, answers card, timeline card, decision actions). The shared partial `adoption_requests/_adopter_insight_card.html.erb` is also rendered on `my/adoption_requests/show` (individual publisher flow).
- **Adopter signals available today** (confirmed):
  - `User#created_at` (account age), `User#verified_at` (email verified), `User#onboarding_completed_at`.
  - `IndividualProfile` (table `individual_profiles`, 8 onboarding questions): `weekend_activity` (multi), `activity_level`, `ideal_companion`, `pet_experience` (`first_time` → `very_experienced`), `adoption_goals` (multi), `daily_time_available` (`less_than_1h` → `more_than_4h`), `personality`, `adoption_priority` (text).
  - `AdoptionRequest#additional_answers` (free-text answers at request time).
  - **No structured data exists** for adopter age/DOB, home environment (fenced yard), or other pets — this plan adds them (REQ-49-13).
- **Onboarding** is the adopter questionnaire (`Onboarding::Individual::QuestionsData`, 8 questions) required to apply. This is the natural home for the new structured fields.
- **AI conventions:** vendor-agnostic `Ai::*` services, prompts in `config/prompts/*.yml`, JSON validation/normalization after provider calls, and a strict honesty rule ("never fabricate; use `unknown` when evidence is missing") established in plan 25.
- **Design system:** semantic tokens `success` `#00C9A7`, `warning` `#F59E0B`, `danger` `#EF4444`, `info` `#3B82F6`; badge conventions require a text label in addition to color (color is never the only indicator); WCAG AA; i18n en/es per plan 33.
- **Notifications:** `Notifications::Deliver` + timeline events already exist for status changes.

---

## User Stories

> As a shelter staff member,
> I want incoming adoption requests to be automatically checked against my shelter's policies and Tovitu's safety rules,
> so that I can focus my attention on the requests that actually need a human decision.

> As a shelter staff member,
> I want to see a clear red/yellow/green verdict with the specific rules that passed or failed,
> so that I can understand at a glance why a request was flagged or pre-accepted — and still make the final call myself.

> As a shelter owner,
> I want to write my adoption policies in plain language and have them translated into evaluable rules I can review,
> so that my screening reflects what I actually require without me writing technical rule code.

> As an adopter,
> I want my profile to reflect the things shelters care about (age, home, other pets),
> so that good-fit requests aren't flagged just because shelters couldn't verify me.

---

## Requirements & Proposed Behavior

### REQ-49-1 — Automatic evaluation on request receipt

When an adoption request is created (`Adoptions::SubmitRequest` success path), an **evaluation job is enqueued** and runs asynchronously. The job:

- Collects the adopter's current signals (account age, email verification, profile completeness, profile answers, request answers, relevant history).
- Evaluates **system rules** (always) and **shelter rules** (when the request targets a shelter; enabled rules only).
- Produces a **verdict** and a **per-rule result set** (rule, severity, passed/failed, evidence, source).
- Persists the evaluation snapshot on the request (REQ-49-7).

Evaluation is deterministic (structured rules over stored data) — no AI provider call happens in the request path. The job must never block request creation or the adopter's confirmation screen.

### REQ-49-2 — Verdict semantics (advisory; the shelter always decides)

| Verdict | Badge | Status effect | Meaning |
|---------|-------|---------------|---------|
| **High concern** (red) | Red (`danger`) | **None — request stays `pending`** | At least one **high-severity (reject)** rule failed. Strongly suggests declining. |
| **Needs review** (yellow) | Yellow (`warning`) | **None — request stays `pending`** | At least one **warning-severity** rule failed, or a rule could not be evaluated due to missing data. |
| **Pre-accept** (green) | Green (`success`) | **None — request stays `pending`** | At least one rule was evaluated and **all** evaluated rules passed. A recommendation to approve — **not** an acceptance. |

**Non-negotiable product rule: the evaluation never changes request status and never sends a decision to the adopter.** It is decision support for the responsible party. Accepting, declining, and validating remain exclusively human actions through the existing decision flow. If the shelter disagrees with a red verdict, they can accept anyway — the evaluation is advisory.

### REQ-49-3 — System rules (platform-owned)

System rules are defined centrally by the platform, always evaluated, and **not editable by shelters** (shelters see them in the evaluation breakdown but cannot change thresholds or severity). Initial system rules (defaults; central tuning only):

| Rule | Signal | Default severity |
|------|--------|------------------|
| Account is too new | `User#created_at` | Account younger than **3 days** → **red (high concern)** |
| Email not verified | `User#verified_at` | Unverified email → **red (high concern)** |
| Adopter is a minor | `IndividualProfile#date_of_birth` (new) | Under **18** → **red (high concern)** |
| Profile is incomplete | Answered onboarding questions / total | Below **60%** completeness → **yellow** |
| History of declined/withdrawn requests on this pet's publisher | `AdoptionRequest` history | Prior declined/withdrawn request for the **same pet** → **yellow** |

Defaults are documented here as the initial platform baseline; the exact thresholds live in one central place (config) and can be tuned by the platform team. Future system rules (e.g. duplicate-account signals) are out of scope.

### REQ-49-4 — Natural-language policies → structured rules (AI translation at save time)

Shelters author adoption policies in **natural language** in shelter settings (new "Automatic evaluation" area under Adoption Policies, REQ-49-11). When policies are saved:

1. The system asks an AI service (vendor-agnostic `Ai::*`, prompt in `config/prompts/`) to translate each natural-language statement into **structured rules** from the evaluable vocabulary (REQ-49-5), each with a suggested severity (`red` high concern or `yellow` warning).
2. The translation is **proposed, not silently applied**: the shelter reviews each translated rule, can edit parameters/severity, enable/disable it, or discard it. Untranslatable statements are labeled "not auto-evaluated" (REQ-49-5) and remain as display-only policies for adopters.
3. Only **enabled, reviewed** rules participate in request-time evaluation.

Translation happens at policy-save time only — never per request. The translation service must validate and normalize the AI output into the bounded rule vocabulary (mirroring the plan 25 `InsightAnalyzer` pattern), and fail gracefully (keep the raw policy text, mark it not-evaluated, surface a retry) rather than block policy saving.

### REQ-49-5 — Evaluable rule vocabulary + honest "not auto-evaluated" state

The evaluator supports a **bounded vocabulary of rule types**, each mapping to a real stored signal:

| Rule type | Signal | Example NL policy |
|-----------|--------|-------------------|
| `account_age_min` (days) | `User#created_at` | "Only accept applications from accounts at least a week old" |
| `email_verified` (bool) | `User#verified_at` | "Applicants must have a verified email" |
| `adopter_age_min` (years) | `IndividualProfile#date_of_birth` (new) | "Applicants must be at least 21 years old" |
| `home_fenced_yard_required` (bool) | `IndividualProfile#home_environment` (new) | "We require a fenced yard" |
| `other_pets_allowed` (bool) | `IndividualProfile#other_pets` (new) | "We prefer homes without other pets" |
| `profile_completeness_min` (%) | answered onboarding questions | "Applicants should have a complete profile" |
| `pet_experience_min` (level) | `IndividualProfile#pet_experience` | "We prefer adopters with previous pet experience" |
| `daily_time_available_min` (level) | `IndividualProfile#daily_time_available` | "Adopters need at least 2 hours a day for a dog" |
| `adoption_priority_present` (bool) | `IndividualProfile#adoption_priority` | "We want to know why you want to adopt" |
| `additional_answers_present` (bool) | `AdoptionRequest#additional_answers` | "Tell us about your home when applying" |
| `no_prior_decline_same_pet` (bool) | request history | "Don't consider repeat requests after a decline" |

**Honesty rule (non-negotiable):** any natural-language policy that cannot be mapped to a supported rule type — or references data we still don't have (e.g. "no small children in the home") — is marked **"not auto-evaluated"**. It stays visible to adopters as a policy, is shown to the shelter in the evaluation settings with an explanation ("we can't check this automatically yet"), and **never** silently affects a verdict. The system never fabricates evidence or infers from missing data (plan 25 principle).

### REQ-49-6 — Verdict aggregation

- **Red (High concern)** if any enabled high-severity (reject) rule fails.
- Else **Yellow (Needs review)** if any enabled warning-severity rule fails, **or** if any enabled rule could not be evaluated because required data is missing (conservative: "couldn't verify" → yellow, with evidence stating what was missing).
- Else **Green (Pre-accept)** if at least one rule was evaluated and all passed.
- **No configured rules** (shelter has no enabled rules and system rules are the only source, or a publisher with no shelter policies): the system rules still evaluate. If a request has **no evaluation at all** (e.g. feature disabled for a publisher context), the section shows a neutral localized empty state — never an error.
- Rule results are ordered: failed high-severity rules first, then failed warning rules, then passed rules.

### REQ-49-7 — Evaluation snapshot per request

The full evaluation outcome is captured **at evaluation time** on the request (a snapshot, not live recomputation — consistent with the adopter-insight snapshot approach). The snapshot records: verdict, overall summary text, per-rule results (rule type, label key, severity, source `system`/`shelter`, passed/failed, evidence text, human-readable translated policy statement when shelter-owned), evaluated-at timestamp, and a version stamp. Evidence is assembled from real stored values (e.g. "Account created 2 days ago", "Profile 50% complete (4 of 8 questions answered)", "Date of birth indicates 19 years old") and is localized where user-facing.

### REQ-49-8 — Request detail: evaluation section with badge + summary (shelter)

On `shelter/adoption_requests/show`, a new **"Policy check"** section renders the evaluation:

- **Badge** matching the verdict: red (`danger`), yellow (`warning`), green (`success`) — always with a text label ("High concern", "Needs review", "Pre-accepted"), never color-only (accessibility rule).
- **Summary line** — one or two localized sentences explaining the verdict.
- **Rule-by-rule breakdown** — each evaluated rule shows: label, severity chip, pass/fail state, evidence, and source (System / Shelter). Failed rules are visually distinct and listed first.
- **Advisory framing** — the section and its actions must not imply a decision was made: copy stays in recommendation language ("We recommend reviewing…", "This request passed the policy check — it's ready for your decision."). The existing accept/validate/decline actions remain primary and unchanged.
- **Contextual actions:** "Re-run evaluation" (REQ-49-14) and a link to the shelter's "Automatic evaluation" settings.
- **States:** ready (verdict present), evaluating (job in flight — non-blocking, matches the adopter-insight card loading pattern), no evaluation configured (neutral empty state). The section is a shared partial so the individual publisher flow reuses it (REQ-49-9).

### REQ-49-9 — Individual publisher view (system rules only)

Individual publishers (`my/adoption_requests/show`) receive the same **Policy check** section via the shared partial, evaluating **system rules only** (they have no shelter policies to configure). Same badge, summary, and breakdown. No publisher-facing policy settings in this plan.

### REQ-49-10 — Request list evaluation chip (triage)

The shelter's adoption request **list** (`shelter/adoption_requests/index`) shows a small evaluation chip next to each request's status badge: red / yellow / green dot + verdict label, so staff can triage the queue at a glance. Chip is advisory only; it never replaces the status badge. Filters/sorting by verdict are out of scope for this iteration (possible follow-up).

### REQ-49-11 — Shelter settings: "Automatic evaluation" management

Under the existing Adoption Policies area, a new **"Automatic evaluation"** management surface:

- **Natural-language policy input:** shelters write/keep their policies in plain language (existing `other_requirements`-style free text and any new statements).
- **Translation review list:** after saving, each policy shows its proposed translated rule(s) with: rule type label, parameters, suggested severity, an enable/disable toggle, and edit/delete controls. Shelters approve or adjust before rules become active.
- **"Not auto-evaluated" list:** untranslatable policies are listed separately with an explanation and remain display-only.
- **System rules visibility:** read-only list of system rules and their current defaults.
- Empty state: no policies yet → clear copy + "Add a policy" CTA; no translations yet → "Translate my policies" CTA.
- This is a **shelter-owner/administrator** capability (REQ-49-15).

### REQ-49-12 — Notifications & adopter transparency

- **The evaluation itself never notifies the adopter.** If the shelter declines after reviewing, the existing decline flow (with reasons) applies unchanged.
- **Shelter:** when a request arrives, the existing "new request" notification is sent as today. The evaluation is visible on the detail page and via the list chip; no new notification kinds are introduced in this plan (a "high-concern request arrived" notification is a possible follow-up).
- **Adopter transparency:** the adopter **never** sees the internal rule-by-rule evaluation breakdown — the evaluation section is responsible-party-only (REQ-49-15). Adopters do see the new structured profile questions and can review/edit them (REQ-49-13), which keeps the data the screening relies on under their control.

### REQ-49-13 — New structured adopter data (unlocks age, fenced-yard, and other-pet rules)

Three structured questions are added to the adopter onboarding questionnaire (extending `Onboarding::Individual::QuestionsData`), stored on `IndividualProfile`:

1. **Date of birth** (date) — used to compute age for `adopter_age_min` rules and the under-18 system rule. Precise DOB (not an age band) so minimum-age policies evaluate correctly. This is personal data: handled per existing privacy conventions, editable in profile settings, never shown raw to shelters (only derived age).
2. **Home environment** (single-select) — options: house with fenced yard / house without fenced yard / apartment or condo / other. Supports `home_fenced_yard_required`.
3. **Other pets** (single or multi-select) — options: no other pets / dog(s) / cat(s) / other animals. Supports `other_pets_allowed`.

Behavior rules:

- **New adopters:** the three questions are part of the onboarding questionnaire they must complete to apply (consistent with the existing 8 questions).
- **Existing adopters** (who completed onboarding before this feature): they are **not** retroactively blocked from applying. Until they answer, rules referencing these fields hit the honest "couldn't verify" path (→ yellow, with evidence naming the missing data). A gentle, non-blocking prompt to complete the new profile fields appears in profile settings and (at most once) near the request flow — never nagging (plan 48 principle).
- Shelters see only derived values where privacy matters: age (e.g. "25 years old"), home-environment label, and other-pets label — never a raw DOB.

### REQ-49-14 — Re-run evaluation

Shelter staff can re-run the evaluation for a request (e.g. after the adopter updates their profile or answers more questions). Re-running recomputes against the **current** adopter signals and replaces the snapshot. Because verdicts are advisory, re-running never changes status. Re-run is a shelter/publisher staff action, not adopter-facing.

### REQ-49-15 — Authorization

- **Viewing the evaluation section:** only the responsible party — shelter members of the request's shelter, or the individual publisher — per the existing `AdoptionRequestPolicy#show?` scope. Adopters never see the breakdown.
- **Managing evaluation policies** (settings, translation review, toggles): shelter owner/administrator only (consistent with plan 42/46 policy-management permissions).
- **Re-run:** shelter members authorized for the request (per `manage?` scope).
- All enforced via Pundit; no auth checks in views.

### REQ-49-16 — Localization & accessibility

- All new user-facing strings (section title, badge labels, summaries, rule labels/evidence, settings copy, empty states, onboarding questions and options) are localized en/es via `config/locales/*.yml`. No hardcoded strings.
- Natural-language policies are **user-authored content** and are not translated by the platform; they render as-is (with a locale-neutral "Policy" label).
- Rule labels/descriptions use stable locale keys (rule type → label), mirroring the archetype/taxonomy pattern from plan 25.
- Badges include a text label in addition to color (WCAG). Contrast meets AA. Reduced-motion respected.

---

## Acceptance Criteria

- **AC-49-1** — An incoming adoption request is evaluated automatically (system rules + enabled shelter rules) without blocking request creation; the adopter's confirmation is unaffected.
- **AC-49-2** — **No evaluation verdict ever changes request status or notifies the adopter of a decision.** Red, yellow, and green verdicts all leave the request `pending`; only the shelter's own accept/validate/decline actions change status.
- **AC-49-3** — A failed high-severity (reject) rule produces a red "High concern" verdict; the request stays `pending` and the shelter can still accept it if they disagree.
- **AC-49-4** — A failed warning-severity rule (or an unevaluable rule due to missing data) produces a yellow "Needs review" verdict.
- **AC-49-5** — All-evaluated-rules-pass produces a green "Pre-accept" verdict — a recommendation, never an acceptance.
- **AC-49-6** — The evaluation snapshot records verdict, summary, per-rule results (rule, severity, source, passed/failed, evidence), timestamp, and version; it is a snapshot of the signals at evaluation time.
- **AC-49-7** — Shelter policies authored in natural language are translated into proposed structured rules from the bounded vocabulary; the shelter reviews/edits/enables them before they affect evaluation.
- **AC-49-8** — Natural-language policies that cannot be mapped to an evaluable rule (or reference unavailable data) are labeled "not auto-evaluated", remain visible to adopters, and never affect a verdict.
- **AC-49-9** — The request detail page shows a "Policy check" section with a red/yellow/green badge (always with a text label), a summary, and a rule-by-rule breakdown with evidence; the copy is advisory, never decision-like.
- **AC-49-10** — Individual publishers see the same section with system rules only.
- **AC-49-11** — The shelter request list shows an evaluation chip per request.
- **AC-49-12** — Adopters never see the internal rule breakdown; the evaluation itself never sends them a notification.
- **AC-49-13** — New adopters answer the three new onboarding questions (date of birth, home environment, other pets) as part of completing onboarding; existing adopters are not blocked and see a gentle, non-blocking prompt to complete them.
- **AC-49-14** — Rules referencing the new fields evaluate correctly (age, fenced yard, other pets); missing data on those fields produces an honest "couldn't verify" yellow result.
- **AC-49-15** — Pundit enforces: evaluation visible only to responsible parties; policy management owner/administrator-only; re-run restricted to authorized shelter members.
- **AC-49-16** — All new strings are localized en/es; badges are never color-only; WCAG AA holds.
- **AC-49-17** — Existing request flows (submit, review, accept, decline, withdraw, notifications, timeline) continue to pass without regression.

---

## Success Metrics

- **Time-to-first-action:** average time from request submission to shelter's first action (review/accept/decline) decreases (baseline from request timestamps; target ≥ 20% reduction) — screening helps staff triage.
- **Red-verdict agreement:** of requests with a red "High concern" verdict, the share the shelter ultimately declines (target: measure; expect high, e.g. ≥ 60% — validates that red flags align with human judgment; low agreement means rules are too aggressive).
- **Warn engagement:** % of yellow verdicts where the shelter still reviews the request within 48h (target ≥ 90%) — warnings must inform, not bury.
- **Pre-accept conversion:** % of green pre-accepted requests that the shelter accepts (target ≥ 50%) — validates that green means genuinely good.
- **Translation usefulness:** % of shelter natural-language policies successfully translated into evaluable rules (target ≥ 60% for first pass; the rest honestly "not auto-evaluated").
- **New-signal coverage:** % of new adopters who complete the three new onboarding fields (target ≥ 85%); % of existing adopters who fill them within 60 days (target ≥ 50%).
- **Adopter fairness (guardrail):** no sustained increase in declined adopters who reapply — red flags should reduce wasted applications, not discourage good adopters.

---

## Test Strategy

- **Service specs:** `Adoptions::EvaluateRequest` (verdict aggregation, rule evaluation, missing-data → yellow, snapshot persistence, **assert verdicts never mutate status**); translation service (happy path, unparseable policy → not-evaluated, provider failure → graceful).
- **Request specs:** evaluation enqueued on submit; red/yellow/green verdicts rendered on shelter and publisher detail pages; **status never changes as a result of evaluation** (assert `pending` after evaluation in all three verdict cases); re-run; adopters cannot access the breakdown (Pundit).
- **Policy settings specs:** save NL policies → translation proposed → review/edit/enable; not-evaluated list; owner/administrator authorization.
- **Onboarding specs:** new questions save correctly; new adopters can't complete onboarding without them; existing adopters without the fields are not blocked; profile settings edit path.
- **Negative tests:** provider failure during translation never blocks saving; missing adopter data → yellow with honest evidence; no rules configured → neutral empty state; under-18 adopter → red system rule.
- **Regression:** existing submit/review/accept/decline/withdraw/notification/onboarding specs continue to pass.
- **Manual QA matrix:** red/yellow/green verdicts × shelter/publisher surfaces × en/es × mobile/desktop; badge contrast + non-color indicator.

---

## Scope

**In scope:** automatic evaluation on request receipt (system rules + shelter rules); advisory red/yellow/green verdicts that never change status; natural-language → structured-rule translation at policy-save time (AI, vendor-agnostic) with shelter review; bounded evaluable rule vocabulary with honest "not auto-evaluated" handling; three new structured adopter fields (date of birth, home environment, other pets) in onboarding/profile; per-request evaluation snapshot; "Policy check" section on shelter and publisher request detail pages (shared partial); evaluation chip on the shelter request list; shelter "Automatic evaluation" settings (translation review, system-rule visibility); re-run evaluation; Pundit authorization; i18n en/es; accessibility.

**Out of scope:** any automatic status change (reject/accept/validate) by the evaluation — the shelter always decides; auto-reject toggles or reopen flows (not needed since nothing auto-decides); verdict filters/sorting on the list; per-shelter threshold editing for **system** rules (central platform tuning only); evaluation-based scoring or compatibility changes; changing the existing fixed `adoption_policies` keys or their adopter-facing display; rules that call the AI provider at request time; additional untranslatable-policy data (e.g. children in household) — noted as future extensions; notification-preference changes.

---

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Shelters misinterpret verdicts as decisions | High | Advisory-only copy throughout; no status effects; AC-49-2 asserts status never changes; settings explain the three verdicts |
| Shelters distrust or ignore the screening | Medium | Full transparency on the detail page (which rule, what evidence); "not auto-evaluated" honesty; read-only system-rule visibility; red-verdict agreement metric |
| AI translation is wrong or misleading | Medium | Translation is proposed and shelter-reviewed before use; bounded vocabulary + validation/normalization; untranslatable policies marked, never guessed |
| Missing adopter data leads to noisy yellow flags | Medium | Missing data → yellow with explicit "couldn't verify" evidence; new structured fields reduce gaps; shelters can disable rules they don't value |
| New onboarding questions add friction | Medium | Only three questions; existing adopters never blocked; gentle one-time prompt (plan 48 principle) |
| DOB privacy concern | Medium | DOB stored under existing privacy conventions, editable, never shown raw to shelters (derived age only) |
| Regression of the review/decision flow | Medium | Evaluation never touches status transitions; regression suite covers existing flows |
| Rule evolution burden | Low | System rules centralized and tunable by platform team; rule vocabulary designed to grow via locale-key labels |

---

## Dependencies

- **Depends on:** existing adoption request submission/notification/timeline infrastructure; `shelter/adoption_requests` + `my/adoption_requests` detail views and the shared-partial pattern (plan 25); Adoption Policies settings area (plan 42); adopter onboarding questionnaire + `IndividualProfile` (new fields); Pundit conventions; i18n conventions (plan 33); AI vendor-agnostic service + prompt conventions (plan 25, AI Agent).
- **Follow-up candidates (not in this plan):** more structured household data (children, household size) to unlock further rules; verdict filters/sorting on the request list; "high-concern request arrived" shelter notification; evaluation-based routing/priority in the shelter dashboard (plan 44).
- **Note on numbering:** plan 48 references a future `49_nearby_pet_discovery_plan.md`. This plan takes the next free number (49). If the nearby-discovery plan is created later it should take the next free number (50) to avoid collision.

---

## Open Questions

1. **New-field onboarding placement** — the three new questions join the existing 8 as required-to-complete. Should any of them (e.g. date of birth) instead be optional-with-warning to reduce onboarding friction? (Current: required for new adopters; existing adopters never blocked.)
2. **Minimum-age default** — shelters already have a `minimum_age` policy key (display-only). Should translating an NL age policy also update that existing key for consistency, or is the evaluated `adopter_age_min` rule sufficient? (Current: evaluated rule only; existing key untouched.)
3. **Profile completeness definition** — currently "answered onboarding questions / total (now 11)". Should verification, location, or photo count later? (Deferred to when those features mature.)
4. **Children-in-household data** — several shelters ask about children; it's a sensitive signal and could enable potentially discriminatory rules. Deliberately excluded from the new fields; revisit with the founder before adding.
5. **Re-run cost** — re-running is deterministic and cheap today. If future rules call AI (e.g. pet-fit-dimension rules), re-run needs rate limits. Deferred until such rules exist.