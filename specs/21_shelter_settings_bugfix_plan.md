# Plan: Shelter Settings Bugfix (Bug 2.1)

**Domain:** Shelters, Authorization (Pundit), Notifications
**Priority:** 1 (P0 — shelter owners cannot manage their shelter)
**Status:** Draft
**Tracks:** Bug report §2 (Shelter Settings)

---

## Overview

Two related defects were reported while working in Shelter Settings:

1. Editing **Shelter Information**, **Staff**, or **Adoption Policies** redirects the authenticated shelter owner back to the home page with `You are not authorized to perform this action.`
2. The server log shows `ActionController::RoutingError: No route matches [GET] "/notifications/unread_count"` — a background request that fails because the notification bell polls a **locale-less** URL.

This plan fixes both.

---

## Bug 2.1a — Authorization error on Shelter Information / Staff / Adoption Policies

### Problem

Authenticated as the shelter owner (role `shelter_admin`, `user.shelter_id` set), visiting:

- `GET /shelters/:id/edit` (Shelter Information)
- `GET /shelters/:shelter_id/staff` (Staff)
- `GET /shelters/:shelter_id/policies/edit` (Adoption Policies)

results in `Pundit::NotAuthorizedError` → `ApplicationController#handle_unauthorized` → redirect to root with `flash.unauthorized`.

### Root Cause Analysis (partial — needs reproduction)

The Pundit policies gate these on admin ownership:

- `ShelterPolicy#edit?` / `#update?` → `user.shelter_admin? && user.shelter_id == record.id`
- `ShelterPolicy#staff_index?` / `#staff_create?` / `#staff_destroy?` → same
- `ShelterPolicy#policies_edit?` / `#policies_update?` → same

The `Shelters::Register` service correctly sets `user.update!(shelter: shelter, role: "shelter_admin")`, so a freshly created owner should pass. Two plausible failure modes to reproduce and verify:

1. **Role drift:** a user whose `role` is `shelter_staff` (or was set to `staff` by an invitation flow) but who is treated by the UI as an "owner" — the sidebar and dashboard show the links to any shelter user, so a `shelter_staff` member sees Edit links they cannot use. Policy requires `shelter_admin?`, but the UI offers the links to all shelter users.
2. **Stale `shelter_id` / record mismatch:** if `user.shelter_id` is nil (e.g., created before `Shelters::Register` assignment, or an invited staff accepted with role `staff` but the link target uses `current_user.shelter_id` which is nil), every `authorize` fails. The sidebar already renders `shelter_staff_index_path(shelter_id: current_user.shelter_id)` — if `shelter_id` is nil, the generated path is malformed and `set_shelter` → `Shelter.undiscarded.find(nil)` → `RecordNotFound` (a different 500), so this mode should be confirmed with real data.

**Required investigation step (first task in execution):** reproduce with a seeded shelter_admin + shelter_staff account; capture the exact failing action and the user's `role`/`shelter_id` at failure time. Add a request spec that reproduces the exact scenario from the bug report before fixing.

### Expected Behavior

- A shelter **owner** (`shelter_admin` with matching `shelter_id`) can access and modify Shelter Information, Staff, and Adoption Policies without any authorization error.
- Shelter **staff** members see a consistent experience: they may view staff/dashboard as permitted, but must **not** see edit links they cannot use (or receive a clear, non-confusing message if they try).

### Proposed Changes

1. **Confirm and fix the authorization model.**
   - If the report is caused by role confusion (staff seeing admin links): make the **views** role-aware — render Shelter Information / Staff / Adoption Policies edit links only for `shelter_admin` (use the policy in the view via `policy(@shelter).edit?` instead of hardcoding links), and/or relax policies deliberately if staff editing is a product decision (document the decision in this plan).
   - If caused by missing `shelter_id`: add a `before_action`/service guard that raises a clear error and a self-heal path (e.g., re-assign `shelter_id` when `user.shelter.present?`), plus a spec.
2. **Centralize shelter-scoped authorization** — add `ShelterPolicy#manage?` (admin-only umbrella) and use it consistently across `edit/update/staff_*/policies_*` so the three failing sections share one rule (reduces future drift).
3. **Do not change `ApplicationController#handle_unauthorized` globally** — keep redirect-to-root for truly unauthorized actions; the fix is to stop showing/attempting unauthorized actions, not to weaken the fallback.
4. **Add request specs** for: shelter_admin editing each section (200), shelter_staff hitting admin-only sections (redirect + flash, not 500), and views not rendering admin-only links for staff.

### Acceptance Criteria (2.1a)

- **AC-2.1a-1** As `shelter_admin` owner, `GET /shelters/:id/edit` returns 200 and updates persist.
- **AC-2.1a-2** As `shelter_admin` owner, `GET /shelters/:shelter_id/staff` returns 200; invite/remove work.
- **AC-2.1a-3** As `shelter_admin` owner, `GET /shelters/:shelter_id/policies/edit` returns 200; save works (HTML + Turbo).
- **AC-2.1a-4** As `shelter_staff`, the UI does not present admin-only edit links; direct access returns a redirect with `flash.unauthorized` (no 500).
- **AC-2.1a-5** A request spec reproduces the original bug scenario before the fix and passes after.

---

## Bug 2.1b — Missing notifications route (`/notifications/unread_count`)

### Problem

The notification bell Stimulus controller polls:

```js
fetch("/notifications/unread_count", ...)
fetch("/notifications/mark_all_read", ...)   // also hardcoded
```

All application routes are scoped under `scope ":locale"` (`/:locale/notifications/unread_count`), so the locale-less request raises `ActionController::RoutingError`. The 404 is silent in the browser (`.catch(() => {})`) but spams the log and means the badge count never refreshes client-side.

### Root Cause (confirmed in code)

- `app/javascript/controllers/notification_bell_controller.js:66` and `:49` hardcode `/notifications/...` paths.
- `config/routes.rb:38–47` defines notifications only under `/:locale`.

### Expected Behavior

- The notification badge unread count loads and refreshes client-side (initial load + 30s polling).
- `mark_all_read` from the dropdown works without a server error.
- No `RoutingError` in the logs from these calls.

### Proposed Changes

1. **Stop hardcoding locale-less paths in JS.** Inject route URLs as data attributes on the `[data-controller="notification-bell"]` element from the view (`_navbar.html.erb`):
   ```erb
   <div data-controller="notification-bell"
        data-notification-bell-unread-count-url-value="<%= unread_count_notifications_path %>"
        data-notification-bell-mark-all-read-url-value="<%= mark_all_read_notifications_path %>">
   ```
   Update the controller to read `this.unreadCountUrlValue` / `this.markAllReadUrlValue` instead of hardcoded strings. (Repo convention: no hardcoded strings; use route helpers.)
2. **Alternative (only if endpoints must be locale-agnostic):** add locale-less routes for the two JSON endpoints outside the `:locale` scope, e.g. `get "/notifications/unread_count", to: "notifications#unread_count"`, and keep `mark_all_read` scoped. **Prefer option 1** — it matches the app's locale-scoping convention and `default_url_options`.
3. **Add specs**: request spec for `GET /:locale/notifications/unread_count` returning JSON `{ count: N }`; confirm `mark_all_read` PATCH works with a locale prefix.

### Acceptance Criteria (2.1b)

- **AC-2.1b-1** No `No route matches [GET] "/notifications/unread_count"` in logs after deploy.
- **AC-2.1b-2** Badge count renders on page load and updates within ~30s without full page reload (manual + controller spec).
- **AC-2.1b-3** "Mark all as read" from the dropdown succeeds and clears the badge.
- **AC-2.1b-4** No hardcoded notification URLs remain in `app/javascript/**`.

---

## Success Metrics

- Shelter Settings admin flows (info/staff/policies) usable 100% of the time by owners; 0 authorization redirects for valid owners in logs.
- 0 `RoutingError` entries for `/notifications/*` in logs.
- Notification badge polling success rate ≈ 100% (no 404s).

## Test Strategy

- Request specs (per repo convention — request specs over controller specs) for each Shelter Settings section and for notifications endpoints.
- Pundit policy specs for `manage?` umbrella and existing action policies.
- Manual QA: owner edits all three sections; staff account sees no admin links; notification bell updates badge without console errors.

## Scope

**In scope:** authorization model for shelter settings sections; role-aware views; notification-bell URL injection; related specs/locales.

**Out of scope:** broader notifications redesign; other Pundit policies not listed in the bug; sidebar/navbar changes (plans 22–23).

## Risks

- Relaxing policies to allow staff editing is a product decision with adoption-safety implications — default to **keep admin-only** and fix the view/authorization mismatch instead.
- Changing `handle_unauthorized` globally would mask real authorization bugs — avoid.

---

## Implementation Notes (2026-08-06)

### Root cause confirmed (2.1a)

The authorization model itself was correct for the nominal owner (`shelter_admin` + matching `shelter_id` passes every failing action). The bug was **role confusion in the UI**: the views presented admin-only links to any shelter user (`shelter_user?` with a `shelter_id`), including `shelter_staff` (and invited members whose role is `staff`). Clicking those links produced the reported `You are not authorized to perform this action.` redirect.

Affected views before the fix:
- Profile settings rendered "Edit Shelter Information" for every shelter user.
- Sidebar rendered Staff and Adoption Policies for every shelter user.
- Dashboard quick actions rendered Manage Team and Adoption Policies, and the team card's Manage link, for every shelter member.

### Decision

**Keep admin-only.** Do not relax `ShelterPolicy`. Fix the view/authorization mismatch instead (per Risks above).

### Changes

1. `ShelterPolicy#manage?` umbrella (`shelter_admin? && shelter_id == record.id`); `edit?/update?/staff_*/policies_*` delegate to it. `dashboard?` unchanged (shelter members may view).
2. Views gate admin-only links on `policy(<shelter>).manage?`:
   - `shared/_sidebar` — Staff / Adoption Policies links
   - `authentication/profiles/edit` — Shelter Information card
   - `shelters/dashboard/show` — Manage Team / Adoption Policies quick actions + team Manage link
   - `shelters/dashboard/_checklist` — admin-only steps render as non-clickable (lock) for non-managers (`ShelterPresenter` steps carry `manage_only`)
3. Bug 2.1b: navbar injects locale-scoped URLs as Stimulus values (`data-notification-bell-unread-count-url-value`, `...mark-all-read-url-value`); `notification_bell_controller.js` reads `this.unreadCountUrlValue` / `this.markAllReadUrlValue`. No hardcoded `/notifications/*` paths remain in `app/javascript/**`.
4. Specs: `spec/policies/shelter_policy_spec.rb` (new), dashboard/staff/policies/shelters/notifications request specs extended, profiles spec asserts staff do not see the edit link.

### Drive-by fixes (unrelated defects blocking the P0 flow)

- `SheltersController#create` called `Shelter.find(result.data)` while `Shelters::Register` returns a `Shelter` object → shelter creation 500'd. Now uses `result.data` directly.
- Dashboard `_welcome_overlay` called `shelter.model.name` where `model` is a private reader → dashboard 500'd for shelters with no pets. Now uses `shelter.name`.
- Stale test assertions updated: profiles "Edit profile" → i18n title; notifications grouping uses `Time.current` (timezone-safe).
