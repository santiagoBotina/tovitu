# Plan: Adoption Policies Section — Redesign & Design-System Alignment (Story 1.2)

**Domain:** Frontend, Shelter Tools, Design System
**Priority:** 2 (Medium-High)
**Status:** Draft
**Tracks:** Epic "Shelter Experience UI Modernization" (Story 1.2)

---

## Overview

The Adoption Policies page is currently a single-column form squeezed into a narrow container (`max-w-lg`). It does not communicate the purpose of adoption policies, does not distinguish existing policies from the edit action, and visually diverges from the rest of the dashboard.

This plan redesigns the page so that:

- The section clearly explains **what adoption policies are and why they matter**.
- **Existing policies** are presented as structured, readable cards (grouped by intent) instead of a bare form.
- The **edit action** is visually distinct and easy to access.
- Typography, spacing, cards, buttons, borders, interaction states, and empty states match the current Tovitu design system (DESIGN.md "Playground Standard").
- **All existing business logic is preserved** — this is a presentation-layer change.

---

## Current State (confirmed in code)

- **Single edit page:** `app/views/shelters/policies/edit.html.erb` renders one `max-w-lg` form with a back link header (`mb-6`, no top margin) and a single card containing all fields.
- **Domain model:** adoption policies are stored on `Shelter#adoption_policies` (a serialized hash) with a **fixed set of keys**:
  - `adoption_fee` (number), `minimum_age` (number)
  - `fee_description` (text)
  - `home_visit_required`, `fenced_yard_required`, `vet_reference_required` (booleans)
  - `other_requirements` (free text, one per line)
- **Controller:** `Shelters::PoliciesController#edit` / `#update` (Pundit `policies_edit?` / `policies_update?` = shelter admin only). `update` persists the hash and responds with HTML redirect + Turbo Stream (checklist/progress-bar refresh).
- **There is no multi-policy CRUD today** — no create/delete/enable/disable of individual policies. The only capability that exists is editing the fixed policy set.

---

## User Stories

> As a shelter owner,
> I want to see my adoption policies presented clearly and grouped by intent,
> so that I can quickly confirm what adopters will be asked to meet without reading a raw form.

> As a shelter owner,
> I want a single obvious "edit policies" action that opens the existing editing experience,
> so that updating requirements stays fast and familiar.

---

## Requirements & Proposed Behavior

### REQ-42-1 — Structured section with clear purpose

The page must clearly distinguish:

1. **Section title** — "Adoption Policies" (existing heading style).
2. **Description/instructions** — one or two sentences explaining what adoption policies are and that they appear to adopters during the adoption process.
3. **Existing policies** — the configured policy set, displayed as grouped cards (see REQ-42-3).
4. **Edit action** — a clear, prominent action (e.g., "Edit policies") that opens the editing experience.

### REQ-42-2 — Visual hierarchy & design-system consistency

- Use the standardized page-header layout from **plan 41** (navbar → spacing → back nav → title → description → content).
- Cards use the design-system card recipe (white surface, `rounded-xl`, `border-neutral-200`, restrained `shadow-sm`) with `bento-enter` entrance where the rest of the dashboard uses it.
- Buttons: primary button recipe (`bg-primary-500 text-white rounded-xl hover:bg-primary-600`, focus ring) for the primary edit action; ghost/secondary for any secondary actions.
- Typography: `font-display` headings, `text-neutral-*` body per DESIGN.md.
- Responsive across mobile, tablet, desktop.

### REQ-42-3 — Existing policies presented in logical groups

Group the fixed policy set by intent (indicative grouping; validated during implementation):

- **Adoption fee** — `adoption_fee`, `fee_description`.
- **Applicant requirements** — `minimum_age`, `home_visit_required`, `fenced_yard_required`, `vet_reference_required`.
- **Other requirements** — `other_requirements` (rendered as a list, one item per line).

Each group is a card with an icon/title and readable value presentation (e.g., fee shown as currency, booleans as "Required / Not required" chips, other requirements as a bulleted list).

### REQ-42-4 — Edit action

- A single, clearly visible edit action (button/CTA in the header area or per-group "Edit" affordance — one consistent choice).
- Clicking it opens the **existing edit form** (the current `edit.html.erb` content, restyled to the same design system and grouped the same way), preserving the existing save/Turbo Stream behavior and validation.

### REQ-42-5 — Empty & unset states

- When no policy data has been configured (or a group has no values), show an **intentional empty state** consistent with the app: icon + short copy + the edit CTA as the next step.
- Partial data (some fields set, others nil) renders gracefully — unset fields show "Not set" rather than blank or broken markup.

### REQ-42-6 — Preserve business logic

- Same attributes, same `Shelter#adoption_policies` storage, same `update` flow, same Pundit authorization, same Turbo Stream responses, same validation behavior.
- **No new multi-policy CRUD**, no enable/disable toggles for individual policies, no new policy types — the requirement explicitly limits actions to "where these capabilities already exist."

**Edge cases:**

- Shelter with no policies configured at all → full empty state with CTA.
- Shelter with partial policies (e.g., fee set but no requirements) → mixed state: configured groups render values, unset fields show "Not set".
- `other_requirements` with multiple lines → rendered as a list; empty → "Not set".
- Very long free-text values → readable wrapping; no layout breakage.
- Validation failure on save → existing error handling (error summary + retained input) stays; page still matches the design system.
- `minimum_age` / `adoption_fee` edge values (0, nil) → displayed correctly ("No fee", "Not set" as appropriate) without misleading adopters.
- Locale: all new strings localized (en/es); existing keys reused where possible.

---

## Acceptance Criteria

- **AC-42-1** — The Adoption Policies page visually matches the current Tovitu design system (DESIGN.md tokens).
- **AC-42-2** — Typography, spacing, cards, buttons, borders, and interaction states are consistent with the updated dashboard.
- **AC-42-3** — The section has sufficient top spacing from the navbar (via the plan 41 header pattern).
- **AC-42-4** — The page provides a clear visual hierarchy between title, description, content, and actions.
- **AC-42-5** — Empty states are intentional and visually consistent with the application.
- **AC-42-6** — Existing adoption policy functionality continues working without regression (same save flow, Turbo Stream refresh, authorization).
- **AC-42-7** — The page is responsive across mobile, tablet, and desktop viewports.
- **AC-42-8** — No new business logic is introduced (no policy CRUD, no toggles, no new fields) — verified in code review.
- **AC-42-9** — All new/changed strings are localized (en/es); no hardcoded user-facing strings.

---

## Success Metrics

- **Adopter clarity:** no adopter-facing confusion caused by misconfigured/missing policies (founder-reported; qualitative).
- **Shelter confidence:** shelter owners can see their policies at a glance (visual audit + usability check).
- **Consistency:** page matches the dashboard design system with zero divergence found in the design-review pass.
- **Zero regression:** policies request specs continue to pass unchanged (except presentation).

---

## Test Strategy

- **Request specs:** `spec/requests/shelters/policies_spec.rb` continues to pass (edit/update authorization, save behavior, Turbo Stream refresh) — unchanged business behavior.
- **View specs:** page renders title, description, policy groups, values/chips, "Not set" placeholders, empty state, edit action.
- **Manual QA matrix:** configured / partial / empty policy data × mobile/tablet/desktop; both locales; keyboard focus on the edit action.

---

## Scope

**In scope:** restructure of the Adoption Policies page into a grouped, card-based presentation with standardized header (plan 41), clear edit action, intentional empty/unset states; restyle of the existing edit form to the same design system; all presentation-layer only.

**Out of scope:** any change to the policy data model, new policy types, per-policy enable/disable, delete/create of individual policies, changes to adopter-facing rendering of policies, and anything requiring migration. Also out of scope: roles & permissions changes (plan 46) that may later gate policy management.

---

## Risks

- **Scope creep into new policy capabilities** — mitigated by AC-42-8 and the explicit "where these capabilities already exist" constraint.
- **Regression of the Turbo Stream save flow** (checklist/progress-bar refresh on the dashboard) — mitigated by keeping controller/update behavior intact and re-running policies specs.
- **Inconsistent grouping vs. domain semantics** — grouping is presentation-only; the stored structure is unchanged, so no data risk.
- **Design drift** — mitigated by using the shared card/button/header recipes and the design-review pass.

---

## Dependencies

- **Depends on plan 41** (standardized page header + back navigation).
- **Related to plan 44** (dashboard) — policies quick-action links must keep working after the redesign.
- **Related to plan 46** (roles & permissions) — policy management permission becomes role-based later; this plan does not change authorization.
- **Depends on plan 33 conventions** (i18n) already in place — no new dependency.