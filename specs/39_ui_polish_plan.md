# Plan: UI/UX Polish — Dropdown Padding & Section Card Cutoff (REQ-17, REQ-18)

**Domain:** Frontend, Design System
**Priority:** 3 (Low) — quick wins, safe to ship anytime
**Status:** Draft
**Tracks:** Epic "UI/UX Polish" (REQ-17, REQ-18)

---

## Overview

Two small visual defects erode the "Playground Standard" polish (per DESIGN.md):

1. The **dropdown chevron** sits too close to the right edge of the control.
2. The **last pet card** in the "Listo para conocer a alguien" section is cut off at the end of the container.

Both are low-risk, high-visibility fixes. They should be fixed at the **reusable component level**, not patched per instance, and verified across breakpoints.

---

## Current State (confirmed in code)

- **Dropdown component:** a reusable select/dropdown is used across the app (filters, forms, etc.); the chevron's right spacing is insufficient per the design system spacing scale.
- **"Listo para conocer a alguien" section:** a pet-card section (horizontal scroll/row of cards) whose last card is clipped by the section's end padding — the end of the row lacks the breathing room the other edges have.

---

## User Stories

> As a user,
> I want dropdowns to look balanced and aligned to the design system,
> so that the interface feels crafted rather than cramped.

> As a user browsing pets,
> I want to see every card completely, including the last one in a row,
> so that no pet is hidden or cut off.

---

## Requirements & Proposed Behavior

### REQ-17 — Fix dropdown chevron padding

1. Increase the horizontal space between the chevron and the control's right edge.
2. Keep vertical alignment correct.
3. Use the design system's spacing token (per DESIGN.md) so the value is consistent, not a one-off.
4. Apply the fix to the **reusable component** (single source), not a single instance.
5. Verify behavior on desktop and mobile.
6. The change must **not shrink the interactive area** of the dropdown (click target stays at least the current size).

**Edge cases:**
- RTL/other locales: spacing should be symmetric in behavior (chevron side may vary if RTL is ever added).
- Focus states / keyboard: unchanged; padding change must not shift focus ring alignment.
- Selects with long option labels: no text truncation regression.

### REQ-18 — Fix last-card cutoff in "Listo para conocer a alguien"

1. Every pet card in the section is fully visible.
2. The last card is never cut off.
3. The section has the necessary end padding/spacing.
4. Works across screen sizes.
5. If the section uses a carousel/horizontal scroll, the last card must be reachable and fully viewable (scroll end lands with the card fully in view).
6. No unexpected horizontal page overflow is introduced.

**Edge cases:**
- Few cards (fewer than the viewport shows): no awkward empty space; layout still balanced.
- Mobile: horizontal scroll reaches the last card comfortably; end padding visible.
- Keyboard: the last card is focusable and fully revealed when focused (scroll-into-view).
- Reduced motion: no scroll-snap animation regressions.
- Section with exactly one card: fully visible, no clipping.

---

## Acceptance Criteria

- **AC-39-1 (REQ-17)** — The dropdown chevron has increased horizontal space from the right edge.
- **AC-39-2 (REQ-17)** — Vertical alignment of the chevron is correct.
- **AC-39-3 (REQ-17)** — The padding uses the design-system spacing scale (consistent with DESIGN.md), not an ad-hoc value.
- **AC-39-4 (REQ-17)** — The fix lives in the reusable component; all dropdown instances inherit it.
- **AC-39-5 (REQ-17)** — Desktop and mobile render correctly; the interactive area of the dropdown is not reduced.
- **AC-39-6 (REQ-18)** — All cards in "Listo para conocer a alguien" are fully visible, including the last one.
- **AC-39-7 (REQ-18)** — The section has proper end padding across screen sizes.
- **AC-39-8 (REQ-18)** — For a carousel/horizontal-scroll layout, scrolling to the end leaves the last card fully in view.
- **AC-39-9 (REQ-18)** — No unexpected horizontal page overflow is introduced on any breakpoint.
- **AC-39-10** — No user-visible strings change (no new i18n keys required; existing keys reused if any).

---

## Success Metrics

- **Visual consistency**: no dropdown instances with cramped chevrons remain (visual audit).
- **Zero regression**: all interactive areas unchanged; no horizontal overflow on home/dashboard pages across breakpoints (automated + manual check).
- **QA sign-off**: design review passes on the Playground Standard bar.

---

## Test Strategy

- **View/component checks**: the reusable dropdown renders the corrected padding; the section renders end padding.
- **Manual QA matrix**: desktop (multiple widths) + mobile for the section; dropdowns across the app (filters, forms, settings).
- **Layout regression check**: no `overflow-x` regressions on the pages containing the section.

---

## Scope

**In scope:** chevron padding fix in the reusable dropdown component; end-padding/scroll-end fix for the "Listo para conocer a alguien" section.

**Out of scope:** Any new animation or restyle of dropdowns; redesign of the section; other card sections (only if they exhibit the same bug, the fix pattern should be applied at the shared level).

---

## Risks

- **Low risk** — visual-only changes; the main risks are (a) patching one instance instead of the shared component (mitigation: AC-39-4) and (b) introducing horizontal overflow while fixing the section (mitigation: AC-39-9 + regression checks).
- **Scroll-snap interactions** — if the section uses scroll-snap, adjusting end padding must not change snap behavior; verify with reduced-motion and keyboard.

---

## Dependencies

- None. Safe to schedule in any order; ideal as a final polish pass after plans 33–38 (so newly added components are audited for the same patterns).