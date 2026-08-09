# Plan: Unauthenticated Homepage — Discovery Entry Point & Conversion (Item 2.1)

**Domain:** Frontend, Landing, Pet Discovery, Conversion
**Priority:** 1 (High)
**Status:** Draft
**Tracks:** Product Improvements §2 (Public Homepage & User Conversion)

---

## Overview

The landing page (`app/views/landing/index.html.erb`) currently works as a static marketing page with a hero, "How It Works," a "For Shelters" section, and a final CTA. It does not function as an **entry point into the pet discovery experience** for unauthenticated users: visitors cannot search/browse pets from the homepage itself, there are no featured pets, and nothing persists their exploration so it can be reused on a later visit.

This plan transforms the public homepage into a **landing + discovery hybrid**: visitors can immediately search and browse available pets without registering, their exploration is stored locally in the browser, and conversion-focused sections explain Tovitu's value and drive account creation.

### Goals
- Let unauthenticated users **search and browse pets** from the homepage without an account.
- **Persist exploration locally** (filters/search/saved interest) so a returning visitor picks up where they left off and is nudged to create an account to save their progress.
- Add **conversion-focused sections** (how matching works, benefits of an account, adoption process) that make the value concrete.
- Preserve the existing brand personality (Playground Standard, DESIGN.md) — no generic SaaS landing patterns.

---

## Current State (confirmed in code)

- **Landing page** (`app/views/landing/index.html.erb`): hero (purple, logo wordmark, CTA buttons linking to `pets_path` and shelter login) → "How It Works" (3 numbered steps) → "For Shelters" (feature cards) → final CTA (teal). No pets are rendered on the page.
- **Pets browsing is already public**: `PetsController` (`app/controllers/pets_controller.rb`) has **no authentication before_action**; `index` calls `skip_authorization`. The pets index at `/pets` already supports search/filtering (species chips, filters grid: breed, age, size, city/state, good-with, query) via `Pets::Search.call`.
- **Pet detail** (`pets/show`) calls `authorize @pet` — need to confirm the `PetPolicy` permits unauthenticated `show?` (Pundit policies typically default-deny; this must be verified/fixed so basic pet info is browsable logged-out).
- **Saved pets require an account**: `SavedPetsController` and `Pets::SavesController` rely on `current_user`; `saved_pets_path` is authenticated. There is no localStorage-based interest/save mechanism today.
- **localStorage precedent exists**: `sidebar_controller.js` persists `tovitu:sidebar` in `localStorage` — the pattern is established for a `tovitu:exploration` key.
- **Navbar** (`shared/_navbar.html.erb`) for signed-out users shows Sign In / Create Account links; there is a search input in the navbar but **only for signed-in users** (`<% if signed_in? %>` wrapper, lines 23–38).
- Homepage locale strings live under `landing.index.*` in `config/locales/{en,es}.yml`.

---

## User Stories

> **As a first-time visitor**, I want to search for adoptable pets directly from the homepage without creating an account, so that I can immediately see whether Tovitu has pets I'm interested in.

> **As a returning visitor who hasn't signed up yet**, I want my recent search/filters and pet interests to be remembered in my browser, so that when I come back I can continue exploring and eventually decide to create an account.

> **As a hesitant visitor**, I want to understand how Tovitu's matching works and what I gain from an account, so that I feel confident creating one.

---

## Proposed Experience

### Part A — Homepage pet discovery (no account required)

1. **Search bar in the hero** (replaces/augments the current "Find a pet" CTA):
   - Large, on-brand search input (DESIGN.md input styling, `rounded-xl`, primary focus ring) wired to `pets_path` with the `query` param (same param the pets index and navbar search use).
   - Submitting navigates to `/pets?query=...` and **pre-fills the filter state** on the pets index.
   - Keep the secondary "I'm a shelter" link as-is.
2. **Featured pets strip on the homepage**:
   - A horizontal-scrollable card row (or a 3–4 card grid) of adoptable pets pulled from the public pets query (e.g., `Pet.undiscarded.adoptable.includes(:shelter).recent.limit(6)` or reuse `Pets::Search` with a `featured` policy — decide with Domain/Data agents; keep the data simple at MVP).
   - Each card links to the public pet show page (with `back_to: root_path` so the back link returns to the homepage).
   - Cards follow the pet-card visual language already used in `dashboard/index.html.erb` (photo, name, breed, match-score-style badge only if real scoring exists — **do not** fake scores; use a "Available" status chip instead per `app/views/pets/_status_badge.html.erb`).
   - Section header + "View all pets" link.
3. **Basic pet info browse**: verify/ensure `PetPolicy#show?` allows unauthenticated access to the essential pet profile (photos, name, species, breed, age, size, description, shelter name/city). If policy currently denies, update it (Product→Spec handoff; security review: public pet profiles are the intended default, contact details stay behind auth).
4. **Save-for-later via localStorage** ("paw it" / interest bookmark):
   - Heart/bookmark button on pet cards (homepage strip and/or pets index for logged-out users) stores `pet_id` in `localStorage["tovitu:interests"]` (an array; cap at, say, 20; dedupe).
   - On the pets index, previously interested pets show a filled heart (no account needed).
   - **Conversion hook**: when a logged-out user clicks "View my saved pets" (or on their 2nd+ interest), show a friendly interstitial/modal: *"Save your picks — create a free account to keep them."* with a create-account CTA. No hard wall; dismissing keeps them browsing.
   - On sign-up/creation, offer to import localStorage interests into real `SavedPet` records (one-time migration — decide scope at implementation; default: a soft prompt on first dashboard visit).

### Part B — Persist exploration locally

1. **`tovitu:exploration` localStorage key** (new Stimulus controller, e.g., `exploration_memory`):
   - On the pets index, save the current filter/search params (`query`, `species`, `breed`, `age_category`, `size`, `city`, `state`, `good_with_*`) to localStorage as the user applies filters (debounced), keyed by last-write time.
   - On the homepage, if `tovitu:exploration` exists and is recent (e.g., < 14 days), render a **"Pick up where you left off"** section: your last filters as chips + a "Resume search" button linking to `/pets` with those params, plus your localStorage interests as mini-cards.
   - Clear/refresh logic: when the user creates an account, offer to carry the exploration forward (merge into server-side state) then clear the local key.
2. **Privacy**: everything is client-side; no PII stored; localStorage only (no cookies beyond what exists). Note in the plan for review: respect `prefers-reduced-motion` and add a visible "Clear my saved searches" affordance in the resume section.

### Part C — Conversion-focused sections

Add to the landing page (below the existing "How It Works", before "For Shelters", or interleaved per design review):

1. **Featured Pets section** (Part A.2) — the discovery hook.
2. **"How matching works" section**: 3 compact visual steps describing the AI matching story (tell us about you → we analyze compatibility → meet pets that fit) using the existing brand geometry/icon language. Keep copy short, avoid the "numbered marker" cliché per DESIGN.md (use icon tiles instead of 01/02/03).
3. **"Benefits of creating an account" section**: 3–4 benefit cards (save pets, get personalized matches, apply in minutes, track your adoption journey). Emphasize outcomes, not features.
4. **"Adoption process overview"**: a simple horizontal journey (Discover → Meet → Apply → Adopt → Thrive) — visual only, links to relevant pages where they exist.
5. **Interactive discovery component**: the hero search (Part A.1) doubles as the interactive component; optionally add a species quick-pick (Dogs / Cats / Other chips) that jumps to `/pets?species=...`.

### Ordering recommendation (visual hierarchy)
Hero (with search) → Featured Pets → How it works → How matching works → Adoption process → Benefits of account → For Shelters → Final CTA. Final layout to be settled in design review; keep `landing.index.*` i18n structure but add new keys under `landing.index.discovery.*`, `landing.index.featured.*`, `landing.index.matching.*`, `landing.index.benefits.*`, `landing.index.process.*`, `landing.index.resume.*`.

---

## Acceptance Criteria (2.1)

- **AC-2.1-1** An unauthenticated visitor can search pets from the homepage hero and lands on `/pets` with results matching their query.
- **AC-2.1-2** An unauthenticated visitor can view the full public pets index with all current filters, and open any pet's public profile (photos, name, species, breed, age, size, description, shelter name/city) without being redirected to login.
- **AC-2.1-3** The homepage shows a Featured Pets section with real adoptable pets (never fake/mock data or fabricated match scores); each card links to the pet page and back to the homepage works.
- **AC-2.1-4** A logged-out visitor can bookmark ("paw") pets; the bookmark persists in localStorage across page reloads and reflects on the pets index.
- **AC-2.1-5** The first time a logged-out user tries to view their saved pets, a friendly conversion prompt appears (create-account CTA, dismissible, no hard wall).
- **AC-2.1-6** Filter/search state on the pets index persists to `tovitu:exploration`; the homepage shows a "Pick up where you left off" resume section when recent exploration exists.
- **AC-2.1-7** "How matching works", "Benefits of an account", and "Adoption process" sections render with concise, on-brand copy (i18n en/es) and no generic SaaS patterns (no numbered-marker kickers, no glass, no gradient text).
- **AC-2.1-8** When a visitor creates an account, the app offers to import their localStorage interests/saved pets into their account (soft prompt; dismissible).
- **AC-2.1-9** All new UI respects `prefers-reduced-motion` and WCAG AA (contrast, keyboard, focus rings).
- **AC-2.1-10** Shelter login path and existing landing sections (How It Works, For Shelters, final CTA) remain intact.

---

## Success Metrics

- **Conversion lift**: sign-up click-through from homepage increases (baseline to be captured before/after; proxy: % of new sessions that view ≥2 pets pages before sign-up).
- **Discovery engagement**: % of logged-out sessions that perform a search or open a pet from the homepage (new metric).
- **Return exploration**: % of returning logged-out visitors who resume from the "Pick up where you left off" section (new metric).
- **Safeguard**: no regression in current landing page quality (design review) and no security regression (pet profiles remain safe; contact details stay protected).

## Test Strategy

- **Request/system specs**: unauthenticated access to `pets#index` and `pets#show` (with policy change if needed); homepage renders featured pets from real data; `back_to` param preserved.
- **JS specs / manual QA**: localStorage exploration memory (save, resume, clear); bookmark persistence; conversion prompt appears once and is dismissible; import-on-signup flow.
- **View specs**: new landing partials render and use i18n keys.
- **A11y check**: contrast on hero search over purple background, keyboard flow for horizontal scroll strip, reduced-motion.
- **Existing suite**: full `bin/rails test`/spec run to catch regressions.

## Scope

**In scope:** hero search; featured pets strip; public pet profile access (policy update if required); localStorage interests + exploration memory (Stimulus controller); conversion prompt; three new conversion sections; import-on-signup prompt; i18n keys.

**Out of scope:** full authentication-less saved-pets backend (real SavedPet still requires account); personalized AI matching for logged-out users; messaging/WhatsApp for visitors; changing the pets search backend semantics (Pets::Search is reused as-is); push/email for logged-out users; the AWS/infrastructure item (see section 5 note).

## Risks

- **Public pet profiles** expose shelter/basic pet data to anyone — acceptable by product intent, but confirm the PetPolicy change and what fields remain hidden (contact details, internal notes) with the Domain/Spec agents.
- **localStorage complexity** can grow — keep to a single controller + one key pair (interests + exploration), capped sizes, and a clear affordance.
- **Fake match scores** temptation on featured cards — explicitly prohibited; use real status chips only.
- **Homepage length** could balloon — keep each new section compact (3 items max per section) and get a design pass before implementation.
- **Import-on-signup** adds a data-migration concern — keep it a one-time, best-effort client→server sync with a "skip" path.
