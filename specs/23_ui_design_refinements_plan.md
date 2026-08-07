# Plan: UI / Design Refinements (Bugs 4.1 – 4.3)

**Domain:** Frontend, Design System, Authentication
**Priority:** 3 (visual polish; no functional impact)
**Status:** Draft
**Tracks:** Bug report §4 (UI / Design)

---

## Overview

Three visual defects were reported:

- **4.1** The Verified badge doesn't match the design language (pill shape, placement).
- **4.2** The language selector uses the browser's native dropdown instead of a custom Tovitu control.
- **4.3** Login page branding: the Individual icon is perceived as green (green is reserved for Shelter); needs purple for Individual plus branded artwork.

All changes must honor `DESIGN.md` (Playground Standard, WCAG AA, no decorative gradients/glass).

---

## Bug 4.1 — Verified badge redesign

### Current State (confirmed in code)

The "Verified" indicator in `app/views/authentication/profiles/edit.html.erb:69–75` is a **fully rounded pill**:

```erb
<span class="inline-flex items-center gap-1 px-2.5 py-1 text-xs font-semibold rounded-full bg-success/10 text-success">
  <svg .../> <%= t(".verified") %>
</span>
```

There is also a WhatsApp-verified pill in `app/views/notification_preferences/edit.html.erb:60–63` (same pill style) — the plan's component should cover both.

### Expected Behavior

- Keep the existing **colors** (`bg-success/10 text-success`).
- Keep the current **verification check icon**.
- Make the badge more **rectangular/squared** (e.g., `rounded-md`/`rounded-lg` instead of `rounded-full`).
- Display it in the **upper-right corner** of the component where it appears (currently it sits inline next to the email field).

### User Story

> As a verified user,
> I want the Verified badge to look like a deliberate, squared badge in the top-right of my profile card,
> so that the status is recognizable at a glance and consistent with the design system.

### Proposed Changes

1. **Extract a shared partial** `app/views/shared/_verified_badge.html.erb`:
   - Props: `label` (default `t("shared.verified_badge")`), optional `extra_class`.
   - Squared shape: `rounded-lg` (per DESIGN.md card radius convention), keep `bg-success/10 text-success`, keep the check icon, `text-xs font-semibold`.
   - Accessible: `role="status"` or `aria-label`.
2. **Apply in `profiles/edit.html.erb`**:
   - Move the badge to the **upper-right corner** of the Account Info card (e.g., in the card header row, aligned right).
   - Keep the `verified?` / `pending` logic (pending state keeps a similar squared warning badge for symmetry, if it exists).
3. **Apply in `notification_preferences/edit.html.erb`** (WhatsApp verified): same squared component, upper-right of its card.
4. **Audit for other "Verified" badges** (grep `verified`, `bg-success`): replace any remaining pill-shaped verified badges with the shared component.
5. **i18n**: `shared.verified_badge` in en/es; reuse existing strings where possible.

### Acceptance Criteria (4.1)

- **AC-4.1-1** Verified badge renders as a squared (non-pill) badge.
- **AC-4.1-2** Colors (`bg-success/10 text-success`) and check icon unchanged.
- **AC-4.1-3** Badge appears in the upper-right corner of the profile Account Info card.
- **AC-4.1-4** WhatsApp-verified badge uses the same component/style.
- **AC-4.1-5** No pill-shaped verified badges remain.

---

## Bug 4.2 — Language selector redesign

### Current State (confirmed in code)

`app/views/authentication/profiles/edit.html.erb:131–133` uses the native select:

```erb
<%= f.select :locale, options_for_select([["English", "en"], ["Español", "es"]], ...), {}, class: "w-full px-4 py-3 border ..." %>
```

### Expected Behavior

A **custom language selector** consistent with the Tovitu Design System (Playground Standard): bold, unambiguous, large targets, keyboard accessible, no native dropdown chrome.

### User Story

> As a user changing my language,
> I want a custom, on-brand language selector,
> so that the control feels native to Tovitu and works with keyboard and screen readers.

### Proposed Changes

1. **Build a custom selector component** (Stimulus controller, e.g., `language-select`):
   - Trigger button styled like the design-system buttons (border `neutral-300`, `rounded-xl`, focus ring `primary-500`, `h-10+` target).
   - Shows current locale label + a chevron.
   - Popover/menu listing languages (English, Español) with active state highlighted (primary-500 fill + white text per DESIGN.md filter-chip active convention).
   - Keyboard: button toggles menu, arrow keys move, Enter selects, Escape closes; `aria-haspopup="listbox"`/`aria-expanded`; role listbox/option.
   - Click-outside closes; respects `prefers-reduced-motion` (simple fade/scale from existing patterns).
2. **Wire submission**: selecting an option submits the existing profile `locale` form (PATCH `profile_path`) — preserve current behavior of saving locale with the account; no new endpoint.
3. **i18n**: strings under `shared.language_selector.*` (e.g., `aria_label`, `trigger`, `english`, `español`) — note `English`/`Español` may stay as language-native labels per convention.
4. **Placement**: replaces the `f.select` block inside the Language Preference card; keep the existing save button OR auto-save on selection (choose auto-save-on-select for a cleaner control, matching "selecting a language applies it immediately" mental model — confirm with founder before implementing; default recommendation: auto-save).

### Acceptance Criteria (4.2)

- **AC-4.2-1** Language Preference card shows a custom selector, not a native `<select>`.
- **AC-4.2-2** Selecting a language updates the UI and persists the locale to the user profile (en/es verified).
- **AC-4.2-3** Fully keyboard-operable (open, navigate, select, close) with visible focus rings.
- **AC-4.2-4** Screen reader announces the control as a listbox with the current selection.
- **AC-4.2-5** Matches DESIGN.md styling tokens (no new colors/radii outside the system).

---

## Bug 4.3 — Login page branding improvements

### Current State (confirmed in code)

- Individual login icon: `app/views/authentication/sessions/_individual_form.html.erb:2–5` → `bg-primary-50` / `text-primary-500` (**purple** — already the individual color in the current palette).
- Shelter login icon: `_shelter_form.html.erb:2–4` → `bg-secondary-50` / `text-secondary-500` (**teal/green** — already the shelter color).
- Palette (DESIGN.md + `app/assets/tailwind/application.css`): `primary` = purple `#6C30FF`, `secondary` = teal `#00C9A7`.

> **Note:** The report claims the Individual icon is green. The current code already uses purple for Individual and teal for Shelter, so the report may predate the palette refactor (commit `83b0f9d refactor: color palette`) or refer to a specific asset. **Verify visually during implementation**; if any green (`secondary`/`green-*`) is still applied to Individual assets, correct it to purple. The remaining asks — branded illustrations and a subtle Tovitu logo background — are implemented regardless.

### Expected Behavior

- Individual accounts use the **purple** palette everywhere on login.
- Shelter accounts keep **green/teal**.
- The login page has branded illustrations/icons and a subtle repeating Tovitu logo background (or equivalent branded artwork) — decorative only, respecting reduced motion and contrast.

### User Story

> As a visitor choosing how to log in,
> I want the login page to look unmistakably Tovitu — purple for me as an individual, teal for shelters, with playful branded artwork,
> so that the brand personality carries through the first screen I see.

### Proposed Changes

1. **Verify + fix role color mapping**:
   - Audit all auth views (`_individual_form`, `_shelter_form`, `_adopter_form`, `_role_toggle`, registration) for icon colors. Ensure Individual/adopter = `primary` (purple); Shelter = `secondary` (teal). Fix any `green-*`/`secondary` usage on Individual assets.
2. **Add branded illustration/icons**:
   - Use existing brand assets (logo SVG at `public/assets/tovitu-*.svg`, the onboarding mascot geometry in `onboarding/shelter/questions/show.html.erb:28–53` as inspiration) to create a small login-page illustration or accent icon set for the Individual and Shelter panels.
   - Keep it flat/geometric per DESIGN.md (no gradients except existing brand-safe ones, no glass).
3. **Subtle repeating logo background**:
   - Add a low-opacity repeating Tovitu paw/logo pattern behind the login card (CSS background, `background-image` with an inline SVG data-URI or a CSS pattern), kept subtle (e.g., `opacity` low, `aria-hidden="true"`).
   - Must not hurt contrast of the form (WCAG AA); pattern behind the card, not over text.
   - Respect `prefers-reduced-motion` (static pattern only).
4. **i18n**: any new aria/copy strings in en/es.

### Acceptance Criteria (4.3)

- **AC-4.3-1** Individual login icon/panel uses purple (`primary`); no green on Individual assets.
- **AC-4.3-2** Shelter login icon/panel uses teal (`secondary`).
- **AC-4.3-3** Login page includes branded illustration/icon(s) consistent with the Playground Standard.
- **AC-4.3-4** A subtle repeating Tovitu logo/paw background is present, `aria-hidden`, and does not reduce form contrast.
- **AC-4.3-5** No regression to role-toggle behavior or form layout at mobile width.

---

## Success Metrics

- Verified badge recognized in a visual QA pass (screenshot review).
- Language selector usable via keyboard + screen reader (manual QA + a11y check).
- Login page screenshot matches DESIGN.md brand direction (founder/design review).

## Test Strategy

- View-level specs for the new partials (`shared/verified_badge`, `shared/back_link` if reused) and language-select Stimulus controller behavior (JS unit test if the repo has JS test infra; otherwise manual QA checklist).
- System/manual QA: verified badge placement, language switch en↔es, login page on mobile/desktop.
- No request-spec changes expected (no controller behavior changes) except locale keys.

## Scope

**In scope:** verified badge component + placements; custom language selector; login branding (colors, illustration, subtle background).

**Out of scope:** redesigning the whole login flow; changing the locale persistence model; new brand illustration files beyond what the design system already implies.

## Risks

- A custom language selector adds JS complexity; keep it dependency-free (plain Stimulus) and degrade gracefully (form still works if JS fails — keep the native `<select>` inside the custom popover as a fallback OR ensure the profile form submit still posts the selected value).
- The repeating logo background could read as noise — keep opacity very low (≤ 5–8%) and test on both light surfaces.
