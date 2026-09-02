# Specification: Shelter Dashboard — Modernization & Shelter-Specific Information Architecture (Story 1.4)

**Domain:** Frontend, Shelter Tools, Design System
**Priority:** 2 (Medium-High)
**Status:** Approved
**Source plan:** `specs/44_shelter_dashboard_modernization_plan.md`

---

## Overview

The Shelter Dashboard has drifted visually from the Adopter Dashboard. This spec upgrades its presentation, hierarchy, empty states, and data density to the current design system (DESIGN.md "Playground Standard") while **preserving shelter-specific information architecture** — the shelter dashboard stays operational and actionable, not a copy of the adopter dashboard.

The redesign:

- Reuses the **visual language** of the updated app (cards, typography, spacing, buttons, icons, empty states, `bento-enter` motion).
- **Keeps shelter-specific workflows** and reorganizes content around the shelter's primary operational tasks.
- **Prioritizes actionable and operational information** over decorative content.
- **Uses only data that already exists** — no speculative metrics or invented business logic.

---

## Goals

1. Bring the shelter dashboard to visual parity with the adopter dashboard (shared design language).
2. Keep shelter-specific IA: see what needs attention, act on it, know where things stand.
3. Make important actions (reviewing applications, adding a pet) more prominent than secondary information.
4. Improve empty and zero-value states so they communicate calmly and point to useful next steps.
5. Preserve every existing behavior (welcome overlay, onboarding checklist + dismiss/restore, pending alert bar, Turbo Stream refreshes, Pundit gating).

---

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Server-rendered only | No new async metrics | No skeleton screens; existing queries stay synchronous |
| Controller-computed data | Counts stay in `Shelters::DashboardController` | Single source of truth, request-spec friendly |
| Pets-needing-attention in scope | Derived from existing columns only | `description` (blank) or `photos` (empty) on non-terminal pets; no speculative logic |
| Turbo Stream targets unchanged | `#onboarding-checklist`, `#progress-bar` kept | Policies controller replaces both; checklist completion refreshes them |
| Header keeps `shared/section_header` | No bespoke header | Plan 41 consistency; identity rendered as an inline avatar in the title row |
| No new CSS classes | Reuse `bento-enter`, `card-lift`, design tokens | No design-system additions required |
| All new strings localized | en/es via `config/locales/*.yml` | Plan 33 i18n convention |

---

## Design System Mapping (DESIGN.md)

- **Cards:** `bg-white rounded-xl shadow-sm border border-neutral-200`, `p-6` (compact `p-5` where needed), `bento-enter` + staggered delays.
- **Typography:** `font-display` for headings, `text-neutral-700`+ body (4.5:1 AA floor), `text-neutral-500` for secondary.
- **Color blocks:** full-surface tints for emphasis (`primary-50`, `warning/10`, `info/10`, `secondary-50`) — no side-stripe borders (Playground Scale Rule).
- **Buttons:** full-bleed `primary-500`/`secondary-500` for primary actions; `rounded-xl`, `active:scale-[0.97]`, focus rings.
- **Motion:** `bento-enter` entrance animation only; transform/opacity; `prefers-reduced-motion` respected via existing CSS.
- **No glassmorphism, no gradient text, no side-stripe borders** (design-system explicit don'ts).

---

## Key Behaviors

### 1. Header / overview (REQ-44-2)

- `shared/section_header` with title `"%{name} Dashboard"`.
- Shelter identity: logo avatar (or initials tile) rendered inline in the title row when a logo is attached.
- Contextual subtitle derived from existing counts, one of:
  - No pets → setup encouragement.
  - Pending requests → "X request(s) awaiting review + Y adoptable pets".
  - Otherwise → adoptable pets + active adoptions summary.

### 2. Pending alert bar (REQ-44-4, preserved)

- Rendered only when `@pending_requests > 0`.
- Warning-tinted banner, pluralized copy (no emoji), "Review Now" → `shelter_adoption_requests_path`.

### 3. Onboarding checklist (REQ-44-6, preserved)

- Same card container (`bg-primary-50 ... border-primary-100`), same `_checklist`, `_progress_bar`, `_encouragement` partials.
- Turbo Stream DOM targets `#onboarding-checklist` and `#progress-bar` unchanged.

### 4. Metrics (REQ-44-3)

- Four data-backed cards: **Adoptable pets**, **Pending requests**, **In review**, **Active adoptions**.
- Expressive design-system cards (tinted icon tiles, display numerals, label), each a link to the relevant management screen.
- Zero-value states: neutral `0` + helpful hint; never error-styled.

### 5. Empty shelter state (edge case)

- When `@total_pets == 0 && @total_requests_count == 0`, a gradient hero empty state replaces the metrics grid: welcome copy + primary "Add Your First Pet" + secondary action (policies for admins, public page otherwise).

### 6. Recent activity (REQ-44-4)

- Recent adoption requests with status-coded icons, adopter/pet copy, and a direct "View" link to the request.
- "View all activity" when 5+.
- Rich empty state with next-step CTA.

### 7. Pets needing attention (REQ-44-4, validated derivable)

- Only non-terminal pets (`available`/`on_hold`, undiscarded) missing a **photo** or a **description**.
- Card shows up to 5 rows; each row links to the pet's edit screen with a badge naming what's missing.
- "Manage all pets" footer link.

### 8. Quick actions (REQ-44-5)

- Two prominent full-bleed actions first: **Add a Pet** (`new_shelter_pet_path`), **Review Applications** (`shelter_adoption_requests_path`).
- Secondary list: **Manage Pets** (`shelter_pets_path`, always), and admin-gated **Manage Team**, **Configure Policies**, **Shelter Profile**.

### 9. Team status (preserved)

- Existing avatars + "+N more" overflow, admin "Manage Team" link, `@staff_count >= 2` visibility rule.

---

## Scope

**In scope:** visual modernization of the shelter dashboard; metric card upgrade; actionable/empty-state improvements; quick-action correctness and prominence; responsive refinements; presentation layer only.

**Out of scope:** new metrics requiring new domain logic beyond existing dashboard data (the pets-needing-attention query is trivially derived and included); adoption-request management screens; onboarding checklist logic; roles & permissions (plan 46); schema/model changes.

---

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Empty shelter (no pets, no requests) | Gradient hero empty state with "Add your first pet" + secondary CTA |
| Zero pending requests | Alert bar hidden; pending metric shows `0` with neutral hint |
| Zero on any metric | `0` with neutral styling + specific hint; no error look |
| Long shelter names / many staff | Truncation + `+N` overflow preserved (existing team pattern) |
| Non-admin quick actions | Admin-gated actions hidden (existing `can_manage`) — no broken links |
| Mobile | Metrics 1-up → 2-up → 4-up; activity/quick actions stack; generous tap targets |
| Locale | All strings localized en/es; no hardcoded strings |
| Turbo | Checklist/policy updates refresh dashboard widgets via Turbo Streams; DOM targets stable |