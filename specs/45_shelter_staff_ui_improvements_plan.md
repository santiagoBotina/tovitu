# Plan: Shelter Staff Section — UI Improvements (Story 1.5)

**Domain:** Frontend, Shelter Tools, Design System
**Priority:** 2 (Medium-High) — UI-only, independent of the roles & permissions feature
**Status:** Draft
**Tracks:** Epic "Shelter Experience UI Modernization" (Story 1.5)

---

## Overview

The Staff section needs immediate visual and layout improvements. The page title sits too close to the navbar, the staff list presentation is dated, and the page does not follow the standardized dashboard page-header layout.

**Critical boundary:** this plan covers **only the visual and layout improvements** of the existing Staff section. The authorization and role management system (roles, permissions, role assignment) is a **separate feature** (plan 46) and must not be introduced here.

---

## Current State (confirmed in code)

- **Page:** `app/views/shelters/staff/index.html.erb` — an inline `<header>` (back link + title) with `mb-6` and **no top margin**, so the title sits immediately under the sticky navbar.
- **Staff list:** rows with avatar initial, name, email, a role badge (`member.role.titleize`), and a "Remove" button for non-self members.
- **Pending invitations:** card listing invitation email + invited-ago time + status badge (pending/expired) — visible only when invitations exist.
- **Invite form:** inline email field + "Send invitation" button.
- **Controller:** `Shelters::StaffController#index/create/destroy` (Pundit `staff_index?` / `staff_create?` / `staff_destroy?` = shelter admin only); creation delegates to `Shelters::InviteStaff`, removal to `Shelters::RemoveStaff`.
- **Empty states exist minimally** (a plain "no staff" text line); invitation list has no empty state (card hidden when empty).

---

## User Stories

> As a shelter owner,
> I want the Staff page to follow the same layout as the rest of the dashboard,
> so that the title isn't cramped under the navbar and the page feels part of the same app.

> As a shelter owner,
> I want my team members and pending invitations presented clearly and consistently,
> so that I can see who's on the team and who is still pending at a glance.

---

## Requirements & Proposed Behavior

### REQ-45-1 — Standardized page header

Use the standardized page-header layout from **plan 41**:

```text
Navbar
   ↓  consistent top spacing
Back navigation (when applicable)
   ↓
Staff title
Description
   ↓
Staff content/actions
```

- Title, description, and back link use the shared header component — no inline header markup.
- Back navigation goes to the shelter dashboard (contextual fallback; no browser history).

### REQ-45-2 — Staff members presentation

Display existing staff members with a modern, consistent UI using the design system:

- Avatar (existing initials pattern or richer avatar), name, email, role badge (current role display preserved — **display only**).
- Consistent row/card layout, spacing, dividers, and hover states matching the dashboard's team/activity cards.
- Remove action remains available for authorized (admin) users, visually consistent (danger-styled action with the existing confirmation).

### REQ-45-3 — Pending invitations presentation

- Pending invitations, when supported (they are), presented consistently: email, invited-ago time, status badge (pending/expired), consistent with the staff list styling.
- No new invitation capabilities are added here (cancel pending invitations belongs to plan 46).

### REQ-45-4 — Invite staff action

- The invite action is clear and accessible: a prominent "Invite staff member" button/CTA (design-system primary button) that reveals the invite form (or navigates to a dedicated form if the current inline form doesn't fit the layout).
- The invite form keeps the existing single-email input behavior and submit flow (`Shelters::InviteStaff`) — **no role selection added** (that is plan 46).

### REQ-45-5 — Empty states

- **No staff yet:** intentional empty state (icon + copy + invite CTA as next step), consistent with the application's empty states.
- **No pending invitations:** intentional, subtle empty state (or a clean hidden state with a matching "Nothing pending" line) — no awkward blank cards.

### REQ-45-6 — No roles/permissions functionality

- **No role selection, no role change, no permission matrix, no role-based visibility changes** are introduced in this plan.
- The existing role badge continues to show whatever role the current domain stores (display only).

**Edge cases:**

- Shelter with many staff members → list remains scannable (consistent row spacing, no layout breakage).
- Self-row: remove action hidden for the current user (existing behavior preserved).
- Expired invitations → status badge reflects expired state (existing behavior preserved).
- Invite form validation (invalid/duplicate email) → existing service errors surface via flash; presentation remains consistent.
- Mobile: rows stack cleanly; invite button/tap targets remain comfortable.
- Locale: all new/changed strings localized (en/es).
- Turbo: after creating an invitation or removing a member, the page redirects to staff index (existing behavior) — no broken Turbo navigation.

---

## Acceptance Criteria

- **AC-45-1** — The Staff title has sufficient spacing from the navbar.
- **AC-45-2** — The page uses the standardized dashboard page-header layout (navbar → spacing → back nav → title → description → content).
- **AC-45-3** — Existing staff members are displayed using a modern and consistent UI (avatar, name, email, role badge, actions).
- **AC-45-4** — Existing invitation functionality remains operational (invite create flow, accept flow, remove flow unchanged).
- **AC-45-5** — Empty states are visually consistent with the application (staff list and pending invitations).
- **AC-45-6** — No roles or permissions functionality is introduced as part of this UI-only task (no role selection, no role changes, no permission UI) — verified in code review.
- **AC-45-7** — The page is responsive across mobile, tablet, and desktop.
- **AC-45-8** — All new/changed strings are localized (en/es); no hardcoded user-facing strings.

---

## Success Metrics

- **Visual consistency:** Staff page matches the dashboard design system with zero divergence found in the design-review pass.
- **Zero scope bleed:** no roles/permissions code or UI introduced (verified in code review + diff).
- **Zero regression:** staff request specs (index/create/destroy + invitations) continue to pass unchanged.

---

## Test Strategy

- **Request specs:** `spec/requests/shelters/staff_spec.rb` and `spec/requests/shelters/invitations_spec.rb` continue to pass (authorization, invite, remove, accept flows) — unchanged business behavior.
- **View specs:** page renders the standardized header, staff rows with badges/actions, pending invitation rows, invite CTA + form, empty states.
- **Manual QA matrix:** staff present / no staff / pending invitations present / none × mobile/tablet/desktop; invite + accept + remove flows; both locales.

---

## Scope

**In scope:** standardized page header (plan 41); staff list and pending-invitation presentation modernization; invite action/form presentation; empty states; responsive refinements; all presentation-layer only.

**Out of scope:** roles & permissions (role selection at invite, role changes, permission enforcement, role-based visibility) — explicitly deferred to plan 46; cancel-invitation capability (plan 46); staff data model changes; any business-logic changes.

---

## Risks

- **Scope creep into roles/permissions** — the most important risk for this plan; mitigated by AC-45-6 and an explicit diff review.
- **Breaking the invite/remove flows** — mitigated by keeping controller/service behavior untouched and re-running staff/invitation specs.
- **Inconsistent header if plan 41 isn't merged first** — mitigated by scheduling after plan 41 (hard dependency).
- **Design drift** — mitigated by reusing shared recipes and the design-review pass.

---

## Dependencies

- **Depends on plan 41** (standardized page header + back navigation) — hard dependency.
- **Related to plan 44** (dashboard) — the dashboard's "Manage team" quick action links here.
- **Independent from plan 46** by design: plan 46 (roles & permissions) builds on top of this UI but is scheduled and reviewed separately.
- **Depends on plan 33 conventions** (i18n) already in place.