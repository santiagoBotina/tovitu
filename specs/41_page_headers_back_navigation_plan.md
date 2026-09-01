# Plan: Standardized Dashboard Page Headers & Back Navigation (Story 1.1)

**Domain:** Frontend, Navigation, Design System
**Priority:** 1 (High) — foundation that unblocks plans 42–45
**Status:** Draft
**Tracks:** Epic "Shelter Experience UI Modernization" (Story 1.1)

---

## Overview

The reusable **"Back to…" navigation element** is inconsistent across dashboard sections. Some pages render it through the shared partial, others inline; none give it enough separation from the sticky navbar, so back links look glued to the top of the viewport and the page header lacks the breathing room used elsewhere in the app.

This plan standardizes the page-header layout used by every dashboard sub-page:

```text
Navbar
   ↓  consistent top spacing
Back navigation (when applicable)
   ↓
Page title
Optional description
   ↓
Main page content
```

The result is a single reusable pattern — no per-page layout duplication — with consistent spacing, iconography, typography, interaction states, and deterministic navigation.

---

## Current State (confirmed in code)

- **Shared partial exists:** `app/views/shared/_back_link.html.erb` renders the chevron + label with hover/focus states. Spacing is explicitly "controlled by the caller."
- **`shared/_section_header` exists** and already prepends a top margin (`mt-6`) so titles clear the sticky navbar, but it has **no back-link slot**.
- **Shelter sub-pages render an inline `<header>`** (`shelters/policies/edit`, `shelters/staff/index`, `shelters/edit`) that places `shared/back_link` + title with only `mb-6` and **no top margin** → back link sits immediately under the `h-16` sticky navbar (`app/views/layouts/application.html.erb` renders the navbar, `<main>` has no top padding).
- **My Pets uses a separate inline back link** (`app/views/my/pets/show.html.erb`) with `mb-6`, no top margin, and slightly different markup than `shared/back_link`.
- **`safe_back_path` helper already exists** (`app/helpers/navigation_helper.rb`) and validates `back_to` (same-origin, internal paths only, falls back on malformed/external values). It is not consistently wired to the shared back link.
- Other sub-pages that use back-style navigation include shelter pet detail/media, adoption request detail/decision screens, and notifications — all should be audited.

---

## User Stories

> As a shelter or adopter dashboard user,
> I want back navigation to sit at a consistent distance below the navbar on every sub-page,
> so that the header feels part of the app rather than cramped against the top edge.

> As a user moving between a detail page and its listing,
> I want the back button to take me to the screen I came from (when reachable) and to a sensible fallback otherwise,
> so that navigation never dead-ends and never depends on browser history quirks.

---

## Requirements & Proposed Behavior

### REQ-41-1 — Reusable page-header pattern

Introduce (or extend) a single reusable component that renders, in order:

1. Top spacing token (the design-system value already used by `shared/section_header` — `mt-6` default, validated against DESIGN.md spacing scale).
2. Optional back navigation (rendered via `shared/back_link`).
3. Page title (existing `font-display` heading styles).
4. Optional description/subtitle.
5. Optional CTA slot (preserve the existing `section_header` block behavior).

**Implementation direction (for spec):** add an optional `back_link` local to `shared/section_header` (path + optional label) that renders `shared/back_link` above the title row, OR introduce `shared/page_header` that composes `shared/back_link` + `shared/section_header`. Either way there must be **one** source of truth — no new inline header markup on pages.

### REQ-41-2 — Consistent vertical spacing

- Every page using the pattern gets identical spacing: navbar → back link, back link → title, title → content.
- The header block must use the same top margin everywhere (`mt-6` per the existing convention, or the validated design-system token).
- Content container: back link and header align with the page's main content container (the `max-w-* mx-auto` wrapper each page already uses) — never full-bleed.

### REQ-41-3 — Consistent interaction & visual states

- Reuse the exact `shared/back_link` styling everywhere: chevron icon, `text-sm`, `neutral-500 → neutral-700` hover, rounded focus ring (`focus-visible:ring-2 ring-primary-500 ring-offset-2`).
- Hover, focus-visible, and mobile tap targets are identical across all instances.
- No duplicate back-link CSS or markup on any page.

### REQ-41-4 — Deterministic navigation (no browser history)

- Back links navigate to a **contextual path**, resolved with `safe_back_path`:
  - When the page was reached with a `back_to` query param, navigate there (same-origin validation already handled by the helper).
  - Otherwise navigate to the explicit fallback for that page (e.g., dashboard, pet listing, adoption requests list).
- Never use `window.history.back()` / `history.go(-1)`.

### REQ-41-5 — Apply across all dashboard sub-pages

Audit and update every page that uses a back-navigation pattern, including but not limited to:

- **My Pets** — `my/pets/show`, `my/pets/edit` (entry: `my/pets` listing)
- **Adoption Policies** — `shelters/policies/edit` (entry: shelter dashboard)
- **Personal Information** — `shelters/edit` (entry: shelter dashboard / public profile)
- **Staff** — `shelters/staff/index` (entry: shelter dashboard)
- **Shelter pet detail/media/imports** and **adoption request detail/decision** screens (audit; apply the same pattern where a back link already exists or is the natural parent-child navigation)

Pages that are natural entry points (dashboard itself, index pages) must **not** show a back link.

### REQ-41-6 — No regressions

Existing navigation flows continue to work: dashboard → sub-page → back → dashboard; pet listing → pet detail → back → listing (via `back_to`).

**Edge cases:**

- No `back_to` param → explicit fallback (never dead-end, never external).
- Malformed/external `back_to` (`//host`, `https://…`, backslashes) → fallback (helper already guards; keep).
- Turbo navigation: back links must render and work after Turbo visits; focus rings visible on keyboard focus.
- Mobile: consistent spacing at small viewports; tap target ≥ 44px equivalent.
- Pages reached directly (fresh load, no referrer) → fallback path shown.
- RTL is not in scope; spacing must remain symmetric so a future RTL flip stays clean.
- Translation scope footgun: if the header partial captures a block (`capture { yield }`), callers must precompute lazy `t(".…")` keys as locals before the render call (documented in `shared/section_header`).

---

## Acceptance Criteria

- **AC-41-1** — The back-navigation element is no longer visually attached or too close to the navbar on any page using the pattern.
- **AC-41-2** — All pages using the pattern have identical vertical spacing (navbar → back link → title → content).
- **AC-41-3** — The back-navigation element aligns with the page's main content container.
- **AC-41-4** — Hover, focus-visible, and mobile interaction states are identical across all instances.
- **AC-41-5** — Back navigation goes to the correct contextual screen (back_to-aware) and never relies on browser history.
- **AC-41-6** — The solution is reusable: one component/layout; no per-page duplication of header/back-link styles.
- **AC-41-7** — No regressions to existing navigation flows (dashboard → sub-page → back; listing → detail → back via `back_to`).
- **AC-41-8** — Responsive across mobile, tablet, and desktop viewports.
- **AC-41-9** — All new/changed user-facing strings are localized (en/es); no hardcoded strings.

---

## Success Metrics

- **Visual consistency:** no page renders a back link with different spacing, iconography, or states (visual audit across all dashboard sub-pages).
- **Zero duplication:** no inline back-link markup remains outside the shared component(s).
- **Navigation correctness:** manual QA passes for every affected section (entry, back_to, direct-load, malformed back_to).
- **No regressions:** existing request specs for shelters/staff/policies/dashboard/pets continue to pass.

---

## Test Strategy

- **View/request specs:** assert the shared header renders back link + title + description in the documented order with the expected container classes; assert back link is absent on entry-point pages.
- **Navigation specs:** `safe_back_path` behavior (valid `back_to`, malformed, external, direct load) — extend existing coverage if thin.
- **Manual QA matrix:** each affected page on mobile/tablet/desktop; keyboard focus; Turbo back/forward; locale prefix routes (`/en/…`, `/es/…`).

---

## Scope

**In scope:** reusable page-header/back-navigation component (or extension of `shared/section_header`); consistent spacing and interaction states; `safe_back_path` wiring; audit + update of all dashboard sub-pages that use back navigation (My Pets, Adoption Policies, Personal Information, Staff, shelter pet/adoption-request detail screens where applicable).

**Out of scope:** any change to business logic, routing structure, or sidebar/navbar behavior; RTL support; redesign of individual sections (those are separate plans 42–45 and depend on this one); changes to `safe_back_path` security behavior beyond what is needed for consistent usage.

---

## Risks

- **Patching instances instead of the shared component** — the most likely failure mode; mitigated by AC-41-6 and a full audit pass.
- **Turbo `capture` translation footgun** — if the header accepts a block, lazy `t(".…")` keys inside the block resolve against the partial's scope; mitigated by the documented precompute-locals pattern.
- **Back link appearing where it shouldn't** — entry-point pages must not render one; mitigated by an explicit "no back link" rule and QA matrix.
- **`back_to` open-redirect risk** — already guarded by `safe_back_path`; keep guards and add specs.

---

## Dependencies

- **Blocks / unblocks:** this plan is the foundation for plans 42 (Adoption Policies), 43 (Personal Information), 44 (Shelter Dashboard), and 45 (Staff UI) — all of which reuse the standardized header.
- **No external dependencies.** Safe to schedule first in Epic 1.