# Specification: User Location — Collection, Storage, Management & Privacy (Adopter "My Location")

**Domain:** Adopter Experience, Privacy & Consent, Onboarding, Shelter Tools
**Priority:** 1 (High)
**Status:** Approved
**Source plan:** `specs/48_user_location_plan.md`

---

## Overview

Adopters currently have no location on Tovitu, so discovery can't be personalized by area and shelters have no geographic context about applicants. This spec introduces an opt-in **"My Location"** capability for adopter accounts:

- Collected two ways — asked during account creation with a clear statement of purpose, and detected from the device.
- Stored at **city-level precision only** (privacy by design; exact coordinates are never retained at full precision).
- Fully user-controlled — viewable, modifiable, deletable at any time.
- Shelters see **only the city** during the adoption process and on the adopter's profile — never the exact location.

The downstream consumer features (nearby-pet filtering, recommendations, radius adjustment) depend on this foundation and are specified separately in `49_nearby_pet_discovery_plan.md`.

---

## Goals

1. Collect an adopter's location with **transparent consent** during account creation, with two collection methods (manual + device).
2. Store location at **city-level precision only**, limited to the disclosed purposes.
3. Give adopters **full control**: view, modify, delete at any time.
4. Enforce a hard **privacy boundary**: shelters only ever see the city.
5. Leave **no-location** as a first-class, graceful product state.

---

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Location is adopter-only | No location step for shelter accounts | Shelters already carry their own location; an adopter's location is private |
| Collection point | Optional step in the adopter onboarding questionnaire | Follows account creation ("while creating the user"), purpose-built context, non-blocking |
| Storage precision | City-level only; full device precision never persisted | Privacy by design; sufficient for future proximity queries |
| Consent model | Recorded decision + disclosure version + timestamp at collection | Traceability and legal compliance; change of same purpose does not re-prompt |
| Device detection | Browser Geolocation API behind a service abstraction | Vendor-agnostic per project convention; manual entry always available as fallback |
| Shelter exposure | City (+ region/state) only, in adoption process + adopter profile | Hard privacy boundary; never coordinates or precision metadata |
| Application snapshot | City recorded on the application at submission; survives later deletion | Shelters need applicant city for logistics; honest, disclosed retraction limits |
| Deletion semantics | Full removal of current location + personalization; snapshot disclosure | Respects user control while being honest about already-shared data |
| No-location state | Neutral localized "City not shared" for shelters; browsing unchanged for adopters | Missing location is never an error and never a red flag |
| All new strings localized | en/es via `config/locales/*.yml` | Plan 33 i18n convention |

---

## Key Behaviors

### 1. Onboarding location step (REQ-48-1, REQ-48-2)

- Presented as an optional step in the adopter onboarding questionnaire, right after account creation.
- Inline **purpose disclosure** before any collection:
  > "We use your location to show you pets and recommendations near you. Your exact location stays private — shelters only ever see your city. You can change or delete it anytime."
- Three actions: **Use my current location** (device, primary), **Enter city manually** (always available), **Skip for now** (non-blocking).
- Skipping proceeds normally; onboarding completion is never blocked by the location step.

### 2. Device-based detection (REQ-48-2, REQ-48-7)

- Triggered only by an explicit user tap (which fires the browser permission prompt).
- The detected position is reduced to city-level precision before storage.
- Failures degrade gracefully: permission denied, unsupported API, timeout, or non-secure context all fall back to manual entry with friendly localized messages — never an error wall.

### 3. Profile settings management (REQ-48-4)

- "My Location" card in profile settings shows: city-level location, source (Device / Entered manually), last updated.
- Actions:
  - **Update to my current location** — re-runs device detection.
  - **Edit city** — manual change.
  - **Delete location** — confirmation with consequences:
    > "Delete your location? We'll stop personalizing pets by location, and shelters will no longer see your city on your profile or in new activity. Your city may remain on adoption applications you've already submitted. This can't be undone."
- Deletion is irreversible; re-adding later starts fresh.

### 4. Shelter-facing privacy (REQ-48-5, REQ-48-6)

- Shelters see **city** (+ region/state when needed) on:
  - the adopter's profile, and
  - the adoption request/application review.
- No coordinates, no street-level data, no precision metadata in any shelter surface (including messaging).
- No location set → neutral localized **"City not shared"**.
- Application submissions snapshot the city at that time; later deletion does not retroactively erase those snapshots (disclosed in deletion confirmation).

### 5. No-location is first-class (REQ-48-8)

- Browsing, search, and recommendations behave exactly as today without location.
- No nagging after skip/delete; at most one gentle, optional re-offer in settings.

---

## Scope

**In scope:** optional location step in adopter onboarding; device detection + manual entry; city-level storage; consent traceability; profile settings view/modify/delete; shelter-facing city-only display; "City not shared" state; application city snapshot; graceful degradation; localization; authorization boundaries.

**Out of scope:** nearby-pet filtering/recommendations/radius (follow-up `49_nearby_pet_discovery_plan.md`); map-based picking; location history/multiple locations; shelter account locations; exposing coordinates to shelters; third-party data sharing.

---

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Adopter skips location at onboarding | Account + onboarding complete normally; location can be added later from settings |
| Device permission denied / unsupported / timeout / non-secure | Device option hidden or degraded; manual entry offered; never blocking |
| Adopter moves cities | Update via "Edit city" or "Update to my current location"; timestamp refreshes |
| Adopter deletes location | Personalization stops; profile + new activity show "not shared"; submitted applications keep the city snapshot (disclosed) |
| Adopter with no location applies | Shelter sees neutral "City not shared" |
| Shelter staff view adopter profile | City only; rendered output never contains coordinates |
| Shelter account user | No location step shown (feature is adopter-only) |
| Locale | All strings localized en/es; disclosure + confirmation + errors included |
| Turbo navigation | Location step behaves like the existing questionnaire; settings updates use the standard profile form/streams |
| Multiple accounts, one device | Each account stores its own location independently |