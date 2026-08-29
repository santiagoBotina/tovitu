# Specification: Adoption Engagement & Trust (REQ-12, REQ-13, REQ-14)

**Domain:** Dashboard, Navigation, Pet Profile, Trust & Safety
**Priority:** 2 (Medium)
**Status:** Implemented
**Source plan:** `specs/37_adoption_engagement_trust_plan.md`
**Owner:** Domain Agent (recommendation value object + journey variant), Frontend Agent (dashboard card, sidebar/nav copy, profile section), Data Agent (migration, model validation).

---

## Overview

Three medium-priority improvements strengthen the emotional core of Tovitu — accompaniment and trust:

1. **REQ-12 — Journey card upgrade.** The dashboard's "Adoption Journey" card gains a Tovitu-branded background, a one-sentence explanation, an achieved-milestones summary, a concrete next step, and a clear state-adaptive CTA — without points, levels, or leaderboards.
2. **REQ-13 — Clarify "Incoming Requests" for individual users.** The navigation item and all related copy are renamed so an individual user understands it is about requests *they receive* when they give a pet up for adoption — not requests *they send* as an adopter. Shelter vocabulary is unchanged.
3. **REQ-14 — Shelter recommendation on the pet profile.** Shelters and individual publishers can author a recommendation for a pet; it renders on the public pet profile with clear "shelter says" framing, is visually differentiated from AI content, and is sanitized + appropriateness-checked before storage and display.

---

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Storage | **`pets.recommendation` text column** (new migration) | Content is pet-scoped by definition; one column keeps it cheap and versionless |
| Sanitization | `Pets::Recommendation` value object in `lib/pets/recommendation.rb` | Domain-agent convention; strips HTML/scripts/event-handlers and enforces a bounded length + appropriateness heuristic |
| Model hook | `before_validation :sanitize_recommendation` + `validate :recommendation_content_appropriate` on `Pet` | Sanitization happens once at write time regardless of entry path (shelter form, individual form, service objects) |
| Display | ERB auto-escape (`<%= %>`) + `whitespace-pre-wrap` paragraph | Defense in depth: even a legacy stored payload cannot execute |
| Recommendation framing | "What the shelter says about %{name}" for shelter pets; "What %{publisher} says about %{name}" for individual-listed pets | AC-37-14/37-18: clear author, no AI badge, distinct visual treatment vs. the 🤖 AI Life Preview |
| Journey variant | `Gamification::Journey#card_variant` → `:fresh` / `:mid_journey` / `:active_applicant` | View stays thin; thresholds documented in one place; presentation-derived (no new tables) |
| Journey CTA | `card_cta_key` + `card_cta_path` computed from the variant | Fresh → complete profile; mid-journey → browse pets; active applicant → see requests |
| REQ-13 naming | Reuse existing locale keys, change values to role-accurate copy | "Single terminology source" (locale keys); minimal churn; shelter sidebar unaffected |
| Animations | Static brand gradient; no new animation utilities | AC-37-1 + reduced-motion edge case: static brand treatment |

---

## REQ-12 — Adoption Journey card

### Journey card variants (`Gamification::Journey#card_variant`)

| Variant | When | Explanation | CTA |
|---------|------|-------------|-----|
| `:fresh` | Onboarding incomplete AND no saved pets AND no requests | The journey explained + what's first | Complete profile → `profile_onboarding_path` |
| `:mid_journey` | Otherwise (profile progress / saved pets / past requests) | Celebrate progress + name the next step | Browse pets → `pets_path` |
| `:active_applicant` | ≥1 request `pending`/`in_validation` | Status context + awaiting-shelter line | See your requests → `adoption_requests_path` |

Published-pet users keep the same CTA logic (the primary journey CTA never conflicts with the giving-up role; the dashboard already shows a separate "My Published Pets" card).

### Card anatomy (top of left column, replaces the old readiness card)

- **Background:** `bg-gradient-to-br from-primary-50 via-primary-50/70 to-white border-primary-100` — full surface tint per the Playground Scale Rule (no side-stripe).
- **Header:** journey icon + "Adoption Journey" title + percent badge.
- **Explanation:** one accessible sentence, localized per variant.
- **Progress:** existing `progress-shimmer` bar + segmented stage indicator (kept).
- **Achievements:** "You've reached X of Y milestones" + compact milestone chips (done=teal check, locked=neutral).
- **Next step:** localized per `next_step_key` (existing).
- **CTA:** one primary button (`bg-primary-500`), label + path per variant.
- **Accompaniment line:** "Tovitu está contigo en cada paso" footer with a heart icon.

No points, levels, or leaderboards. No animated background flourishes (reduced-motion safe). Responsive classes keep the card from breaking mobile layout.

---

## REQ-13 — Clarify "Incoming Requests" for individuals

Terminology updates (values only — keys reused as the single source):

| Key | en | es |
|-----|----|----|
| `shared.sidebar.incoming_requests` | "Requests for my pets" | "Solicitudes para mis mascotas" |
| `dashboard.index.incoming_requests` | "Requests for my pets" | "Solicitudes para mis mascotas" |
| `my.adoption_requests.index.title` | "Requests for my pets" | "Solicitudes para mis mascotas" |
| `my.adoption_requests.index.subtitle` | "Adoption requests you receive from people who want one of your pets." | … |
| `my.adoption_requests.index.empty_body` | "When you publish a pet for adoption, requests from adopters appear here." | … |
| `my.pets.show.incoming_requests` | "Requests for this pet" | "Solicitudes para esta mascota" |

- The sidebar item remains visible to all individuals (it already has a helpful empty state) — the copy now makes the role explicit.
- Shelter sidebar is untouched (`shared.sidebar.adoptions`), keeping genuine organizational vocabulary.
- Notifications/emails already read "…has submitted an adoption request for %{pet_name}" — no "incoming requests" wording to change there.

---

## REQ-14 — Shelter recommendation

### `Pets::Recommendation` (`lib/pets/recommendation.rb`)

- `MAX_LENGTH = 600`
- `.sanitize(value)` → nil-safe, strips HTML tags, script/style blocks, event handlers (`on\w+=`), and `javascript:` / `vbscript:` URL schemes; collapses whitespace; strips; returns nil when blank.
- `.inappropriate?(value)` → checks a curated profanity/abuse blocklist (word-boundary matched, case-insensitive, with common leetspeak substitutions).
- `.appropriate?(value)` → `!inappropriate?(value)`.

### `Pet` model

- `before_validation :sanitize_recommendation` — stores sanitized plain text.
- `validate :recommendation_content_appropriate` — friendly error on blocklist hit.
- `validates :recommendation, length: { maximum: Pets::Recommendation::MAX_LENGTH }`.
- Whitespace-only input → nil (section hidden on profile).

### Profile rendering (`pets/show`)

- Renders only when `pet.recommendation.present?`.
- Card: `bg-primary-50` surface, shelter/paw icon, heading "What the shelter says about %{name}", author line ("Written by %{author}"), plain-text body, **no** AI badge (visually distinct from the 🤖 AI Life Preview card).
- `PetPresenter#recommendation` → sanitized display value; `#recommendation_author` → `shelter.name || publisher.name`; `#recommendation_author_kind` → `:shelter` | `:individual`.
- Edits propagate immediately (column read at render; no cache).

### Forms

- `shelter/pets/_form.html.erb` — new "Recommendation" section (label + textarea + hint).
- `my/pets/new.html.erb` + `my/pets/edit.html.erb` — same field.
- Both controllers add `:recommendation` to permitted params.

---

## Out of Scope (unchanged from plan)

Points/badges/leaderboards; full dashboard redesign; moderation dashboard/workflow (MVP uses automated validation); shelter↔adopter messaging.

---

## Verification

- `spec/lib/pets/recommendation_spec.rb` — sanitize (script/iframe/onerror/javascript:), appropriateness, length, whitespace.
- `spec/models/pet_spec.rb` — recommendation sanitize-on-write, blocklist rejection, max length, whitespace→nil, render toggle.
- `spec/requests/pet_recommendation_spec.rb` — profile render/no-render, shelter vs individual framing, XSS payload neutralized in the response body.
- `spec/lib/gamification/journey_spec.rb` — `card_variant` per state.
- `spec/requests/dashboard_gamification_spec.rb` — journey card variants, explanation, achievements, CTA, accompaniment line, no new-gamification, REQ-13 sidebar + dashboard naming.
- `spec/requests/my/adoption_requests_spec.rb` — REQ-13 index title/subtitle/empty-state naming.
- i18n parity check for every new key (en/es).