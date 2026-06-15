# Plan: Shelters

**Domain:** Shelters
**Priority:** 2 (needed before pets can exist)
**Status:** Draft

---

## User Stories

1. As a **shelter admin**, I want to **register my shelter** so that I can list pets and manage adoptions.
2. As a **shelter admin**, I want to **manage my shelter profile** so that adopters see accurate information.
3. As a **shelter admin**, I want to **invite staff members** so that my team can help manage the shelter.
4. As a **shelter staff member**, I want to **view my shelter's dashboard** so that I can see key metrics and pending tasks.
5. As a **prospective adopter**, I want to **browse shelters** so that I can find pets near me.
6. As a **shelter admin**, I want to **configure adoption policies** so that the adoption process matches our requirements.

---

## Description

The Shelters domain is the organizational unit of Tovitu. Every pet, adoption application, and staff member belongs to a shelter. Shelters register on the platform and configure their profile, location, and adoption policies.

The MVP assumes each shelter has one admin (the person who registered) and can invite additional staff. Shelters can set their service area, hours, adoption fees, and questionnaire templates.

A public-facing shelter directory allows adopters to find shelters by location. Each shelter gets a public profile page showing their pets, about text, and contact information.

---

## Acceptance Criteria

### AC1: Shelter Registration
```
Given I am a logged-in user with a verified email
When I fill in the shelter registration form
  And I provide: name, address, phone, website, description, species_served
Then a shelter is created
And I become the shelter admin
And I am redirected to my shelter dashboard
And I see a "welcome" banner with onboarding steps
```

### AC2: Shelter Profile Management
```
Given I am a shelter admin
When I update my shelter's name, address, phone, or description
Then the changes are saved
And the public profile reflects the changes immediately

Given I am a shelter staff member (not admin)
When I attempt to edit the shelter profile
Then I see a 403 Forbidden error
```

### AC3: Staff Management (Admin)
```
Given I am a shelter admin
When I invite a new staff member by email
Then an invitation email is sent
And a pending invitation record is created

Given I am an invited staff member
When I click the invitation link
Then I am taken to a registration page with email pre-filled
And after completing registration, I am added to the shelter
And I have "staff" role permissions

Given I am a shelter admin
When I view the staff management page
Then I see a list of all staff members and pending invitations
And I can revoke access for any staff member
```

### AC4: Shelter Dashboard
```
Given I am logged in as a shelter admin or staff
When I visit my shelter dashboard
Then I see:
  - Total pets listed
  - Active adoption applications
  - Pending tasks (unread messages, incomplete applications)
  - Recent activity log
```

### AC5: Public Shelter Directory
```
Given I am a visitor
When I visit /shelters
Then I see a list of all active shelters
And I can filter by city/state or species served

Given I am a visitor
When I click on a shelter
Then I see their public profile with:
  - Name, description, contact info, hours
  - List of available pets
  - Adoption process overview
```

### AC6: Adoption Policy Configuration
```
Given I am a shelter admin
When I configure my adoption policies
Then I can set:
  - Adoption fee amount and description
  - Required questionnaire (custom questions)
  - Minimum age requirement for adopters
  - Home visit required (yes/no)
  - Other requirements (fenced yard, vet reference, etc.)
```

---

## Business Rules

1. **One shelter per admin in MVP** — a user can only admin one shelter. Staff can belong to one shelter.
2. **Shelter names must be unique** — case-insensitive uniqueness.
3. **Invitations expire** after 7 days.
4. **A shelter cannot be deleted** while it has active pets or pending adoptions. Soft-delete only (discarded_at).
5. **Public visibility** — a shelter must explicitly mark itself as "active" to appear in the public directory. New shelters start as "active" but can be set to "inactive".
6. **Required fields** — name, address (street, city, state, zip), phone, and species_served are required.
7. **Audit logging** — log all shelter profile changes and staff management actions.

---

## User Flow

### Shelter Registration Flow
1. User verifies email (from auth flow)
2. User is redirected to `/shelters/new`
3. User fills in shelter details
4. System creates Shelter record, sets user as admin
5. System redirects to shelter dashboard with onboarding checklist
6. Onboarding checklist: Add first pet → Configure adoption policies → Invite staff → Set hours

### Staff Invitation Flow
1. Admin navigates to shelter staff management
2. Admin enters staff email
3. System creates Invitation record (token, expires_at)
4. System sends invitation email with registration link
5. Recipient clicks link → registration form (email pre-filled)
6. Recipient completes registration → added as staff to shelter
7. System redirects to shelter dashboard

---

## Edge Cases & Error States

| Edge Case | Handling |
|-----------|----------|
| User without verified email tries to create shelter | Redirect to verification prompt |
| Shelter name already taken | Show "name already exists" error on form |
| Admin tries to leave shelter | Must transfer admin role to another staff member first, or close shelter |
| Last admin tries to delete account | Require shelter transfer or shelter closure first |
| Staff email is already a user | Skip registration, directly add to shelter |
| Invitation link expired | Show "invitation expired" with option to request new one |
| Duplicate invitation for same email | Resend existing invitation or revoke + re-invite |
| Shelter has 0 staff (admin removed all) | Prevent removal of last user with admin role |
| Address geocoding fails | Allow manual entry; show warning but don't block creation |
| Phone number format | Store as string, validate format per country (US for MVP) |

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Shelter registration completion | > 80% (started → active) |
| Staff invitation acceptance rate | > 60% |
| Shelter profiles completed (onboarding) | > 70% within first week |
| Public directory bounce rate | < 40% |

---

## Dependencies / Prerequisites

- Authentication (Phase 1) — user must be logged in and verified
- Geocoding gem or service (optional for MVP — city/state string search is acceptable)
- Active Storage not needed for shelter logo in MVP (can be added later)

---

## Open Questions / Risks

1. **Geocoding for location-based search?** For MVP, simple text-based city/state filtering is sufficient. Geocoding adds complexity. Postpone to Phase 3 (pets search).
2. **Multiple shelters per admin?** Not in MVP. A user admin-ing multiple shelters is a rare edge case.
3. **Shelter verification/approval?** Should we manually verify shelters before they go public? Risk of fake shelters. For MVP, trust model — verification can be added if abuse occurs.
4. **Shelter branding (logo, colors)?** Deferred to post-MVP. Shelters have a profile page but no custom theming.
5. **Opening hours data model?** Simple text field for MVP ("Mon-Fri 9-5, Sat 10-2") rather than structured schedule.
6. **Internationalization?** Not in MVP — US-only for initial launch.
7. **Multiple species per shelter?** Yes — `species_served` is an array/enum (dog, cat, other).

---

## Technical Notes

### Models
```
Shelter
  - name (string, not null, unique)
  - street (string, not null)
  - city (string, not null)
  - state (string, not null)
  - zip (string, not null)
  - phone (string, not null)
  - website (string, nullable)
  - description (text, nullable)
  - species_served (jsonb/array, not null) — ["dog", "cat", "other"]
  - hours (string, nullable) — text description of hours
  - status (string, default: "active") — active | inactive
  - discarded_at (datetime, nullable)
  - adoption_policies (jsonb, default: {})
  - onboarding_completed (boolean, default: false)

Invitation
  - email (string, not null)
  - token (string, not null, unique)
  - shelter_id (bigint, not null)
  - expires_at (datetime, not null)
  - accepted_at (datetime, nullable)
  - created_by_id (bigint, not null) — user who sent invitation
```

### Associations
```
User belongs_to :shelter (optional — staff/admin)
User belongs_to :shelter (required for shelter-specific roles via shelter_id)
Shelter has_many :users
Shelter has_many :pets
Shelter has_many :adoption_applications (through :pets)
Shelter has_many :invitations
```

### Service Objects
- `Shelters::Register` — creates shelter, assigns admin role
- `Shelters::UpdateProfile` — updates shelter info with validation
- `Shelters::InviteStaff` — creates invitation, sends email
- `Shelters::AcceptInvitation` — processes invitation acceptance
- `Shelters::RemoveStaff` — revokes access for a staff member
- `Shelters::DirectorySearch` — queries active shelters with filters

### Routes
```
resources :shelters, only: [:index, :show, :new, :create, :edit, :update] do
  resources :staff, only: [:index, :create, :destroy], controller: "shelters/staff"
  resources :invitations, only: [:create], controller: "shelters/invitations"
  resource :policies, only: [:edit, :update], controller: "shelters/policies"
  resource :dashboard, only: [:show], controller: "shelters/dashboard"
end
```

### Testing Notes
- Test that shelter creation without verified email is rejected
- Test invitation expiry with `travel_to`
- Test that non-admin staff cannot edit shelter profile
- Test public directory filtering
- Test onboarding checklist progression
