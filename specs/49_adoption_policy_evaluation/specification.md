# Specification: Adoption Policy Auto-Evaluation — Advisory Request Screening with Natural-Language Shelter Policies

**Domain:** Adoptions, AI, Shelter Tools
**Priority:** 1 (High)
**Status:** Approved
**Source plan:** `specs/49_adoption_policy_evaluation_plan.md`

---

## Overview

When an adoption request is received, the system automatically evaluates the adopter's profile against **system rules** (platform-owned safety checks) and **shelter rules** (derived from the shelter's natural-language policies). The evaluation produces one of three advisory verdicts:

- **High concern (red)** — at least one high-severity rule failed (e.g. account too new, unverified email, underage adopter). Strongly suggests declining.
- **Needs review (yellow)** — at least one warning rule failed, or a rule couldn't be verified due to missing data.
- **Pre-accept (green)** — all evaluated rules passed; a recommendation to approve.

**Verdicts are advisory only. The evaluation never changes request status and never notifies the adopter of a decision. The shelter always makes the final call** through the existing accept/validate/decline actions.

Shelters write policies in plain language; an AI service translates them into a bounded set of evaluable structured rules at **policy-save time** (never per request), and shelters review before the rules go live. Three new structured adopter fields — **date of birth, home environment, other pets** — are added to onboarding so age, fenced-yard, and other-pet policies become evaluable. The results are shown on the request detail page as a "Policy check" section with a red/yellow/green badge and a rule-by-rule summary.

---

## Goals

1. Reduce shelter time-to-decision by screening requests automatically before human review.
2. Let shelters express screening requirements in natural language and get them translated into rules they can review and control.
3. Never fabricate: policies that can't be evaluated are honestly marked "not auto-evaluated" and never affect a verdict.
4. Keep the human in charge: verdicts are recommendations only — the shelter decides; green never accepts.
5. Surface the *why* behind every verdict with per-rule evidence on the request detail page.
6. Collect the structured adopter data (age, home, other pets) that makes real shelter policies evaluable.

---

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Evaluation timing | Async job after request creation; deterministic rule evaluation | No LLM call in the submission path; never blocks the adopter |
| NL → rules translation timing | At policy-save time, AI-proposed + shelter-reviewed | Reviewable, deterministic screening; cost contained |
| Verdict status effects | **None.** Red/yellow/green all leave the request `pending` | The shelter always decides; evaluation is decision support |
| Adopter notifications | Evaluation never notifies the adopter; existing decline flow only | No automatic decisions → no automatic messaging |
| System rules | Platform-owned, always evaluated, read-only to shelters, centrally tunable | Consistent safety baseline; shelters see but don't control |
| Rule vocabulary | Bounded types mapped to real signals; unsupported policies marked "not auto-evaluated" | Honesty rule from plan 25: never infer from missing data |
| New adopter signals | DOB, home environment, other pets collected in onboarding (required for new adopters; never blocks existing) | Unlocks age/fenced-yard/other-pet rules; existing adopters get honest "couldn't verify" |
| Missing data | Conservative: unevaluable rule → yellow with "couldn't verify" evidence | Safe default that invites human review |
| Snapshot semantics | Evaluation captured per request at evaluation time | Matches adopter-insight snapshot approach; no live recomputation drift |
| AI abstraction | Vendor-agnostic `Ai::*` service + prompt in `config/prompts/` + output validation | AI Agent conventions (plan 25) |
| Adopter transparency | Evaluation breakdown is responsible-party-only; adopters control their new profile fields | Screening is decision-support; adopters keep data control |
| Localization | All new strings en/es via locale files; user-authored policies rendered as-is | Plan 33 convention |
| Accessibility | Badges always carry a text label; color never the only indicator | WCAG AA |

---

## Key Behaviors

### 1. Request-time evaluation (REQ-49-1, REQ-49-7)

- On `Adoptions::SubmitRequest` success, an evaluation job is enqueued. It collects current adopter signals, evaluates system + enabled shelter rules, and persists a snapshot (verdict, summary, per-rule results, timestamp, version).
- **No status side effects, ever.** Accept/validate/decline remain exclusively human actions through the existing decision flow.

### 2. Advisory verdicts (REQ-49-2, REQ-49-6)

- **Red (High concern)** if any enabled high-severity (reject) rule fails.
- **Yellow (Needs review)** if any enabled warning rule fails, or any enabled rule can't be evaluated (missing data) → "couldn't verify" evidence.
- **Green (Pre-accept)** if at least one rule was evaluated and all passed.
- No evaluation at all → neutral localized empty state.
- Rule results ordered: failed high-severity first, then failed warnings, then passed.

### 3. Rule sources (REQ-49-3, REQ-49-5)

- **System rules** (always on, read-only to shelters): account younger than 3 days → red; unverified email → red; under 18 (from DOB) → red; profile < 60% complete → yellow; prior declined/withdrawn request for the same pet → yellow. Thresholds centralized and tunable by the platform team.
- **Shelter rules** (from NL policies): bounded vocabulary over real signals — `account_age_min`, `email_verified`, `adopter_age_min`, `home_fenced_yard_required`, `other_pets_allowed`, `profile_completeness_min`, `pet_experience_min`, `daily_time_available_min`, `adoption_priority_present`, `additional_answers_present`, `no_prior_decline_same_pet`. Each rule carries a severity (`red`/`yellow`) and enable/disable state.

### 4. NL → rules translation (REQ-49-4)

- Shelters save natural-language policies in the "Automatic evaluation" settings.
- An AI service proposes structured rules (type, parameters, severity) from the bounded vocabulary; output is validated/normalized; unparseable statements → "not auto-evaluated".
- Translation is proposed only — shelters review, edit, enable/disable, or discard before rules affect evaluation.
- Provider failure never blocks policy saving (raw policy text is kept; retry surfaced).

### 5. Request detail "Policy check" section (REQ-49-8, REQ-49-9)

- Shared partial on `shelter/adoption_requests/show` and `my/adoption_requests/show` (publisher sees system rules only).
- Red/yellow/green badge with a text label, a summary line, and a per-rule breakdown (label, severity, pass/fail, evidence, source).
- Advisory copy throughout — never decision-like; existing accept/validate/decline actions remain primary.
- Contextual actions: "Re-run evaluation"; link to settings.
- States: ready / evaluating (non-blocking) / no-evaluation-configured.

### 6. Triage chip on the list (REQ-49-10)

- Shelter request list shows a small verdict chip (red/yellow/green + label) per request. Advisory only; never replaces the status badge.

### 7. Settings: "Automatic evaluation" management (REQ-49-11)

- NL policy input; translation review list (enable/disable, edit severity/parameters); "not auto-evaluated" list; read-only system-rule list. Owner/administrator only.

### 8. Notifications & adopter transparency (REQ-49-12)

- The evaluation never notifies the adopter. Decline (when the shelter decides) uses the existing decline flow with reasons.
- Shelter gets the standard "new request" notification; the evaluation is visible on the detail page and list chip. No new notification kinds.

### 9. New structured adopter data (REQ-49-13)

- Onboarding adds three questions, stored on `IndividualProfile`:
  - **Date of birth** (date) → age for `adopter_age_min` + under-18 system rule. Privacy: stored per existing conventions, editable, never shown raw to shelters (derived age only).
  - **Home environment** (single-select): house with fenced yard / house without fenced yard / apartment or condo / other → `home_fenced_yard_required`.
  - **Other pets** (select): no other pets / dog(s) / cat(s) / other animals → `other_pets_allowed`.
- New adopters complete them as part of onboarding. Existing adopters are never blocked; missing fields → honest "couldn't verify" yellow results + a gentle, non-blocking prompt (plan 48 principle).

### 10. Re-run evaluation (REQ-49-14)

- Shelter staff can re-run against current signals; snapshot is replaced; re-running never changes status.

---

## Scope

**In scope:** automatic evaluation at request receipt; system + shelter rules; advisory red/yellow/green verdicts that never change status; NL → structured-rule translation (AI, vendor-agnostic) with shelter review; bounded evaluable vocabulary + honest "not auto-evaluated" handling; three new structured adopter fields (DOB, home environment, other pets) in onboarding/profile; per-request evaluation snapshot; "Policy check" section on shelter and publisher detail pages (shared partial); evaluation chip on the shelter list; shelter "Automatic evaluation" settings; re-run; Pundit authorization; i18n en/es; accessibility.

**Out of scope:** any automatic status change by the evaluation (reject/accept/validate) — the shelter always decides; auto-reject toggles or reopen flows; verdict filters/sorting; editing system-rule thresholds per shelter; AI calls at request time; changing existing `adoption_policies` keys or their adopter-facing display; children-in-household data and other untranslatable-policy data; notification-preference changes.

---

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Shelter has no enabled rules | System rules still evaluate; neutral empty state if truly no evaluation |
| Rule references missing data (no profile, no DOB, no answers) | Yellow "couldn't verify" evidence; never inferred |
| Existing adopter completed onboarding before the new fields | Not blocked; yellow "couldn't verify" on new-field rules + gentle prompt |
| NL policy can't be translated | Marked "not auto-evaluated", shown to adopters, never affects verdict |
| AI translation fails / provider error | Policy saving not blocked; raw policy kept; retry surfaced |
| Under-18 adopter applies | Red system rule; request stays `pending`; shelter decides |
| Shelter's policy requires a fenced yard, adopter lives in an apartment | Yellow/red shelter rule fails; request stays `pending`; shelter decides |
| Adopter updates profile after evaluation | Snapshot stays until staff re-run (REQ-49-14) |
| Same pet, second request after decline | System rule `no_prior_decline_same_pet` warns |
| Individual publisher request | Evaluation = system rules only; same shared partial |
| No additional answers submitted | `additional_answers_present` rule (if enabled by shelter) → yellow; honest evidence |
| Evaluation still in flight when staff opens detail | Non-blocking "evaluating" state (matches adopter-insight pattern) |
| Adopter's DOB is close to a minimum-age threshold | Age computed precisely from DOB; evidence shows derived age ("19 years old") |
| Locale es | All rule labels, summaries, evidence, onboarding questions, and notifications localized; user-authored policies render as-is |
| Badge rendering | Color + text label always; AA contrast; reduced-motion respected |