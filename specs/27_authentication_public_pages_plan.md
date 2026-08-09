# Plan: Authentication & Public Pages Branding and Polish (Items 1.1 – 1.3)

**Domain:** Frontend, Authentication, Design System
**Priority:** Mixed (1.3 = High; 1.1 = Medium; 1.2 = Low / visual polish)
**Status:** Draft
**Tracks:** Product Improvements §1 (Authentication & Public Pages)

---

## Overview

Three items in the authentication/public surface:

- **1.1** Replace authentication icons with Tovitu branding (Login + Sign Up pages).
- **1.2** Remove the navbar border on unauthenticated/public pages.
- **1.3** Fix authentication page colors — Individual = purple (`primary`), Shelter = teal/green (`secondary`), throughout the flow.

All changes must honor `DESIGN.md` (Playground Standard), the multi-color logo rule, WCAG AA, and the auth-specific conventions already established in `23_ui_design_refinements_plan.md` (bug 4.3).

---

## Item 1.1 — Replace authentication icons with Tovitu branding

### Problem

The Login and Sign Up pages present an identity that doesn't match the application's branding. The Sign Up page (`app/views/authentication/registrations/new.html.erb`) has **no brand mark at all** — it renders the role toggle, a heading, and the form with no logo or mascot. The Login page (`app/views/authentication/sessions/new.html.erb`) shows a geometric **cat-dog hybrid mascot SVG** + "Tovitu" wordmark, which reads more like a generic cat icon than the official Tovitu logo mark.

The official brand mark exists as a shared partial — `app/views/shared/_logo.html.erb` — which renders the full vectorized Tovitu logo (purple gradient paw/roundel with yellow accents). This is the signature element DESIGN.md explicitly permits and encourages: *"Do use the multi-color logo as a signature element."*

### Business Value

Authentication is the first branded moment for every new visitor. Consistent, unmistakable branding on Login/Sign Up builds trust and reinforces the playful, bold identity before a user even creates an account. It reduces the "generic pet app" perception and strengthens conversion to sign-up.

### User Story

> As a new visitor arriving at the Login or Sign Up page,
> I want to see the official Tovitu logo treated consistently with the rest of the app,
> so that I immediately recognize the brand and feel I'm in a polished, cohesive product.

### Current State (confirmed in code)

- **Login** (`authentication/sessions/new.html.erb:12–32`): inline geometric cat-dog mascot SVG (`circle` head, ear triangles, teal nose) + `font-display text-2xl font-extrabold ... text-primary-600` "Tovitu" wordmark. Also has a `login-paw-pattern` decorative background (already implemented per plan 23, bug 4.3).
- **Sign Up** (`authentication/registrations/new.html.erb`): no logo, no mascot — plain form card with role toggle.
- **Official logo partial** (`app/views/shared/_logo.html.erb`): full vector logo, used in `_navbar.html.erb:17` and `_sidebar.html.erb:29` with `class_name` sizing (`w-7 h-7`, `w-9 h-9`).
- The role-toggle icons (heart for individual, building for shelter) in `authentication/_role_toggle.html.erb` are functional role indicators — **not** in scope for replacement; they communicate role choice, not brand.

### Expected Behavior

- The Login page shows the **official Tovitu logo** (the `shared/logo` partial, or an auth-sized variant of the same mark) as the primary brand element, following the same visual treatment used in the navbar/sidebar.
- The Sign Up page shows the **same** brand element so both auth entry points are visually consistent.
- The wordmark may remain as an accompanying lockup (logo + "Tovitu" in `font-display`), consistent with navbar usage — but the icon itself must be the official mark, not the cat-dog mascot.

### Proposed Changes

1. **Create an auth brand lockup partial** `app/views/shared/_auth_brand.html.erb` (or reuse inline pattern):
   - Renders `shared/logo` (e.g., `w-12 h-12` or `w-14 h-14`) + optional "Tovitu" wordmark beneath or beside it.
   - Single source of truth so Login and Sign Up stay consistent.
   - If the mascot has emotional value, it may be kept as a *secondary decorative accent* (e.g., small, `aria-hidden`, corner motif) — but the **primary** brand element is the official logo. Decision to record at implementation; default recommendation: primary = official logo only.
2. **Apply to Login** (`sessions/new.html.erb`): replace the inline mascot SVG + wordmark block with the shared lockup partial. Keep the existing `login-paw-pattern` background.
3. **Apply to Sign Up** (`registrations/new.html.erb`): add the same shared lockup partial above the role toggle.
4. **Consistency sweep**: check `passwords/new.html.erb`, `passwords/check_email.html.erb`, `verifications/*`, `registrations/check_email.html.erb` — add the brand lockup to any of these that act as standalone auth pages and currently lack it (recommend: password reset pages get it; verification/check-email pages at minimum keep consistent headers). Keep scope tight: the two primary pages first, then the flow pages that visually "stand alone".
5. **i18n**: no new strings required if the lockup is purely visual (`alt`/`aria-label` for the logo should be `t("shared.logo_alt")` if it exists, else add en/es).

### Acceptance Criteria (1.1)

- **AC-1.1-1** Login page primary brand element is the official Tovitu logo (via `shared/logo` partial), not the cat-dog mascot.
- **AC-1.1-2** Sign Up page shows the same brand lockup as Login.
- **AC-1.1-3** The lockup matches the visual treatment used in navbar/sidebar (same mark, `font-display` wordmark where present).
- **AC-1.1-4** Logo is accessible (decorative `aria-hidden` OR meaningful alt in en/es, consistent with navbar usage).
- **AC-1.1-5** Role-toggle and form functionality unchanged; no layout regressions at mobile width.

---

## Item 1.2 — Remove navbar border for unauthenticated users

### Problem

The navigation bar displays a bottom border on public/unauthenticated pages, which adds visual noise to the landing page and makes the public surface feel like an internal app chrome rather than a marketing entry point.

### Business Value

The public homepage should feel open and inviting — a landing experience — not like a logged-in app shell. Removing the border on unauthenticated pages is a small polish change that improves the perceived finish of the first impression.

### Current State (confirmed in code)

`app/views/shared/_navbar.html.erb:1`:

```erb
<header class="sticky top-0 z-20 bg-white/80 backdrop-blur-md <%= signed_in? ? "border-b border-neutral-200/60" : "" %>">
```

**The conditional border is already implemented** — the border only renders when `signed_in?` is true. This item appears to be **already resolved in the current codebase**.

### Expected Behavior

- No border on the navbar for unauthenticated users.
- Border present (as today) for signed-in users.
- No other visual regression.

### Proposed Changes

1. **Verify at runtime** (screenshot/visual QA): load `/` (landing) and `/sessions/new` logged out; confirm no `border-b` renders. The code path is correct, so this is verification + regression guard.
2. **If a border still appears** on any public page, find the source (likely a page-specific header or a different layout wrapping the navbar) and remove it only on unauthenticated routes.
3. **Add a view-level spec or system spec assertion** (if not present) that the navbar `header` has no `border-b` class when signed out, to lock the behavior.

### Acceptance Criteria (1.2)

- **AC-1.2-1** Unauthenticated navbar renders without a bottom border on landing, login, sign-up, and pets-browse pages.
- **AC-1.2-2** Signed-in navbar still renders the bottom border.
- **AC-1.2-3** No layout shift or height change on the navbar.

---

## Item 1.3 — Fix authentication page colors

### Problem

Authentication pages have color inconsistencies: some elements on the Individual side may use green/teal (the Shelter color) and vice versa, and the two account types don't consistently use their assigned palettes across the full flow (login → sign-up → password reset → verification → check-email).

### Business Value

Color is the primary way users distinguish "this is the individual (adopter) experience" from "this is the shelter experience." Consistency here prevents confusion about which account type a user is signing into and reinforces the DESIGN.md palette discipline (purple = individual/adopter, teal = shelter).

### Current State (confirmed in code)

The palette mapping is **mostly correct** in the primary flows:

- **Individual login** (`sessions/_individual_form.html.erb`): icon `bg-primary-50 text-primary-500` (purple) ✅; submit button `bg-primary-500` (purple) ✅.
- **Adopter login** (`sessions/_adopter_form.html.erb`): same purple mapping ✅.
- **Shelter login** (`sessions/_shelter_form.html.erb`): icon `bg-secondary-50 text-secondary-500` (teal) ✅; submit `bg-secondary-500` (teal) ✅.
- **Role toggle** (`authentication/_role_toggle.html.erb`): individual = `bg-primary-500`, shelter = `bg-secondary-500` ✅.
- **Remaining inconsistencies found:**
  - `sessions/_shelter_form.html.erb:27` — "Forgot password?" link uses `text-primary-600 hover:text-primary-800` (**purple on a Shelter page**). Should be `text-secondary-600/700` for role coherence (or neutral — decision at implementation; default: use the role palette).
  - **Password reset pages** (`passwords/new.html.erb`, `passwords/edit.html.erb`, `passwords/check_email.html.erb`) and **verification pages** (`verifications/*`) are role-agnostic but render **purple-only** buttons/icons. Since password reset and verification are shared flows for both roles, neutral or purple is acceptable — but **no teal should appear on them** (none does today). Recommend keeping them **purple** (brand default) and documenting that choice.
  - `registrations/check_email.html.erb`, `verifications/*` — purple ✅.
- No green/teal was found on Individual-only pages in the current code. The remaining risk is **un-audited views** (profiles, new_* entry points, legacy `new_adopter.html.erb`/`new_individual.html.erb`/`new_shelter.html.erb` shims).

### Expected Behavior

- Individual/adopter flow: purple (`primary-*`) only for brand accents, buttons, icons, and backgrounds.
- Shelter flow: teal/green (`secondary-*`) for brand accents, buttons, icons, and backgrounds.
- No component on an Individual page uses `secondary`/teal, and no component on a Shelter page uses `primary`/purple — except where DESIGN.md explicitly allows cross-role brand usage (e.g., the multi-color logo, neutral links).
- Buttons, icons, backgrounds, and focus rings follow the Tovitu Design System for each role.

### Proposed Changes

1. **Fix `sessions/_shelter_form.html.erb:27`**: change the forgot-password link to `text-secondary-600 hover:text-secondary-700` (match role palette) or neutral-600 (consistent with role-agnostic links) — default recommendation: `text-secondary-600 hover:text-secondary-700` for shelter-flow coherence.
2. **Audit the full auth flow** for palette violations (grep `text-primary|bg-primary|text-secondary|bg-secondary` across `app/views/authentication/**` and `app/views/notification_preferences/**` if reachable pre-login):
   - Individual/adopter pages must contain zero `secondary-*` accent classes on interactive/brand elements.
   - Shelter pages must contain zero `primary-*` accent classes on interactive/brand elements (except the shared logo and neutral links).
3. **Role-agnostic pages** (password reset, verification, check-email): keep the **purple** brand default; add a comment or locale note documenting this is intentional (shared flows don't map to a single role).
4. **Verify legacy shims** (`new_adopter.html.erb`, `new_individual.html.erb`, `new_shelter.html.erb` render templates) — they delegate to `sessions/new`, so they inherit the fix automatically.
5. **i18n**: no new strings needed for color changes.

### Acceptance Criteria (1.3)

- **AC-1.3-1** No `secondary`/teal color is used on any Individual/adopter auth element (icon, button, background, link).
- **AC-1.3-2** No `primary`/purple color is used on any Shelter auth element (icon, button, background, link) — excluding the shared logo and neutral links.
- **AC-1.3-3** Shelter login "Forgot password" link uses the shelter palette (or neutral — recorded decision).
- **AC-1.3-4** Role-agnostic auth pages (password reset, verification, check-email) use the purple brand default consistently.
- **AC-1.3-5** Full auth flow screenshot audit passes against DESIGN.md for both roles (founder/design review).

---

## Success Metrics

- Login and Sign Up screenshots match the DESIGN.md brand direction and the official logo usage (design/founder review).
- Auth palette audit (grep-based) returns zero violations for both roles.
- Public navbar renders borderless logged-out; border retained logged-in (visual QA).
- No regression in auth functionality (login, sign-up, reset, verify) at mobile/desktop widths.

## Test Strategy

- **View-level specs**: for the new `_auth_brand` partial (logo + wordmark rendered; accessible).
- **System/manual QA**: logged-out navbar border absent; login/sign-up pages show official logo; screenshot review for both roles across the auth flow (en + es).
- **Request specs**: unchanged (no controller behavior changes) except any locale keys added.
- **Grep-based audit** as a QA gate: `rg "secondary" app/views/authentication/sessions/_individual_form.html.erb` etc. must be empty for role-mismatched pages.

## Scope

**In scope:** shared auth brand lockup; applying official logo to Login + Sign Up; removing navbar border (verification + lock); palette fixes in the auth flow (role-mapped accents), including the shelter forgot-password link and full-flow audit.

**Out of scope:** redesigning the auth layout/flow; changing the role-toggle behavior; replacing the role icons (heart/building); backend/auth-logic changes; the cat-dog mascot asset elsewhere in the app (only the auth primary brand element is swapped).

## Risks

- Removing the mascot entirely may reduce perceived playfulness — mitigate by keeping it as an optional small decorative accent if the founder prefers, without making it the primary brand element.
- The navbar border is already conditional; over-engineering the fix could introduce regressions — keep to verification + a regression spec.
- Palette audit may surface borderline cases (e.g., a teal accent on a neutral element that spans both roles) — resolve case-by-case against DESIGN.md, recording decisions.
