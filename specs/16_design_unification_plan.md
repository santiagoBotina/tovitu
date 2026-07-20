# Plan: Design Unification — Settings, Pets, Shelters & Beyond

**Domain:** Frontend, UX
**Priority:** 2 (improves visual consistency across all authenticated pages)
**Status:** Draft
**Timestamp:** 2026-07-20

---

## Overview

The adopter and shelter dashboards (implemented in plan #14) established a new visual standard for Tovitu: bento-grid cards, generous spacing, contextual empty states, consistent use of design tokens, and micro-interactions (`bento-enter`, `card-lift`, `progress-shimmer`, etc.). However, the remaining pages — Settings/Profile, Pets index, Pet detail, Shelters index, Shelter detail, Saved Pets, and all shelter management pages — still use an older visual vocabulary: simpler card layouts, fewer animations, less considered empty states, and inconsistent application of the DESIGN.md system.

This plan defines a phased approach to bring every authenticated page up to the dashboard's visual standard, using **Stitch MCP** to generate and iterate on high-fidelity design screens, and then implementing those designs in ERB/Tailwind.

### Design Reference

The **adopter dashboard** (`app/views/dashboard/index.html.erb`) is the canonical reference. Key patterns to propagate:

| Pattern | Dashboard Implementation | Target Pages |
|---------|------------------------|--------------|
| **Bento grid cards** | Responsive grid with `rounded-xl`, `shadow-sm`, `border border-neutral-200`, `p-6` | All index/list pages |
| **Section headers** | `font-display text-lg font-bold text-neutral-800` with `flex items-center justify-between` | All pages |
| **Contextual empty states** | Centered illustration, `font-display` heading, body text, CTA button | All pages |
| **Micro-interactions** | `bento-enter`, `card-lift`, `image-reveal`, `score-pop`, `active:scale-[0.97]` | Cards, interactive elements |
| **Gradient accent cards** | `bg-gradient-to-br from-secondary-50 to-white` with accent border | Highlighted sections |
| **Progress bars** | `rounded-full h-3`, `progress-shimmer` animation | Settings/onboarding |
| **Button patterns** | `px-5 py-2.5 rounded-xl font-semibold text-sm`, primary/secondary/ghost variants | All CTAs |
| **Avatar/initials** | `rounded-xl bg-primary-500 text-white text-sm font-bold shadow-sm` | Profile, team members |
| **Status badges** | `px-2 py-0.5 rounded-full text-[11px] font-medium` | Requests, pets |

---

## Current State — Page-by-Page Audit

### Authenticated Pages

| Page | Route | Current Design Quality | Gaps vs Dashboard |
|------|-------|----------------------|-------------------|
| **Adopter Dashboard** | `/dashboard` | ★★★★★ Reference | — |
| **Shelter Dashboard** | `/shelters/:id/dashboard` | ★★★★☆ High | Onboarding checklist uses gradient (should be flat per DESIGN.md) |
| **Profile Settings** | `/profile/edit` | ★★★☆☆ Medium | `shadow-md` should be `shadow-sm`; no bento-enter animations; no card-lift on interactive elements; empty states missing |
| **Pets Index** | `/pets` | ★★★★☆ High | Filter bar doesn't match dashboard card aesthetic; no micro-interactions on filter chips; card grid is good but could use bento-enter |
| **Pet Show** | `/pets/:id` | ★★★★☆ High | Well-structured; could use more dashboard-level polish on secondary cards |
| **Saved Pets** | `/saved_pets` | ★★★☆☆ Medium | Identical to pets index but no filters section; same polish gaps |
| **Adoption Requests (adopter)** | `/adoption_requests` | ★★★☆☆ Medium | Card layout is clean but lacks dashboard animations; empty state is basic |
| **Adoption Request Show** | `/adoption_requests/:id` | ★★★☆☆ Medium | Timeline section could use better visual treatment; cards are plain |
| **Shelters Index** | `/shelters` | ★★★☆☆ Medium | Filter card is functional but not visually matched; grid cards lack micro-interactions |
| **Shelter Show** | `/shelters/:id` | ★★★☆☆ Medium | Good structure but secondary cards are basic; FAQ section could use better styling |

### Shelter Management Pages (shelter_user role)

| Page | Route | Current Design Quality | Gaps vs Dashboard |
|------|-------|----------------------|-------------------|
| **Shelter Pets Index** | `/shelter/pets` | ★★★☆☆ Medium | Table layout is functional but not dashboard-aligned; filter chips lack polish |
| **Shelter Pet Show** | `/shelter/pets/:id` | ★★★☆☆ Medium | Detail cards are plain; photo gallery is good but could use bento-enter |
| **Shelter Pet New/Edit** | `/shelter/pets/new`, `/shelter/pets/:id/edit` | ★★★☆☆ Medium | Forms are standard; no dashboard-level visual treatment |
| **Shelter Adoption Requests** | `/shelter/adoption_requests` | ★★★☆☆ Medium | Table-based, functional; no empty state animations |
| **Shelter Request Show** | `/shelter/adoption_requests/:id` | ★★★☆☆ Medium | Decision form is basic |
| **Staff Management** | `/shelters/:id/staff` | ★★★☆☆ Medium | Cards are plain; invite form is basic |
| **Shelter Edit** | `/shelters/:id/edit` | ★★★☆☆ Medium | Form layout is clean but lacks dashboard visual treatment |
| **Adoption Policies** | `/shelters/:id/policies/edit` | ★★★☆☆ Medium | Form-based, basic |
| **AI Documents** | `/shelter/ai/documents` | ★★★☆☆ Medium | Basic index/new pages |

### Unauthenticated / Onboarding Pages

| Page | Route | Current Design Quality | Notes |
|------|-------|----------------------|-------|
| **Landing Page** | `/` (via locale) | ★★★★☆ High | Already well-designed (separate scope) |
| **Sign In / Sign Up** | `/login`, `/registration` | ★★★☆☆ Medium | Auth pages — redesign in separate scope with auth flow |
| **Onboarding (adopter)** | `/profile/onboarding` | ★★★☆☆ Medium | Question flow — redesign in separate scope |
| **Onboarding (shelter)** | `/profile/shelter_onboarding` | ★★★☆☆ Medium | Question flow — redesign in separate scope |

---

## Phased Approach

The work is split into **4 phases**, ordered by user impact and dependency. Each phase produces screens in Stitch MCP, implements the approved designs, and includes both locale files and acceptance testing.

### Phase 1: Profile/Settings (Highest user frequency)

**Pages:** `/profile/edit`

This is the most frequently visited non-dashboard page. Every user sees it. It currently has 3–4 stacked cards with `shadow-md` (wrong token) and no micro-interactions.

**Scope:**
- Redesign account info card with bento-card styling
- Redesign preferences card
- Redesign language card
- Redesign shelter info card (shelter users)
- Add `bento-enter`, `card-lift`, `active:scale-[0.97]` to all interactive elements
- Update `shadow-md` → `shadow-sm` per DESIGN.md
- Ensure empty states for users with incomplete profiles
- Add progress/onboarding indicator with dashboard-style progress bar

**Stitch screens needed:**
1. Profile settings — adopter view (all sections visible)
2. Profile settings — shelter view (with shelter info card)
3. Profile settings — onboarding incomplete state (with completion banner)

---

### Phase 2: Pets & Adoption Requests (Adopter Journey)

**Pages:** `/pets`, `/pets/:id`, `/saved_pets`, `/adoption_requests`, `/adoption_requests/:id`

These are the core adopter journey pages after the dashboard. They're already reasonably well-designed but lack dashboard-level polish.

**Scope:**
- **Pets Index:** Redesign filter bar as a bento card; add `bento-enter` animations to pet cards; add `card-lift` hover effects consistent with dashboard
- **Pet Show:** Polish secondary info cards with dashboard card patterns; add micro-interactions to interactive elements
- **Saved Pets:** Apply same polish as pets index; redesign empty state with dashboard-level illustration and animation
- **Adoption Requests Index:** Add `bento-enter` to request cards; improve empty state with illustration
- **Adoption Request Show:** Redesign timeline with visual connector line; add gradient accent cards for status sections

**Stitch screens needed:**
1. Pets index — with results (3-column grid)
2. Pets index — empty state (no results after filter)
3. Pet detail — top section (photo gallery + header)
4. Pet detail — info cards
5. Saved pets — with saved items
6. Saved pets — empty state
7. Adoption requests — with active requests
8. Adoption requests — empty state
9. Adoption request detail — in-progress state
10. Adoption request detail — accepted/declined states

---

### Phase 3: Shelters (Adopter-Facing)

**Pages:** `/shelters`, `/shelters/:id`

Shelters pages are the adopter-facing shelter discovery and detail view. They're functional but need visual alignment.

**Scope:**
- **Shelters Index:** Redesign filter card as dashboard-style bento card; add `bento-enter` to shelter cards; improve empty state
- **Shelter Show:** Redesign contact/location cards as bento cards; add micro-interactions; improve FAQ section
- **Shelter Show — Pets section:** Apply dashboard card patterns to available pets grid

**Stitch screens needed:**
1. Shelters index — with results
2. Shelters index — empty state (no shelters match)
3. Shelter detail — hero/header area
4. Shelter detail — info cards + pets grid

---

### Phase 4: Shelter Management (Shelter Staff Journey)

**Pages:** All `/shelter/*` and `/shelters/:id/staff`, `/shelters/:id/edit`, `/shelters/:id/policies/edit`

These are the shelter staff's daily tools. While functional, they lack the visual polish of the dashboard.

**Scope:**
- **Shelter Pets Index:** Convert table to dashboard-aligned card list or enhanced table with bento styling
- **Shelter Pet Show/Edit:** Redesign detail/info cards; add dashboard-level form styling
- **Shelter Adoption Requests:** Enhanced table with dark header matching dashboard patterns; improve empty states
- **Staff Management:** Redesign card sections; improve invite form with dashboard styling
- **Shelter Edit:** Redesign form with dashboard patterns
- **Adoption Policies:** Redesign form
- **AI Documents:** Polish index/new pages

**Stitch screens needed:**
1. Shelter pets index — with pets
2. Shelter pets index — empty state
3. Shelter pet detail — with photos and actions
4. Shelter pet form (new/edit)
5. Shelter adoption requests — with requests
6. Shelter adoption requests — filtered empty state
7. Staff management — with team members
8. Staff management — with pending invitations
9. Shelter edit form
10. Adoption policies form

---

## Using Stitch MCP

### Stitch Auth Status

**Current:** Stitch MCP client registration is not yet configured. The tools require OAuth-based authentication that isn't set up in this environment.

**Setup Required:**
1. Register a Stitch OAuth application
2. Add credentials to `.env` as `STITCH_CLIENT_ID` and `STITCH_CLIENT_SECRET`
3. Update `opencode.json` with Stitch MCP configuration including auth

### Workflow with Stitch (once configured)

1. **Create a project** — `stitch_create_project` with title "Tovitu Design Unification"
2. **Generate screens** — For each phase, call `stitch_generate_screen_from_text` with:
   - Detailed prompt describing the page content, layout, and design reference
   - Reference to the existing dashboard design system via `designSystem` parameter
3. **Iterate** — Use `stitch_generate_variants` or `stitch_edit_screens` to refine
4. **Design system** — Create/update via `stitch_create_design_system` to match DESIGN.md
5. **Export screens** — Download generated screens as reference for implementation

### Design System Configuration

When configuring Stitch, the design system should be:

```json
{
  "displayName": "Tovitu",
  "theme": {
    "colorMode": "LIGHT",
    "customColor": "#6C30FF",
    "headlineFont": "BALOO_2",
    "bodyFont": "POPPINS",
    "roundness": "ROUND_TWELVE",
    "colorVariant": "VIBRANT",
    "designMd": "[Content of DESIGN.md]"
  }
}
```

---

## Implementation Details

### Design Tokens to Standardize

Every page should use these consistent tokens (from DESIGN.md):

| Token | Value | Usage |
|-------|-------|-------|
| Card background | `bg-white` | All cards |
| Card border | `border border-neutral-200` | All cards |
| Card shadow | `shadow-sm` | All cards at rest (never `shadow-md` or `shadow-lg` except modals) |
| Card radius | `rounded-xl` (12px) | All cards |
| Card padding | `p-6` (24px) | Standard cards |
| Card padding compact | `p-5` (20px) | Compact cards |
| Display font | `font-display` (Baloo 2) | All headings |
| Body font | default (Poppins) | All body text |
| Heading bold | `font-bold` | All h1-h3 |
| Heading semibold | `font-semibold` | h4+, card titles |
| Body text | `text-neutral-600` or `text-neutral-700` | Primary body |
| Muted text | `text-neutral-500` or `text-neutral-400` | Secondary/labels |
| Primary button | `bg-primary-500 text-white font-semibold rounded-xl` | Primary CTAs |
| Primary hover | `hover:bg-primary-600` | Primary button hover |
| Secondary button | `bg-secondary-500 text-white font-semibold rounded-xl` | Secondary CTAs |
| Ghost button | `bg-white border-2 border-primary-200 text-primary-700` | Ghost CTAs |
| Active scale | `active:scale-[0.97]` | All clickable elements |
| Focus ring | `focus-visible:ring-2 focus-visible:ring-primary-500 focus-visible:ring-offset-2` | All interactive |

### Micro-interactions to Propagate

From dashboard's `app/assets/stylesheets/application.css` Tailwind config, add these custom animations/utilities to every page:

1. **`bento-enter`** — Fade-in + translate-up on scroll into view (CSS class, applied to card sections)
2. **`card-lift`** — `hover:-translate-y-0.5 hover:shadow-md` for interactive cards
3. **`image-reveal`** — Scale animation on image load
4. **`score-pop`** — Spring-like entrance animation for numeric badges
5. **`progress-shimmer`** — Shimmer animation on progress bars
6. **`notification-dot`** — Pulsing dot for unread indicators

These should be extracted into a shared utility/component pattern rather than duplicated per-page.

### Empty State Pattern

Every list/index page must have a considered empty state following this pattern:

```erb
<div class="text-center py-16 bg-white rounded-xl border border-neutral-200">
  <div class="w-16 h-16 mx-auto mb-4 rounded-xl bg-primary-50 flex items-center justify-center" aria-hidden="true">
    <!-- SVG icon matching the page context -->
  </div>
  <h3 class="font-display text-xl font-bold text-neutral-700 mb-2"><%= t(".empty_title") %></h3>
  <p class="text-sm text-neutral-500 mb-6 max-w-sm mx-auto"><%= t(".empty_body") %></p>
  <%= link_to t(".empty_cta"), some_path,
      class: "inline-flex items-center gap-2 px-6 py-3 bg-primary-500 text-white font-semibold rounded-xl hover:bg-primary-600 active:scale-[0.97] transition-all duration-200" %>
</div>
```

### Responsive Behavior

All pages must be responsive following the dashboard pattern:
- **Mobile (< 768px):** Single column, full-width cards, stacked sections
- **Tablet (768–1024px):** 2-column grids for index pages
- **Desktop (> 1024px):** 3-column grids for pet/shelter indexes; full layout as designed

---

## Acceptance Criteria

### AC-PH1: Profile/Settings Redesign

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | All cards use `shadow-sm` (not `shadow-md`) | Visual + code review |
| 2 | Interactive elements have `active:scale-[0.97]` and `card-lift` hover | Code review + visual |
| 3 | Cards use `bento-enter` fade-in animation | Visual inspection |
| 4 | Section headers use `font-display text-lg font-bold text-neutral-800` | Code review |
| 5 | Onboarding completion banner uses dashboard-style progress bar | Visual inspection |
| 6 | All form inputs have consistent focus ring (`focus-visible:ring-2 focus-visible:ring-primary-500`) | Code review |
| 7 | Buttons use dashboard button pattern (rounded-xl, padding, font-semibold) | Code review |
| 8 | Settings page is responsive (single column mobile, desktop as designed) | Resize browser |
| 9 | All text uses `t()` — no hardcoded strings | Code review |

### AC-PH2: Pets & Adoption Requests Redesign

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | Pets index filter section is redesigned as bento card matching dashboard style | Visual inspection |
| 2 | Pet cards / request cards use `bento-enter` animation | Visual inspection |
| 3 | Empty states follow dashboard pattern (rounded-xl card, icon, heading, body, CTA) | Visual + code review |
| 4 | Pet show info cards use dashboard card pattern (white bg, neutral-200 border, shadow-sm, p-6) | Code review |
| 5 | Timeline on request show has visual connector lines | Visual inspection |
| 6 | All status badges use consistent pill pattern | Code review |
| 7 | Interactive cards have `card-lift` hover effect | Visual + code review |
| 8 | 44px minimum tap target on all interactive elements | DevTools measurement |

### AC-PH3: Shelters Redesign (Adopter-Facing)

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | Shelters index filter card matches dashboard card aesthetic | Visual inspection |
| 2 | Shelter cards use `bento-enter` and `card-lift` | Visual + code review |
| 3 | Shelter detail contact/location cards use dashboard card pattern | Code review |
| 4 | FAQ section is visually polished (card with proper spacing) | Visual inspection |
| 5 | Available pets grid uses dashboard card patterns | Visual inspection |
| 6 | Empty states for all sections follow dashboard pattern | Visual + code review |

### AC-PH4: Shelter Management Redesign

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | Table-based pages (shelter pets, shelter requests) have consistent header styling | Visual inspection |
| 2 | Filter chips use dashboard pill pattern (rounded-full, active bg-secondary-500) | Code review |
| 3 | Form pages (shelter edit, policies, pet forms) use dashboard card pattern | Code review |
| 4 | All pages have proper empty states for empty data | Visual inspection |
| 5 | All buttons follow dashboard button sizing and styling | Code review |
| 6 | Photo gallery uses `bento-enter` grid with proper spacing | Visual inspection |

### AC-GEN: Cross-cutting

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | All user-facing strings use `t()` or `I18n.t()` — no hardcoded text | Code review |
| 2 | Locale keys exist for both `en.yml` and `es.yml` | File check |
| 3 | All pages render correctly in both English and Spanish | Visual + log inspection |
| 4 | No `shadow-md` or `shadow-lg` on cards (only `shadow-sm` — modals can use `shadow-lg`) | Code review (grep) |
| 5 | No gradient text or gradient backgrounds (except the `bg-gradient-to-br` accent cards per DESIGN.md) | Code review |
| 6 | All interactive elements are keyboard-accessible with visible focus rings | Tab through + visual |
| 7 | Color is never the only indicator of status — text labels accompany all colored badges | Code + visual review |
| 8 | Design tokens are consistent across all pages (spacing, colors, fonts) | Code review |

---

## Spec Assignments

Spec ownership follows agent boundaries per AGENTS.md:

| Phase | Primary Agent | Secondary Agent |
|-------|--------------|-----------------|
| Phase 1: Profile/Settings | **Frontend** | Domain (form validation patterns) |
| Phase 2: Pets & Adoptions | **Frontend** | Domain (pets/adoptions data wiring) |
| Phase 3: Shelters (public) | **Frontend** | Domain (shelter data) |
| Phase 4: Shelter Management | **Frontend** | Domain (management workflows) |

Each phase should produce:
1. Stitch MCP screens (design phase)
2. Updated ERB views (implementation)
3. Updated locale files (i18n)
4. Updated Tailwind utilities if needed
5. Request spec updates for any view changes affecting data display

---

## Risks & Unknowns

### Stitch MCP Authentication
**Risk Level: Medium**
Stitch tools are currently unauthenticated in this environment. If Stitch auth cannot be configured, the fallback is to implement designs directly from the dashboard reference and DESIGN.md without generated screen mockups. The dashboard itself serves as sufficient design spec.

### Design Consistency Enforcement
**Risk Level: Low**
The dashboard code exists as a reference. The main risk is drift — each page being slightly different. Mitigation: extract shared partials/components for repeated patterns (empty states, status badges, card layouts, button variants).

### Tailwind CSS Custom Utilities
**Risk Level: Low**
Micro-interactions (`bento-enter`, `card-lift`, etc.) may need to be defined as custom CSS or Tailwind `@layer utilities`. Check if they're already defined in the Tailwind config or application CSS. If not, define them once in a shared location.

### Shelter User Adoption
**Risk Level: Low**
Shelter management pages currently use tables (pet list, adoption requests). Converting tables to card-based layouts could reduce information density per viewport. Consider keeping tables for management pages but applying dashboard visual patterns (colors, spacing, interactions) rather than full card conversion.

---

## Decision Log

| Decision | Options Considered | Chosen Approach | Rationale |
|----------|-------------------|-----------------|-----------|
| Phase order | (a) By user frequency, (b) By complexity, (c) Alphabetical | By user frequency (Settings → Pets → Shelters → Management) | Highest impact first; Profile is visited by every user |
| Table-to-card conversion for shelter management | (a) Full card conversion, (b) Enhanced table with dashboard styling, (c) Keep as-is | Enhanced table with dashboard styling | Tables remain more functional for data-dense management views; apply colors, spacing, and interaction patterns instead |
| Stitch vs direct implementation | (a) Stitch-first (design in Stitch, then implement), (b) Direct implementation from reference | Stitch-first when available, direct reference implementation as fallback | Stitch provides faster iteration on visual design; but should not block implementation |
| Shared components vs per-page patterns | (a) Extract shared partials, (b) Keep per-page duplication for now | Extract shared partials for repeated patterns | Reduces drift and maintenance; empty states, status badges, and card wrappers are prime candidates for extraction |
| Single PR per phase vs per-page | (a) One large PR per phase, (b) Individual page PRs | One PR per phase | Manageable review size while maintaining coherence within each phase |

---

## Out of Scope

- **Landing page redesign** — Already well-designed; separate scope if needed
- **Authentication pages** (login, registration, password reset) — These follow a different visual pattern (centered card, no sidebar); separate scope
- **Onboarding question flow** — Interactive wizard pattern; separate scope
- **Email templates** — Mailer layouts follow different constraints; separate scope
- **PWA/manifest pages** — Not user-facing in the same sense
- **Design token creation** — No new design tokens; only consistent application of existing ones
- **Animations beyond dashboard patterns** — No new animation types; only propagate existing ones (`bento-enter`, `card-lift`, `image-reveal`, `score-pop`, `progress-shimmer`)
- **Component library extraction** — Not extracting a formal component library; using shared partials at most
- **Accessibility audit beyond dashboard parity** — Match dashboard accessibility level; not performing separate audit
- **Dark mode** — Out of scope for MVP; DESIGN.md specifies light mode only

---

## Summary

This plan defines a 4-phase approach to unify all of Tovitu's authenticated pages under the visual standard established by the dashboard. Each phase targets a coherent set of pages, uses Stitch MCP for design generation (with fallback to dashboard reference), and standardizes design tokens, micro-interactions, empty states, and responsive behavior across the entire application.

The total scope covers approximately **15–20 pages** across all phases. Estimated effort per phase: 2–3 days for design + 3–5 days for implementation = roughly **5–8 days per phase, 20–32 days total** for full unification.
