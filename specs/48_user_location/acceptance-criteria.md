# Acceptance Criteria: User Location — Collection, Storage, Management & Privacy (Story 1)

**Source plan:** `specs/48_user_location_plan.md`

---

## AC-1: Consent-first collection during account creation

**Given** I am a new adopter completing account creation
**Then** the onboarding flow presents an optional location step

**Given** the location step is shown
**Then** it displays a clear purpose disclosure covering: why location is collected, how it is used, that it is optional, that it can be changed or deleted anytime, and that shelters only ever see the city

**Given** I choose "Skip for now"
**Then** account creation and onboarding complete normally and are never blocked

**Given** I make a decision (share or skip)
**Then** my decision and the disclosure version are recorded with a timestamp

---

## AC-2: Two collection methods

**Given** the location step is shown
**Then** I can collect my location via device detection ("Use my current location") or manual city entry, with skip always available

**Given** I choose device detection
**Then** a browser permission prompt is triggered only after my explicit tap

**Given** I choose manual entry
**Then** I can type or select a city and the location is stored from that entry

---

## AC-3: City-level precision storage

**Given** my location is collected from my device
**Then** it is stored at city-level precision only — full device precision is never persisted

**Given** my location is stored
**Then** it contains only what the disclosed purposes require: city/region/country, approximate coordinates at city-level precision, source (device or manual), consent metadata, and timestamps

**Given** my location is stored
**Then** it is used only for discovery personalization and city-level context for shelters — never for any other purpose

---

## AC-4: Full user control in profile settings

**Given** I open profile settings with a location set
**Then** I can view my city-level location, its source, and when it was last updated

**Given** I want to change my location
**Then** I can edit the city manually or re-detect from my device, and the update is timestamped

**Given** I want to delete my location
**Then** a confirmation explains: personalization stops, the city is no longer shown to shelters on my profile or in new activity, and the city may remain on adoption applications already submitted

**Given** I confirm deletion
**Then** my location is removed and cannot be restored

---

## AC-5: Shelter privacy boundary

**Given** a shelter staff member reviews an adoption application
**Then** they see only the adopter's city (+ region/state where needed) — never coordinates, street-level data, or precision metadata

**Given** a shelter staff member views an adopter's profile
**Then** the same city-only rule applies, and rendered output never contains coordinate values

**Given** an adopter has no location set
**Then** shelters see a neutral localized "City not shared" state — never an error-looking or red-flag state

**Given** messaging or notifications are sent to a shelter
**Then** no adopter location beyond the city (when needed) is ever included

---

## AC-6: Deletion semantics

**Given** I delete my location
**Then** location-based personalization stops and my profile/new activity no longer show my city

**Given** I already submitted adoption applications before deleting my location
**Then** the city snapshot recorded on those applications remains visible to the shelter, and this was disclosed in the deletion confirmation

---

## AC-7: Graceful degradation of device detection

**Given** I tap "Use my current location" but deny browser permission
**Then** I am offered manual entry with a friendly localized message and the flow is never blocked

**Given** my browser does not support geolocation, or the context is non-secure
**Then** the device option is hidden and manual entry is offered

**Given** device detection times out or returns a very imprecise reading
**Then** I can retry or use manual entry, with a friendly localized message

---

## AC-8: No-location is a first-class state

**Given** I have no location set
**Then** browsing, search, and recommendations behave exactly as they do today

**Given** I have skipped or deleted location
**Then** the platform never nags or coerces me into sharing it again (at most one gentle optional re-offer in settings)

---

## AC-9: Adopter-only scope

**Given** a shelter account user
**Then** no location step is shown and the feature does not apply to shelter accounts

---

## AC-10: Localization

**Given** the locale is English
**Then** all new location strings (disclosure, settings, confirmations, errors, "City not shared") render in English

**Given** the locale is Spanish
**Then** all new location strings render in Spanish

**And** no new user-facing strings are hardcoded in views

---

## AC-11: Regression

**Given** the test suite runs
**Then** existing onboarding, profile settings, adoption request review, and pet discovery specs continue to pass

**And** new request specs cover: onboarding share/skip/manual/device paths, settings view/update/delete, deletion cascade + confirmation, shelter-facing city display + "not shared", and consent recording

**And** negative tests assert shelter-facing rendered output never contains coordinates