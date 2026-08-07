# Plan: Navigation & UX Improvements (Bugs 3.1 – 3.3)

**Domain:** Frontend, Navigation, Design System
**Priority:** 2 (UX polish; no data loss or crashes)
**Status:** Draft
**Tracks:** Bug report §3 (Navigation & UX)

---

## Overview

Three navigation/UX inconsistencies were reported:

- **3.1** Shelter profile sections lack a consistent back button (the only "Back" today is at the bottom of the Settings page).
- **3.2** The sidebar collapse button lives in the top navigation bar instead of inside the sidebar.
- **3.3** The Settings icon looks like a sun/theme-toggle rather than a gear.

All three are presentational/structural changes; no backend behavior changes are expected. All changes must honor `DESIGN.md` (Playground Standard) and WCAG AA (keyboard, focus rings, aria labels).

---

## Bug 3.1 — Missing/Inconsistent Back button in Shelter sections

### Current State (confirmed in code)

- `app/views/authentication/profiles/edit.html.erb:161–169` — the Settings page places **Back** at the **bottom** of the page.
- `app/views/shelters/edit.html.erb:6–9` — Shelter Information edit has an **icon-only** back square in the header (no label).
- `app/views/shelters/policies/edit.html.erb:6–9` — Policies edit has the same **icon-only** back square.
- `app/views/shelters/staff/index.html.erb:6–9` — Staff page has the same **icon-only** back square.
- `app/views/shelters/show.html.erb:6–10` — Public shelter page has a **labeled** back link at top-left ("Back" + chevron) and a duplicate at the bottom (lines 183–189).

Result: patterns differ across pages (labeled vs icon-only vs bottom placement) and the Settings page's back action is not in the top-left.

### Expected Behavior

- A consistent, labeled **Back** control at the **top-left** of every shelter profile/settings section.
- The existing bottom Back on the Settings page moves to the top-left and matches the app-wide pattern.
- Keyboard accessible, with a clear focus ring (per DESIGN.md focus convention).

### User Story

> As a shelter owner navigating settings,
> I want a predictable Back button in the top-left of every section,
> so that I always know how to return to the dashboard or previous page.

### Proposed Changes

1. **Create a shared partial** `app/views/shared/_back_link.html.erb`:
   - Props: `path`, optional `label` (defaults to `t("shared.back")`).
   - Renders the labeled chevron-back pattern used in `shelters/show.html.erb` (icon + text, top-left).
2. **Apply the partial** to:
   - `authentication/profiles/edit.html.erb` — replace the bottom Back block with the top-left partial (back to dashboard/root; keep existing destination semantics).
   - `shelters/edit.html.erb` — replace icon-only square with the labeled partial (back to shelter dashboard).
   - `shelters/policies/edit.html.erb` — same (back to shelter dashboard).
   - `shelters/staff/index.html.erb` — same (back to shelter dashboard).
3. **Remove the duplicate bottom back** in `shelters/show.html.erb` (keep the top-left one) for consistency — or keep both only if the duplicate is a deliberate affordance; decide during implementation, defaulting to a single top-left control.
4. **Check other shelter-scoped pages** (`shelter/pets/*`, `shelter/adoption_requests/*`, notification preferences) and add the same top-left back control where missing, so the whole shelter area is consistent.
5. **i18n**: add `shared.back` if not present in `config/locales/{en,es}.yml`.

### Acceptance Criteria (3.1)

- **AC-3.1-1** Settings page (profile edit) shows a labeled Back at top-left; bottom back removed.
- **AC-3.1-2** Shelter Information edit, Policies edit, and Staff pages show the same labeled Back at top-left.
- **AC-3.1-3** Every shelter-scoped section has exactly one visible Back control (no duplicates).
- **AC-3.1-4** Back control is keyboard-focusable with a visible focus ring and an accessible name.
- **AC-3.1-5** No page layout regressions at mobile (≤768px) and desktop widths (manual check).

---

## Bug 3.2 — Sidebar collapse button placement & icon

### Current State (confirmed in code)

- The collapse/expand toggle is the hamburger button in `app/views/shared/_navbar.html.erb:7–13` (`data-action="click->sidebar#toggle"`), visible for signed-in users on all breakpoints.
- The sidebar itself (`app/views/shared/_sidebar.html.erb`) already has a **mobile-only** close button (lines 14–22) but no desktop collapse control inside the sidebar.
- `app/javascript/controllers/sidebar_controller.js` already implements `toggleDesktop`, `expand`, `collapse` with `md:w-16` / `md:w-64` and persists state in `localStorage`.

### Expected Behavior

- The collapse/expand control lives **inside the sidebar**, positioned in the **upper-right corner** of the sidebar.
- It uses a clean collapse/expand icon (e.g., chevrons `«`/`»` or panel-left icons) rather than the hamburger.
- On mobile, the existing mobile close button remains (or is unified with the new control, keeping mobile behavior intact).

### User Story

> As a signed-in user,
> I want the sidebar to collapse itself with a control that lives in the sidebar,
> so that the top navigation bar stays clean and the collapse action is where my eye expects it.

### Proposed Changes

1. **Add a desktop collapse/expand button** inside `_sidebar.html.erb`:
   - Position: absolute/flex at the **top-right** of the `<aside>` (e.g., in the logo/brand row, right-aligned), visible on `md:` screens.
   - Icon: use a panel/chevron icon — when expanded show a left-collapse chevron (`«` or `panel-left-close`); when collapsed show a right-expand chevron (`»` or `panel-left-open`). Update the icon based on the expanded/collapsed state via a Stimulus target class toggle.
   - Wire to `sidebar#toggleDesktop` (existing action) or `collapse`/`expand` directly.
   - `aria-label` (`t("shared.sidebar.collapse")` / `t("shared.sidebar.expand")`) updated with state.
2. **Remove the hamburger toggle** from `_navbar.html.erb` on desktop; keep a mobile hamburger if needed to open the drawer (the sidebar is `-translate-x-full` on mobile, so a mobile opener in the navbar is still required — keep the navbar button for mobile only, e.g., `md:hidden`).
3. **Update `sidebar_controller.js`**: add targets for the collapse button + icon and a method to swap icon/aria state on `expand`/`collapse`/`restoreState`.
4. **CSS**: ensure the button doesn't overlap the logo at `md:w-16` (collapsed) width; consider `md:justify-center` when collapsed.
5. **i18n**: `shared.sidebar.collapse` / `shared.sidebar.expand` strings in en/es.

### Acceptance Criteria (3.2)

- **AC-3.2-1** A collapse/expand control is visible inside the sidebar's upper-right corner on desktop (≥768px).
- **AC-3.2-2** Clicking it collapses the sidebar to `md:w-16` and expands back to `md:w-64`, preserving the existing `localStorage` persistence.
- **AC-3.2-3** The icon is a clean collapse/expand glyph, not the hamburger; it swaps direction based on state.
- **AC-3.2-4** The navbar no longer shows the desktop hamburger (mobile drawer opener still present).
- **AC-3.2-5** Keyboard accessible with focus ring; `aria-expanded`/labels reflect state.
- **AC-3.2-6** No regression to mobile drawer open/close behavior.

---

## Bug 3.3 — Settings icon redesign

### Current State (confirmed in code)

The Settings icon is a **sun** (circle + 8 rays) in:
- `app/views/shared/_sidebar.html.erb:234–236`
- `app/views/shared/_navbar.html.erb:100–102` (profile dropdown menu item)

It reads as a light-mode/theme toggle.

### Expected Behavior

Replace with a standard **gear/settings** icon in both locations, consistent with the design system (stroke width 2, same sizing `w-4 h-4` / `w-5 h-5`, same color treatment).

### Proposed Changes

1. Replace the sun SVG path with a gear icon (e.g., Lucide-style `settings` gear: `<path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/>`).
2. Keep color/active-state classes identical to current usage (`icon_active` / `icon_inactive`).
3. Check for any other sun icon misused as Settings (grep for the sun path `M12 1v2` etc.) and replace.

### Acceptance Criteria (3.3)

- **AC-3.3-1** Sidebar Settings link shows a gear icon.
- **AC-3.3-2** Navbar profile dropdown Settings item shows a gear icon.
- **AC-3.3-3** No sun/theme icon remains in Settings contexts.
- **AC-3.3-4** Active/inactive color treatment unchanged.

---

## Success Metrics

- 100% of shelter-scoped pages have a top-left back control (audit checklist).
- No "lost" navigation complaints from QA pass on the settings area (manual).
- Settings icon recognized as settings (visual QA, screenshot review against DESIGN.md).

## Test Strategy

- Mostly visual/UX: manual QA checklist across breakpoints; no request-spec changes expected except locale strings if added.
- If a `back_link` helper/partial is introduced, add a view-level spec (e.g., `spec/views/shared/back_link_spec.rb`) for required label/path rendering.
- Run `bin/rails test`/spec suite to ensure no routing/helper regressions.

## Scope

**In scope:** shared back-link partial + adoption across shelter sections; sidebar collapse control inside sidebar; gear icon swap.

**Out of scope:** redesigning the sidebar layout/content; changing collapse persistence model; other iconography outside Settings/back/collapse.

## Risks

- Moving the collapse button could confuse muscle memory briefly; keep the mobile drawer opener in the navbar to avoid losing the mobile entry point.
- The gear SVG must match existing stroke conventions (24x24, stroke-width 2, currentColor) to avoid visual inconsistency.
