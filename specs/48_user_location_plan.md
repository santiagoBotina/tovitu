# Plan: User Location — Collection, Storage, Management & Privacy (Adopter "My Location")

**Domain:** Adopter Experience, Privacy & Consent, Onboarding, Shelter Tools
**Priority:** 1 (High) — unlocks proximity-based discovery and recommendations
**Status:** Draft
**Tracks:** Epic "Personalized Pet Discovery" (Story 1 — Location Foundation)

---

## Overview

Tovitu's core promise is helping the right pets find the right people. Proximity is a fundamental part of that: adopters want to browse pets near them, and shelters want geographic context about who is applying. Today the platform stores **no location for adopters**, so discovery cannot be personalized by area and shelters have no idea where applicants live.

This plan adds an opt-in **"My Location"** capability for adopter accounts:

- **Collected two ways**: (1) asked during account creation with a clear statement of purpose, and (2) detected from the user's device.
- **Stored** per adopter at **city-level precision only** (privacy by design — exact coordinates are not retained at full precision).
- **Fully user-controlled**: viewable, modifiable, and deletable at any time.
- **Shelter-facing privacy boundary**: shelters never receive an adopter's exact location. During the adoption process and on the adopter's profile, shelters see only the city (or a neutral "not shared" state).

This plan intentionally **excludes** the downstream consumer features — nearby-pet filtering, distance-based recommendations, and adjustable radius. Those depend on this foundation and are specified in a follow-up plan (`49_nearby_pet_discovery_plan.md`).

---

## Current State (confirmed in code)

- **No location data exists on adopter accounts.** `User` has no location fields or associations; `AdopterProfile`/`IndividualProfile` is personality and lifestyle answers only.
- **Shelters already carry their own location** (`Shelter` has `street`, `city`, `state`, `zip`), displayed on the shelter profile and pet cards (e.g., "City, State"). The shelter's city is the only geographic context in pet discovery today.
- **Adopter onboarding exists** as a multi-step questionnaire (`onboarding/individual/questions`, with single-select, multi-select, and text question types) followed by a review/completion step. This is the natural home for a location step.
- **Profile settings exist** (`authentication/profiles#edit` / `#update`, route `resource :profile`) where adopter account/profile management lives — the natural home for location management (view/modify/delete).
- **Adoption process for shelters** (adoption requests review, adopter profiles) currently shows no adopter location at all.
- **i18n convention in place** (plan 33): all user-facing strings in `config/locales/*.yml`, en/es.
- **User roles:** `individual` (adopter), `shelter_admin`, `shelter_staff`, `admin`, `staff`. This feature applies to **adopter accounts only**.

---

## User Stories

> As a new adopter,
> I want to optionally share my location — with a clear explanation of why — when I create my account,
> so that I can see pets and recommendations relevant to my area without wondering what I agreed to.

> As an adopter,
> I want the option to let Tovitu detect my location from my device,
> so that I don't have to type where I live.

> As an adopter,
> I want to view, change, or delete my location at any time,
> so that I stay in control of my personal data.

> As a shelter staff member,
> I want to see only the city of an applicant (never their exact location) during the adoption process and on their profile,
> so that I can understand where they're from and plan logistics without invading their privacy.

---

## Requirements & Proposed Behavior

### REQ-48-1 — Consent-first location collection during account creation

The adopter onboarding flow (immediately after account creation) includes an **optional** location step:

- **Purpose disclosure is mandatory and shown inline** before any collection. The copy must state, in plain language:
  - Why we collect it ("to show you pets and recommendations near you"),
  - How it is used (personalization; city-level context for shelters),
  - That it is **optional** and can be skipped,
  - That it can be **changed or deleted anytime**,
  - That **shelters only ever see the city** — exact location is never shared.
- The step must **not block account creation or onboarding completion**. "Skip for now" is always available.
- The user's decision (shared / skipped) and the disclosure version are **recorded with a timestamp** for consent traceability.
- Disclosure copy lives in `config/locales/*.yml` (en/es) — never hardcoded.

### REQ-48-2 — Two collection methods

1. **Device-based detection (primary when available):** the browser's Geolocation API is used, after the user explicitly taps "Use my current location" (which triggers the browser permission prompt). The detected position is **immediately reduced to city-level precision** before storage — full device precision is never stored.
2. **Manual entry (always available):** the user types/selects a city name. This is the fallback when device detection is unavailable, denied, or imprecise.

At the onboarding step both options are offered ("Use my current location" / "Enter city manually") plus "Skip for now".

### REQ-48-3 — Purpose-limited storage at city-level precision

- One current location per adopter account ("My Location").
- Stored data is limited to what the stated purposes require:
  - **Display location**: city, region/state, country (what the user and shelters see).
  - **Approximate coordinates** at city-level precision (enough for the follow-up proximity spec to compute distance, but not precise enough to identify a home/street address).
  - **Source**: `device` or `manual`.
  - **Consent metadata**: decision + disclosure version + timestamp.
  - **Timestamps**: created/updated.
- Location is used **only** for: personalization of pet discovery/recommendations (next spec) and city-level context for shelters in the adoption process.
- Reverse-geocoding (coordinates → city) must be isolated behind a service abstraction (vendor-agnostic, per project convention) so no business logic couples to a specific provider.

### REQ-48-4 — Full user control: view, modify, delete

Adopters manage "My Location" from **profile settings**:

- **View**: shows the stored city-level location, its source, and when it was last updated.
- **Modify**: change the city manually, or re-detect from the device ("Update to my current location"). Updates record a new timestamp; consent does not need to be re-requested for a change of the same disclosed purpose.
- **Delete**: full removal with an explicit confirmation that states the consequences:
  - Location-based personalization stops,
  - The city is no longer shown to shelters on the profile or in new activity,
  - **Disclosure**: the city may remain on adoption applications already submitted (see REQ-48-6 snapshot rule).
- Deletion is **irreversible** from the user's perspective (they can re-add location later, but the previous data is not restored).

### REQ-48-5 — Privacy boundary for shelters (never exact location)

- Shelters **never** receive an adopter's exact location — no coordinates, no street-level data, no precision metadata — in **any** view, export, message, or notification (including the Messaging/WhatsApp domain).
- During the **adoption process** (application review) and on the **adopter's profile**, shelters see only: **city** (+ region/state where needed for disambiguation).
- If the adopter has **no location set** (never shared or deleted), shelters see a neutral localized "City not shared" state — never a broken/empty-looking field, and never treated as a red flag.
- This boundary is a hard product rule: no shelter-facing feature may request or display more granular location.

### REQ-48-6 — Snapshot rule for already-submitted applications

When an adopter submits an adoption application, the **city at that time** is recorded with the application as a snapshot for the shelter's records.

- Deleting location later affects **all future views** (profile, new applications, personalization) but does **not** retroactively erase city snapshots on already-submitted applications.
- This is **disclosed in the deletion confirmation** (REQ-48-4) so the privacy promise is honest.
- Rationale: shelters legitimately need the applicant's city for adoption logistics (home visits, handover); retracting already-shared data from a third party is neither possible nor honest to promise.

### REQ-48-7 — Graceful degradation for device detection

| Scenario | Behavior |
|----------|----------|
| Browser permission denied | Manual entry offered; never blocking; friendly localized message |
| Geolocation API unsupported | Device option hidden; manual entry offered |
| Timeout / very imprecise reading | Retry or manual entry; friendly localized message |
| Non-secure context (no HTTPS) | Device option hidden; manual entry offered |
| User clears browser permission later | Same as denied on next attempt |

### REQ-48-8 — No-location state is a first-class product state

- Browsing, search, and recommendations work **exactly as today** when no location is set. Missing location is never an error.
- The platform must never coerce or nag an adopter into sharing location after they've skipped or deleted it (one gentle, optional re-offer in settings is the maximum).

### REQ-48-9 — Adopter-only scope

- The "My Location" feature applies to **individual/adopter accounts** only. Shelter accounts are out of scope: shelters already carry their own location on the shelter profile, and an adopter's location is never exposed to them beyond the city rule.

### REQ-48-10 — Localization

- All new user-facing strings — disclosure copy, settings labels, confirmation copy, error messages, shelter-facing "City not shared" — are localized en/es via `config/locales/*.yml`.

---

## Acceptance Criteria

- **AC-48-1** — During account creation, adopter onboarding offers an optional location step with full purpose disclosure (why, how it's used, optionality, control, shelter city-only rule); skipping it never blocks account creation or onboarding completion.
- **AC-48-2** — Location can be collected via device detection **or** manual city entry at the onboarding step.
- **AC-48-3** — The user's decision (shared/skipped) and the disclosure version are recorded with a timestamp.
- **AC-48-4** — Device-detected location is stored at city-level precision only; full device precision is never persisted.
- **AC-48-5** — In profile settings, adopters can view, modify, and delete their location; updates and deletions are timestamped.
- **AC-48-6** — Deleting location stops location-based personalization and removes the city from the adopter's profile and new application activity; the deletion confirmation discloses that city snapshots on already-submitted applications remain.
- **AC-48-7** — Shelters see only city (+ region/state) during the adoption process and on the adopter's profile; exact coordinates or precision metadata never appear in any shelter-facing surface.
- **AC-48-8** — Adopters with no location set show a neutral localized "City not shared" state to shelters.
- **AC-48-9** — Device detection failures (denied, unsupported, timeout, non-secure) degrade gracefully to manual entry with friendly localized messages and never block the flow.
- **AC-48-10** — Browsing/search/recommendations behave exactly as today when no location is set.
- **AC-48-11** — The feature is adopter-only; shelter accounts are unaffected.
- **AC-48-12** — All new strings are localized en/es; no hardcoded user-facing strings.
- **AC-48-13** — Proximity filtering, distance-based recommendations, and radius adjustment are **not** implemented in this plan (deferred to the follow-up plan).

---

## Success Metrics

- **Onboarding location share rate:** % of new individual signups who share a location during onboarding (baseline to establish; target ≥ 50%).
- **Adopter location coverage:** % of active adopters with a location set within 30 days of signup (target ≥ 60%).
- **Deletion rate (guardrail):** % of adopters who delete their location within 90 days of sharing (expect low, < 5%; sustained spikes indicate a trust/UX problem).
- **Control engagement:** % of adopters who update their location after initial collection (moving, re-detection) — indicates the control is discoverable and usable.
- **Shelter context coverage:** % of adoption applications where the shelter sees a city (vs. "not shared") — target ≥ 50% once location coverage matures.
- **Trust guardrail:** zero privacy complaints received about adopter location handling.

---

## Test Strategy

- **Request specs** for: onboarding location step (share/skip/manual/device paths), profile settings view/update/delete, deletion cascade and confirmation, shelter-facing city display and "not shared" state, consent recording.
- **Negative tests:** device permission denied, unsupported API, timeout, non-secure context; no-location adopter applying; shelter staff viewing an adopter profile must never receive coordinates (assert rendered output contains no coordinate values).
- **Authorization:** only the owning adopter can view/modify/delete their location (Pundit); shelter staff can only read the city-level display value.
- **Manual QA matrix:** desktop + mobile; permission granted/denied; browser without geolocation; both locales; Turbo navigation in onboarding and settings.
- **Regression:** existing onboarding, profile settings, adoption request review, and pet discovery specs continue to pass.

---

## Scope

**In scope:** optional location step in adopter onboarding (disclosure, device detection, manual entry, skip); purpose-limited city-level storage; consent traceability; profile settings management (view/modify/delete with confirmation); shelter-facing city-only display during the adoption process and on adopter profiles; "City not shared" state; application city snapshot rule; graceful degradation of device detection; localization; authorization boundaries.

**Out of scope:** nearby-pet filtering, distance-based ranking, recommendations, and adjustable radius (follow-up plan `49_nearby_pet_discovery_plan.md`); map-based location picking (possible later enhancement); storing location history or multiple locations; shelter account locations (shelters already have their own location); exposing coordinates to shelters in any form; third-party location data sharing.

---

## Risks

- **Privacy perception:** adopters may be wary of sharing location. Mitigated by consent-first disclosure, city-level precision, easy deletion, and the hard shelter privacy boundary (REQ-48-5).
- **Permission fatigue / abandonment:** the browser permission prompt may deter users. Mitigated by making location optional, always offering manual entry, and never blocking.
- **Reverse-geocoding vendor dependency:** coordinates → city requires a provider; mitigated by isolating it behind a service abstraction (project vendor-agnostic convention) with manual entry as the always-available fallback.
- **Precision trade-off:** storing city-level precision could make the follow-up proximity feature feel coarse in dense urban areas. Accepted trade-off for privacy; can be revisited with user-facing precision settings later.
- **Deletion expectations vs. shared data:** adopters may expect deletion to erase everything, including what shelters already saw. Mitigated by the explicit snapshot disclosure in the deletion confirmation (REQ-48-4/48-6).
- **Legal/consent compliance:** collecting location requires recorded consent and a disclosed purpose. Mitigated by REQ-48-1 (disclosure + recorded decision + version + timestamp) and easy revocation.
- **Shelter feature creep:** shelters may ask for more precise applicant locations. The city-only rule (REQ-48-5) is a hard product boundary and must be enforced by policy + specs.

---

## Dependencies

- **Depends on:** existing adopter onboarding flow (location step hooks into the questionnaire); existing profile settings (`authentication/profiles`); i18n convention (plan 33); adoption request review + adopter profile views (shelter-facing city display).
- **Follow-up plan:** `49_nearby_pet_discovery_plan.md` — nearby-pet filtering, recommendations, and adjustable radius, consuming this foundation.
- **Related:** plan 27/34 (authentication/onboarding flows), plan 43 (shelter personal information redesign — shelters' own location), plan 18 (adoption requests integration — shelter review views).