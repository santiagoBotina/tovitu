# Plan: Shelter Dashboard — Modernization & Shelter-Specific Information Architecture (Story 1.4)

**Domain:** Frontend, Shelter Tools, Design System
**Priority:** 2 (Medium-High)
**Status:** Draft
**Tracks:** Epic "Shelter Experience UI Modernization" (Story 1.4)

---

## Overview

The Shelter Dashboard has drifted visually from the Adopter Dashboard. It already carries much of the right content (welcome, pipeline metrics, recent activity, quick actions, team status) but the presentation, hierarchy, empty states, and data density need to be brought up to the current design system.

The redesign must **not simply copy the Adopter Dashboard** — the two users have different goals. Shelters operate: they need to see what needs their attention, act on it, and know where things stand. The redesign:

- Reuses the **visual language** of the updated app (DESIGN.md "Playground Standard": cards, typography, spacing, buttons, icons, empty states).
- **Keeps shelter-specific workflows** and reorganizes content around the shelter's primary operational tasks.
- **Prioritizes actionable and operational information** over decorative content.
- **Uses only data that already exists** — no speculative metrics or invented business logic.

---

## Current State (confirmed in code)

- **Controller:** `Shelters::DashboardController#show` computes real counts:
  - `@total_pets`, `@adoptable_pets` (status `available`), `@pending_requests` (status `pending`), `@in_review_requests` (status `in_validation`), `@active_adoptions` (status `accepted`), `@total_requests_count`.
  - `@recent_activity` = last 5 adoption requests (with pet + adopter), `@staff_count` / `@staff_members`.
- **View:** `app/views/shelters/dashboard/show.html.erb` already has: welcome overlay (first visit), section_header welcome, pending-requests alert bar, gamified onboarding checklist (+ dismiss/restore), 4 pipeline metric cards, recent activity card, quick actions card (add pet, review applications, manage team, adoption policies — some admin-gated), team status card.
- **Adopter dashboard** (`app/views/dashboard/index.html.erb`) is the newer design reference: gradient hero card, bento grid, journey/readiness card, richer empty states.
- Metric cards today are compact `p-5` cards; the adopter dashboard uses more expressive cards with clearer hierarchy.

---

## User Stories

> As a shelter operator,
> I want to see at a glance how many pets need homes and how many adoption requests need my attention,
> so that I can prioritize the day's work.

> As a shelter operator,
> I want important actions (reviewing applications, adding a pet) to be more prominent than secondary information,
> so that the dashboard drives me toward the work that matters.

---

## Requirements & Proposed Behavior

### REQ-44-1 — Design consistency with the adopter dashboard

Adopt the newer UI patterns while preserving shelter-specific content:

- **Modern card-based layout** using the design-system card recipe and the same expressive style as the adopter dashboard (consistent `rounded-xl`, borders, restrained shadows, `bento-enter` motion where used).
- **Consistent typography hierarchy** (`font-display` headings, `text-neutral-*` body per DESIGN.md).
- **Updated spacing and container sizes** matching the adopter dashboard's scale.
- **Consistent buttons and action patterns** (primary/ghost recipes, focus rings).
- **Better empty states** with useful next steps.
- **Responsive layouts** across mobile, tablet, desktop.
- **Appropriate icons and visual indicators** (status colors, badges, avatars).

### REQ-44-2 — Overview / welcome area

Keep and refine the contextual welcome area:

- Contextual welcome message (personalized by shelter name).
- Shelter identity (name; logo where available).
- Short summary of current activity — derived from **existing** counts (e.g., "X adoptable pets, Y pending requests").

### REQ-44-3 — Key metrics (data-backed only)

Use visually consistent metric cards. Supported by existing data:

- **Adoptable pets** (`status: available`)
- **Pending adoption requests** (`status: pending`)
- **Applications under review** (`status: in_validation`)
- **Active adoptions** (`status: accepted`)

Rules:

- Metrics must come from **real application data** (the existing dashboard controller queries) — never hardcoded.
- Zero-value states are clearly communicated (e.g., "0" with neutral styling + helpful hint, not an error-looking state).
- Loading states: server-rendered page — verify Turbo navigation and the checklist Turbo Stream refreshes never flash broken/empty metric markup; no skeleton screens required unless a metric becomes async (currently none).
- Card design follows the current dashboard design system (upgrade the existing compact cards to the target style).

### REQ-44-4 — Actionable content prioritized

- **Pending/new adoption applications** get higher prominence than secondary info (e.g., the pending alert bar remains; the activity list keeps direct "View request" navigation).
- **Pets requiring profile completion** — evaluate as an actionable section only if derivable from existing data without speculative logic (e.g., pets without a primary photo or without a description; verify exact fields during implementation). If not cleanly derivable, it stays out of scope.
- **Recent adoption activity** with direct navigation to the relevant management screen.
- **No unnecessary duplication** across dashboard sections (each fact appears in exactly one place).

### REQ-44-5 — Quick actions

Keep and refine clearly visible shortcuts for common shelter workflows (only those with existing destinations):

- **Add a pet** → `new_shelter_pet`
- **Manage pets** → shelter pets index (add if the destination exists)
- **Review adoption applications** → `shelter_adoption_requests`
- **Configure adoption policies** → `edit_shelter_policies` (admin-gated as today)
- **Manage shelter profile** → `edit_shelter` (admin-gated as today)
- **Manage staff/team** → `shelter_staff_index` (admin-gated as today; UI-only until plan 46)

Rules:

- Actions visually consistent with the dashboard.
- Actions navigate to the correct destination (regression-checked).
- Most important shelter actions prioritized (add pet + review applications first).
- Layout remains usable on mobile (buttons/tap targets large enough; grid collapses cleanly).

### REQ-44-6 — Preserve functionality

- All existing behavior preserved unless intentionally redesigned: welcome overlay, onboarding checklist (+ dismiss/restore), pending alert bar, Turbo Stream refreshes, Pundit gating on quick actions.
- The gamified onboarding checklist remains shelter-specific and untouched except for visual consistency.

**Edge cases:**

- Empty shelter (no pets, no requests) → rich empty state: welcome copy + "Add your first pet" primary CTA + secondary "Learn what adopters see" or similar (using existing strings where possible).
- Zero pending requests → alert bar hidden (current behavior); metrics show zero with neutral styling.
- Long shelter names / many staff members → truncation and "+N" overflow (existing team status pattern) preserved.
- Unauthorized quick actions (non-admin) → hidden (current `can_manage` gating) — no broken links.
- Mobile: metrics stack 2-up then 1-up; activity and quick actions stack vertically (current grid `md:grid-cols-5` behavior) — verify comfortable tap targets.
- Locale: all strings localized (en/es).
- Turbo: checklist completion and policy updates refresh dashboard widgets via Turbo Streams — must keep working after restructure.

---

## Acceptance Criteria

- **AC-44-1** — The Shelter Dashboard no longer appears visually disconnected from the Adopter Dashboard.
- **AC-44-2** — Shared design elements (cards, typography, spacing, buttons, icons, empty states) use consistent styles and spacing.
- **AC-44-3** — The dashboard maintains a shelter-specific information architecture (operational/actionable, not a copy of the adopter dashboard).
- **AC-44-4** — Metrics represent real application data (not hardcoded) and zero-value states are clearly communicated.
- **AC-44-5** — Loading states are handled appropriately (no broken flashes during Turbo navigation/refreshes).
- **AC-44-6** — Important actions are more prominent than secondary information; users can navigate directly from dashboard items to the relevant management screen.
- **AC-44-7** — Empty states provide useful next steps where appropriate.
- **AC-44-8** — Information does not duplicate unnecessarily across dashboard sections.
- **AC-44-9** — Quick actions are visually consistent, navigate to the correct destination, prioritize the most important actions, and remain usable on mobile.
- **AC-44-10** — Existing functionality is preserved unless intentionally redesigned (welcome overlay, onboarding checklist + dismiss/restore, alert bar, Turbo Stream refreshes, authorization gating).
- **AC-44-11** — The experience works correctly across mobile, tablet, and desktop.
- **AC-44-12** — All new/changed strings are localized (en/es); no hardcoded user-facing strings.

---

## Success Metrics

- **Visual parity:** design review confirms the shelter dashboard reads as part of the same application as the adopter dashboard.
- **Operational clarity:** shelter operators identify pending work faster (founder-reported / usability check).
- **Actionability:** share of dashboard visits that result in a click into applications or pet management (analytics if available; otherwise qualitative).
- **Zero regression:** dashboard request specs pass; no broken quick-action links.

---

## Test Strategy

- **Request specs:** `spec/requests/shelters/dashboard_spec.rb` continues to pass (counts, authorization, dismiss/restore checklist) — unchanged business behavior.
- **View specs:** dashboard renders welcome, metrics from controller data, activity items with links, quick actions with correct paths and gating, empty states, team status overflow.
- **Manual QA matrix:** empty shelter / busy shelter / admin vs. non-admin × mobile/tablet/desktop; Turbo Stream refresh after checklist/policy update; both locales.

---

## Scope

**In scope:** visual modernization of the Shelter Dashboard to match the adopter dashboard's design language while keeping shelter-specific IA; metric card upgrade; actionable content and empty-state improvements; quick-action consistency and correctness; responsive refinements; all presentation-layer.

**Out of scope:** new metrics requiring new queries/domain logic beyond the existing dashboard controller data (unless trivially derived, e.g., pets needing profile completion — validated during implementation); adoption-request management screens themselves (separate scope); onboarding checklist logic; roles & permissions (plan 46); any schema/model changes.

---

## Risks

- **Copying the adopter dashboard wholesale** — explicitly prohibited by the requirement; mitigated by AC-44-3 and a shelter-specific IA review.
- **Adding metrics without data** — mitigated by the "existing data only" rule (REQ-44-3) and the validation gate on "pets requiring profile completion."
- **Breaking Turbo Stream widgets** — the checklist/progress-bar refresh is triggered from other screens (policies update, checklist completion); mitigated by keeping widget DOM targets/IDs stable and re-running dashboard + policies specs.
- **Quick-action link drift** — mitigated by view specs asserting exact paths and a manual click-through matrix.
- **Design drift** — mitigated by reusing shared recipes and the design-review pass.

---

## Dependencies

- **Depends on plan 41** (standardized page header) for the welcome header if the back-nav slot applies (dashboard itself is an entry point, so mainly for spacing consistency).
- **Related to plans 42/43/45** — quick actions link to the redesigned policies, profile, and staff pages; those plans must keep their routes stable.
- **Related to plan 46** (roles & permissions) — quick actions and dashboard visibility will later become role-aware; this plan keeps current `can_manage` gating.
- **Depends on plan 33 conventions** (i18n) already in place.