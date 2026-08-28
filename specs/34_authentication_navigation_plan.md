# Plan: Authentication & Navigation (REQ-04, REQ-05, REQ-06)

**Domain:** Authentication, Frontend, Navigation
**Priority:** 1 (High)
**Status:** Draft
**Tracks:** Epic "Autenticación" (REQ-04, REQ-05, REQ-06)

---

## Overview

Three frictions exist in the authentication experience:

1. A signed-out visitor who tries to **apply to adopt a pet** is pushed into login without a clear path back to the action they intended — and after authenticating they lose the flow.
2. Inside the **login/sign-up screens**, the global navbar still shows full app navigation (`Iniciar sesión`, `Crear cuenta`, saved-pets heart), which is confusing and creates loops between the two screens.
3. The **visual treatment** of the auth screens is too flat relative to Tovitu's brand, and Login/Sign Up do not share a coherent visual direction.

This plan depends on plan 33 (localization) so all new copy lands already-localized.

---

## Current State (confirmed in code)

- **Adoption request flow:** The adoption request controller requires authentication and onboarding for `new`/`create`. The "Solicitar adopción / Apply to adopt" button on the pet profile links directly to the adoption-request page. For a signed-out user this path dead-ends into a login wall without preserving the intended pet or returning them to the flow after auth.
- **Navbar:** `shared/_navbar.html.erb` renders for signed-out users a "Sign in" link, "Create account" link, and a saved-pets heart (which opens a conversion prompt). This full navbar also appears on the auth screens themselves, producing a screen where the user is simultaneously being asked to log in and offered login links.
- **Auth screens:** `authentication/sessions/new.html.erb` already has a subtle decorative paw pattern behind the card (`login-paw-pattern`), but the overall treatment is minimal and the registration screen has no matching background, so Login and Sign Up do not read as one coherent experience.

---

## User Stories

> As a visitor browsing pets,
> I want to start an adoption application and only be asked to log in when I commit,
> so that after logging in I land right back in the application I was starting.

> As a user in the middle of logging in or creating an account,
> I want a distraction-free screen with one clear way back home,
> so that I can finish authenticating without navigation noise or loops.

> As a new visitor,
> I want Login and Sign Up to feel like Tovitu from the first pixel,
> so that the brand's warmth and trust carry into the most important conversion screen.

---

## Requirements & Proposed Behavior

### REQ-04 — Redirect to Login when applying without authentication

The adoption application must remain available to browse for everyone, but committing to apply requires authentication:

1. A signed-out user can browse pets and pet profiles freely.
2. Tapping **"Solicitar adopción"** while signed out redirects to the login screen.
3. After successful authentication (or account creation), the user is **returned to the adoption application flow for the same pet** — no need to find the pet again.
4. **No adoption request is created** before authentication completes (no partial/dangling applications).
5. The user never sees a technical error during this round trip.

**User flow:**
`Browse pets → Pet profile → "Solicitar adopción" → Login (with a friendly reason message) → Authenticate → Back to adoption application for that pet → Submit`

**Edge cases:**
- User cancels/abandons login → returns to wherever they were (pet profile); no request created.
- User starts login from another page (e.g., navbar) → normal login behavior, no surprise redirect afterwards.
- Pet becomes unavailable while the user is authenticating → clear, non-technical message ("this pet is no longer available") and a link back to browse; no application created.
- Account creation instead of login → same return-to-application behavior after the full sign-up flow.
- The onboarding requirement (requests currently need completed onboarding) must not create a dead-end for the returning user — if onboarding is required, the user should see that clearly and be able to reach onboarding without losing their intent.

### REQ-05 — Simplified navbar on Login and Sign Up

While inside the authentication flow, the navbar reduces to a minimal navigation:

1. On Login: no `Iniciar sesión`, no `Crear cuenta`, no saved-pets heart.
2. On Sign Up: same.
3. Exactly one clear action to go **back to the landing page**.
4. Consistent behavior between Login and Sign Up.
5. No loops between Login and Sign Up from the navbar (the in-screen "don't have an account / already have an account" links remain the single switching mechanism, kept as text links inside the card, not in the navbar).

**Edge cases:**
- Deep links directly to `/login` or `/signup` still render the minimal navbar.
- Password reset / email verification screens: decide and apply the same minimal treatment for consistency of the auth flow.
- Mobile: the minimal navbar must not reintroduce the hamburger or the saved-pets button.

### REQ-06 — Cohesive visual redesign of Login and Sign Up

Login and Sign Up share one visual direction with a background that supports (never competes with) the form:

1. A Tovitu-aligned background behind the auth container on both screens (e.g., the established paw pattern, brand color fields, or an illustrated composition consistent with DESIGN.md).
2. Same layout skeleton and background treatment across Login and Sign Up.
3. The form keeps sufficient contrast and legibility (WCAG AA on all text over the background).
4. The background is decorative and non-interactive (aria-hidden), performs well on desktop and mobile, and does not push the form off-screen.
5. The result reads professional, warm, and trustworthy — **not** childish (per PRODUCT.md anti-references: no overly cute styling; bold clarity + playful confidence).

**Edge cases:**
- Small screens: background must not add horizontal overflow or slow rendering (no heavy assets).
- Reduced-motion preference: any decorative motion is disabled.
- Shelter vs. individual role toggle keeps its distinct accent colors on the same background.

---

## Acceptance Criteria

- **AC-34-1 (REQ-04)** — A signed-out user can browse pets and pet profiles without any authentication wall.
- **AC-34-2 (REQ-04)** — Tapping "Solicitar adopción" while signed out redirects to Login.
- **AC-34-3 (REQ-04)** — After authenticating, the user lands back in the adoption application flow for the same pet they intended.
- **AC-34-4 (REQ-04)** — No adoption request row is created before authentication completes (verified by counting requests for the pet/user before and after the flow).
- **AC-34-5 (REQ-04)** — The flow shows no technical errors; abandoned logins return the user to their previous page.
- **AC-34-6 (REQ-05)** — On Login, the navbar shows no `Iniciar sesión`, `Crear cuenta`, or saved-pets heart.
- **AC-34-7 (REQ-05)** — On Sign Up, the navbar shows no `Iniciar sesión`, `Crear cuenta`, or saved-pets heart.
- **AC-34-8 (REQ-05)** — The minimal navbar has exactly one back-to-landing action, identical on Login and Sign Up.
- **AC-34-9 (REQ-05)** — No navigation loop exists between Login and Sign Up; switching happens only via the in-card text links.
- **AC-34-10 (REQ-06)** — Login and Sign Up share the same visual direction (background + card skeleton).
- **AC-34-11 (REQ-06)** — The background is aligned with Tovitu's identity per DESIGN.md and PRODUCT.md (bold, warm, trustworthy; not childish).
- **AC-34-12 (REQ-06)** — Form text keeps WCAG AA contrast over the new background; the background never overlaps or competes with the form.
- **AC-34-13 (REQ-06)** — The design works on desktop and mobile without overflow; reduced-motion is respected.
- **AC-34-14** — All new copy is localized (en/es) per plan 33 conventions; accessibility labels included.

---

## Success Metrics

- **Login → application completion rate**: the share of signed-out users who start an application, log in, and reach the application form (measurable via a funnel; target: no drop-off attributable to the redirect).
- **Auth screen bounce**: time-on-login / exit-rate from the auth screens does not regress.
- **Sign-up conversion** from the auth screens holds or improves vs. baseline.
- **Support/feedback**: no new "where do I log in?" or "I got stuck after logging in" reports.

---

## Test Strategy

- **Request specs**: signed-out apply → login → return-to-application; pet unavailable mid-flow; abandoned login; navbar variants per screen; no request created pre-auth.
- **View specs**: minimal navbar on Login/Sign Up (absence of the three items, presence of exactly one back link); background rendered once, aria-hidden.
- **Manual QA**: full flow in both locales, mobile + desktop; contrast audit over the new background; reduced-motion check.

---

## Scope

**In scope:** auth-gated adoption application redirect + post-auth return; minimal navbar on auth screens (incl. password reset/verification consistency); shared visual background for Login and Sign Up.

**Out of scope:** Redesign of the onboarding wizard (plan 19 scope); changes to the adoption request form itself (plan 13); new auth methods (SSO/magic links); the locale switcher.

---

## Risks

- **Deep-link handling** — returning users via links from email verification may skip the intended return path; mitigation: only the in-app "apply" redirect carries the return intent; external links behave as today.
- **Onboarding dead-end** — if the returning user must complete onboarding before applying, they may get stuck; mitigation: clear messaging + one-tap path to onboarding that preserves the pet context.
- **Navbar regression** — touching the shared navbar can affect all other screens; mitigation: changes are conditional on "in auth flow" and covered by the navbar view specs.
- **Visual overreach** — a heavy background can hurt mobile performance or readability; mitigation: decorative-only, aria-hidden, lightweight (CSS/SVG, no large raster assets), contrast-verified.

---

## Dependencies

- **Depends on plan 33** (localization) so new auth copy is born localized.
- **Precedes** the favorites work (plan 35) in implementation order because the post-auth favorites import UX (REQ-09) depends on the auth screens being stable.
- Precedes plan 37 engagement work that touches the sidebar/navigation.