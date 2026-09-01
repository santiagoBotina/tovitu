# Plan: Shelter Staff Roles & Permissions — Shelter-Scoped Role-Based Access Control (Epic 2)

**Domain:** Shelter Tools, Authorization, Domain Services
**Priority:** 1 (High)
**Status:** Draft
**Tracks:** Epic "Shelter Staff Authorization" (Stories 2.1–2.5)

> **Independence requirement:** This feature is implemented independently from the Staff section UI improvements (plan 45). Plan 45 is presentation-only; this plan introduces the authorization model. They are scheduled and reviewed separately.

---

## Overview

Today, every invited staff member can be promoted with unrestricted administrative access depending on the flow, and there is no way to assign granular, shelter-scoped roles. The system must prevent every invited staff member from automatically receiving unrestricted access to the shelter's administrative functionality.

This feature introduces a **shelter-scoped role-based authorization model**:

- Each staff member has a **relationship with a specific shelter** and an **assigned role**.
- **Permissions are determined by that role** and enforced at the **domain/application boundary** (service objects + Pundit), never only in controllers or frontend.
- The **invitation flow** captures the intended role so access is granted deliberately, not by default.
- **Staff management** (view roles, change roles, remove members, cancel invitations) is available to authorized users only.
- **Cross-shelter access is impossible** — every staff relationship and permission check is scoped to one shelter.

---

## Current State (confirmed in code)

- **Membership today:** `User` has a single `shelter_id` and a global `role` (`ROLES = %w[individual shelter_admin shelter_staff admin staff]`). `Shelter has_many :users`. There is no role-per-membership model — the role lives on the user.
- **Invitation model exists:** `Invitation` (`shelter_id`, `created_by_id`, `email`, `token`, `expires_at`, `accepted_at`) — **no role column**.
- **Services (lib/shelters):**
  - `InviteStaff` — shelter-admin only; creates an invitation, **or** auto-promotes an existing registered user directly to `shelter_staff` (no invitation, no role choice).
  - `AcceptInvitation` — sets the accepting user's `shelter_id` + role `shelter_staff`.
  - `RemoveStaff` — shelter-admin only; clears `shelter_id`; prevents removing the last admin.
- **Authorization:** `ShelterPolicy` — `manage?` (and all staff/policy sub-permissions) = `user.shelter_admin? && user.shelter_id == record.id`. No finer granularity.
- **Roles today are effectively binary:** `shelter_admin` (full) vs `shelter_staff` (member), with platform-level `admin`/`staff` roles unrelated to shelters.

---

## User Stories

> As a shelter owner,
> I want to invite team members with a specific role,
> so that volunteers get the access they need without full administrative power.

> As a shelter owner,
> I want to see each team member's role, change roles, and remove people,
> so that access reflects reality as the team changes.

> As a shelter staff member,
> I want to do my job (manage pets, process applications) without touching shelter configuration,
> so that mistakes are contained and sensitive settings stay with the owner.

> As the system,
> I want every permission check scoped to a shelter and enforced server-side,
> so that no user can access another shelter's data by tampering with requests.

---

## Business Rules

### BR-46-1 — Roles (initial)

Validate against Tovitu's domain model during implementation; the initial roles are:

- **owner** — the primary administrator of the shelter.
- **administrator** — a high-level operational administrator.
- **staff_member** — an operational role with restricted access.

Platform-level roles (`admin`, `staff`) and individual/adopter roles are **out of scope** — shelter membership roles are independent of them.

### BR-46-2 — Permission matrix (explicitly defined, not inferred)

| Action | owner | administrator | staff_member |
|---|---|---|---|
| View shelter dashboard | ✅ | ✅ | ✅ |
| Manage pets (create, edit, media, discard) | ✅ | ✅ | ✅ |
| View adoption requests/applications | ✅ | ✅ | ✅ |
| Process adoption requests (validate/decide) | ✅ | ✅ | ✅ |
| Manage adoption policies | ✅ | ✅ | ❌ |
| Manage shelter profile/settings | ✅ | ❌ | ❌ |
| View staff list | ✅ | ✅ | ❌ |
| Invite staff | ✅ | ❌ | ❌ |
| Change staff roles | ✅ | ❌ | ❌ |
| Remove staff / cancel invitations | ✅ | ❌ | ❌ |

The matrix must be encoded as explicit authorization rules (Pundit + domain checks) — **never inferred from UI presence**.

### BR-46-3 — Ownership rules

- A shelter has **exactly one owner** (the shelter creator; retained through this feature).
- The owner **cannot be removed or demoted by anyone**, including themselves (ownership transfer is out of scope).
- Only the owner can manage staff (invite, change roles, remove, cancel invitations).
- The owner retains all permissions previously granted to `shelter_admin`.

### BR-46-4 — Scoping

- Every staff relationship is **scoped to one shelter** (current single-shelter membership semantics preserved; multi-shelter membership out of scope).
- Every authorization check verifies the acting user's membership **and** that the target record belongs to the acting user's shelter.
- Attempts to read or modify another shelter's staff/pets/policies are denied server-side.

### BR-46-5 — Invitation flow

1. Only a user with **manage-staff** permission (owner) can create an invitation.
2. The inviter enters the required invitation information (email).
3. The inviter **selects a role** — a role is required before the invitation can be sent.
4. The invitation stores: shelter context, the selected role, and invitation status.
5. The invited user accepts the invitation.
6. Acceptance **creates/activates the staff-to-shelter relationship** with the role stored on the invitation.

### BR-46-6 — Invitation lifecycle

- `pending` → `accepted` / `expired` / `cancelled`.
- An accepted invitation cannot be reused.
- Cancellation is owner-only.
- The current 7-day expiry behavior is preserved.

### BR-46-7 — Role changes & removal

- Role changes take effect **immediately** (next request).
- Removed staff members **lose access to shelter resources immediately** (membership cleared / deactivated).
- Last-owner protection: an owner cannot be removed or demoted, so a shelter always keeps its owner.

### BR-46-8 — Enforcement

- Authorization is enforced at the **application/domain authorization boundary** (service objects + Pundit policies).
- Controllers stay thin (authorize + call services); no authorization rules live only in controllers or frontend components.
- Users cannot gain permissions by modifying client-side requests.

---

## Requirements & Proposed Behavior

### REQ-46-1 — Shelter-scoped authorization model (Story 2.1, 2.2)

- Introduce the shelter-scoped membership concept with a role. The implementation (data layer) must preserve current single-shelter semantics; the functional requirement is: **one staff member ↔ one shelter ↔ one role**, with the role being the source of permission decisions.
- Define the roles and permission matrix (BR-46-1, BR-46-2) as explicit, testable rules.
- Map existing data at migration time (decision point below).

### REQ-46-2 — Invitation flow with role selection (Story 2.3)

- The Staff page's invite form gains a **required role selector** (owner/administrator/staff_member).
- `Shelters::InviteStaff` accepts the selected role, stores it on the invitation, and **no longer auto-promotes** an existing user without an invitation (see decision point DP-4).
- `Shelters::AcceptInvitation` activates the membership with the invitation's stored role.

### REQ-46-3 — Staff management (Story 2.5)

Authorized users (owner) can view and manage:

- **View:** staff member identity, current role, membership status, invitation status where applicable.
- **Change role:** update a member's role (subject to BR-46-3 ownership rules).
- **Remove member:** remove a staff member from the shelter (subject to BR-46-3).
- **Cancel pending invitations.**

### REQ-46-4 — Role-based authorization (Story 2.4)

- Update `ShelterPolicy` (and any other relevant policies) so permissions are derived from the membership role per the matrix — not only from `user.shelter_admin?`.
- Existing shelter actions (dashboard, pets, adoption requests, policies, profile, staff) become role-aware per the matrix.
- Keep Pundit as the authorization layer; service objects keep their domain guards and gain role checks.

### REQ-46-5 — Data migration & back-compat (Story 2.2)

Existing records must be mapped deliberately (decision point DP-3):

- `shelter_admin` users → **owner** (current admins keep full access).
- `shelter_staff` users → **staff_member**.
- Pending invitations → **staff_member** (or require re-invite with a role; implementation decides with founder sign-off).
- Platform `admin`/`staff` users are untouched.

---

## Decision Points (must be resolved during implementation, with founder sign-off)

- **DP-1 — Administrator invite capability:** the matrix defaults to owner-only invitations. Decision: should `administrator` be able to invite `staff_member`-only? Default: **no** (keeps staff management exclusive to the owner).
- **DP-2 — Ownership transfer:** explicitly out of scope in this iteration. Confirm no transfer UI is required.
- **DP-3 — Migration strategy for existing roles/invitations:** defaults above; validate counts and confirm no shelter loses an admin.
- **DP-4 — Existing registered users without an invitation:** today `InviteStaff` auto-promotes them. With role selection, the flow should create a proper invitation (with role) for consistency. Confirm removal of the auto-promote shortcut.
- **DP-5 — Membership data shape:** the implementation decides how to represent the membership+role (evolve `users.role` + `shelter_id` vs. a dedicated membership record) as long as the functional rules (BR-46-1…46-8) hold and cross-shelter safety is provable.

---

## Acceptance Criteria

- **AC-46-1** — Only users with permission to manage staff can create invitations.
- **AC-46-2** — A role must be selected before sending an invitation (required field, validated server-side).
- **AC-46-3** — The invitation stores the intended role.
- **AC-46-4** — Accepted invitations create/activate the staff-to-shelter relationship with the stored role.
- **AC-46-5** — Permissions are enforced server-side; users cannot gain permissions by modifying client-side requests.
- **AC-46-6** — Staff roles are visible to authorized users.
- **AC-46-7** — Role changes take effect according to the authorization model (immediately).
- **AC-46-8** — Removed staff members lose access to shelter resources immediately.
- **AC-46-9** — Users cannot modify staff relationships belonging to another shelter.
- **AC-46-10** — Authorization is enforced at the backend/domain layer (not only controllers or frontend).
- **AC-46-11** — The permission matrix is explicitly defined and testable; no permission is inferred from UI presence.
- **AC-46-12** — The owner cannot be removed or demoted (including by themselves).
- **AC-46-13** — All new/changed strings are localized (en/es); no hardcoded user-facing strings.
- **AC-46-14** — Existing shelter functionality continues to work for `owner` users (back-compat with today's `shelter_admin`).

---

## Success Metrics

- **Security posture:** no unauthorized-access incidents; cross-shelter access attempts rejected (enforced by tests + code review).
- **Least privilege:** new staff members start with the least privilege their role requires; no accidental admin grants.
- **Operational efficiency:** owners can manage roles without support; role changes are immediate and auditable (service logs/tests).
- **Regression safety:** full test suite green with the new authorization coverage.

---

## Test Strategy

Required automated coverage (per the requirement):

- **Authorized access** — each permission granted per matrix.
- **Unauthorized access** — each permission denied for non-owners of that permission.
- **Role-based restrictions** — staff_member blocked from policies/settings/staff; administrator blocked from staff management/settings; owner unrestricted.
- **Cross-shelter access attempts** — member of shelter A cannot view/modify shelter B staff, pets, policies, or requests.
- **Invitation creation** — authorized only; role required; role stored.
- **Invitation acceptance** — activates membership with stored role; cannot be reused; expired handling.
- **Role modification** — authorized only; immediate effect; owner protected.
- **Staff removal** — authorized only; immediate access loss; last-owner protection.

Spec locations (implementation): request specs per controller, policy specs (`ShelterPolicy`), and service specs (`lib/shelters/*` — invite/accept/remove/role-change/cancel).

---

## Scope

**In scope:** shelter-scoped role model (owner/administrator/staff_member); explicit permission matrix; role selection in the invitation flow; invitation stores role; acceptance activates membership with role; staff management (view roles, change role, remove, cancel invitations); role-aware Pundit policies and domain services; data migration for existing roles/invitations; full authorization test coverage.

**Out of scope:** ownership transfer; multi-shelter memberships; platform-level admin/staff role changes; adopter/individual permissions; the Staff section visual redesign (plan 45, separate); audit logs beyond what exists; SSO/external identity.

---

## Risks

- **Breaking existing staff access during migration** — mitigated by explicit mapping (DP-3) and back-compat AC-46-14; validate counts before migrating.
- **Role logic leaking into controllers/views** — mitigated by BR-46-8 and AC-46-10/46-11 (domain-layer enforcement + code review).
- **Invitation flow behavior change** (removing auto-promote) — affects existing-user invites; mitigated by DP-4 founder sign-off and updated specs.
- **Cross-shelfery** — the highest-severity risk; mitigated by BR-46-4, AC-46-9, and dedicated cross-shelter tests.
- **Scope overlap with plan 45** — mitigated by strict separation: plan 45 has no auth code; this plan owns all role/permission behavior.

---

## Dependencies

- **Independent from plan 45** (Staff UI) by requirement — but plan 45's invite form UI will need the role selector from this plan; coordinate to avoid double work (implement the selector here, styled per plan 45's layout).
- **Depends on** the existing Pundit + `lib/shelters` service architecture.
- **Related to plans 42/43/44** — their authorization gating (`can_manage`) will be re-expressed through the role matrix; route/destination stability is already covered by those plans.
- **Depends on plan 33 conventions** (i18n) already in place.