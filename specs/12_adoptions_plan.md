# Plan: Adoption Requests

**Domain:** Adoptions
**Priority:** 4 (core workflow — brings together pets, shelters, and adopters)
**Status:** Draft
**Date:** 2026-06-24

---

## Overview

The Adoptions domain is the core workflow of Tovitu. It enables adopters to express interest in a specific pet and shelters to review, validate, and decide on those requests. This implementation aligns with the newer architecture from `7_auth_and_onboarding_plan.md`, where adopters have authenticated accounts with structured profile data (personality, lifestyle, experience).

Adoption requests are simpler than the earlier `4_adoptions_plan.md` envisioned — the MVP focuses on a three-status lifecycle: **In Validation**, **Accepted**, and **Declined** — rather than the complex multi-step pipeline proposed originally. This keeps the initial scope tight while still enabling meaningful shelter decision-making.

The adopter's onboarding profile (from `7_auth_and_onboarding_plan.md`) feeds into the request, giving shelters visibility into the adopter's personality, activity level, pet experience, and lifestyle preferences. This information helps shelters make informed decisions without requiring a lengthy application form.

---

## 1. User Stories

### Adopter Stories

#### US-ADOPT-01: Initiate an Adoption Request
> **As an** authenticated adopter,
> **I want to** initiate an adoption request for a specific pet I'm interested in,
> **So that** I can start the adoption process.

**Acceptance Criteria:**
```
Given I am logged in as an adopter with a completed onboarding profile
When I view a pet that is available for adoption
And I click "Request to Adopt" / "Adopt Me"
Then I am shown a confirmation step with:
  - The pet's name and photo
  - The shelter's name
  - My profile summary (personality, lifestyle, experience)
  - A "Submit Request" button
  - A "Cancel" button

Given I click "Submit Request"
When the adoption request is created
Then I see a success confirmation message
And I am redirected to my adoption requests page
And the request is listed with status "pending"
And I receive an in-app notification confirming submission
And I receive an email notification confirming submission

Given I have NOT completed my onboarding profile
When I attempt to initiate an adoption request
Then I am prompted to complete my onboarding first
And I am redirected to the onboarding flow
```

#### US-ADOPT-02: Review Pet Information
> **As an** adopter,
> **I want to** review the pet's full profile (photos, personality, needs),
> **So that** I can make an informed decision before requesting adoption.

**Acceptance Criteria:**
```
Given I am viewing a pet's public profile
When I navigate to the pet's page
Then I see:
  - Photo gallery (primary photo + thumbnails)
  - Pet name, species, breed, age, size, sex
  - Description / personality write-up
  - Medical history summary
  - Home requirements and needs
  - AI Life Preview (if available — from Phase 5)
  - Shelter name (linked to shelter profile)
  - "Request to Adopt" button (if pet is available)

Given the pet has been adopted or is on hold
When I view the profile
Then the "Request to Adopt" button is hidden
And I see a status notice: "This pet is currently [adopted/on hold]"
```

#### US-ADOPT-03: View Shelter Information
> **As an** adopter,
> **I want to** view the shelter's information (name, location, details),
> **So that** I can learn about the organization caring for the pet.

**Acceptance Criteria:**
```
Given I am viewing a pet's profile
When I click the shelter's name or a "View Shelter" link
Then I see the shelter's public profile page with:
  - Shelter name
  - Description / about text
  - Location (city, state)
  - Contact phone
  - Website (if available)
  - Hours of operation
  - Adoption policies (fees, requirements)
  - Other available pets from this shelter

Given I am on my adoption request detail page
When I view the request
Then the shelter name is displayed and linked to their public profile
```

#### US-ADOPT-04: Track Adoption Request Status
> **As an** adopter,
> **I want to** see the current status of my adoption requests,
> **So that** I know where I am in the process.

**Acceptance Criteria:**
```
Given I am logged in as an adopter
When I navigate to "My Adoption Requests" on my dashboard
Then I see a list of all my adoption requests
And each request shows:
  - Pet name and photo
  - Shelter name
  - Current status (Pending, In Validation, Accepted, Declined)
  - Date submitted
  - Last updated date
  - A link to view details

Given I have no adoption requests
When I view the page
Then I see an empty state: "You haven't requested to adopt any pets yet"
And a "Browse Pets" CTA button

Given I click on an individual adoption request
When I view the details
Then I see:
  - Full pet profile
  - Shelter information
  - Status history / timeline
  - Any messages from the shelter (decline reason, validation notes)
  - Next steps based on current status
```

### Shelter Stories

#### US-SHELTER-01: Receive Notification of New Request
> **As a** shelter staff member,
> **I want to** receive a notification when a new adoption request is initiated for one of our pets,
> **So that** I can respond promptly.

**Acceptance Criteria:**
```
Given a new adoption request is submitted for one of my shelter's pets
When the request is created
Then all shelter staff members receive an in-app notification
And shelter admins receive an email notification (optional toggle for staff)

Given I am on the shelter dashboard
When I have unread adoption requests
Then the dashboard shows a count of pending requests
And the "Adoption Requests" section highlights new items

Given I open the notification
When I click on it
Then I am taken to the adoption request detail page
```

#### US-SHELTER-02: Review Adoption Request Details
> **As a** shelter staff member,
> **I want to** view the full adoption request including the pet's information and the adopter's profile,
> **So that** I can evaluate the match.

**Acceptance Criteria:**
```
Given I open an adoption request
When I view the details
Then I see:

  **Pet Information:**
  - Pet name, photo, species, breed, age, size, sex
  - Personality traits
  - Medical notes
  - Home requirements
  - AI Life Preview (if available)

  **Adopter Profile:**
  - Adopter name
  - Location (city, state)
  - Personality type (e.g., "Calm and thoughtful")
  - Activity level
  - Pet experience level
  - Weekend activity preferences
  - Adoption goals
  - Daily time available for a pet
  - Ideal companion type
  - Adoption priority statement (free text)
  - Previous interactions or requests from this adopter

  **Request Metadata:**
  - Date submitted
  - Time since submission
  - Status history / timeline

Given the adopter has submitted multiple requests
When I view the adopter's information
Then I see a link to view their other active requests (to identify patterns)
```

#### US-SHELTER-03: Change Adoption Request Status
> **As a** shelter staff member,
> **I want to** change the status of an adoption request to **In Validation**, **Accepted**, or **Declined**,
> **So that** I can manage the adoption pipeline.

**Acceptance Criteria:**
```
Given I am viewing a pending adoption request
When I click "Mark as In Validation"
Then the request status changes to "in_validation"
And the adopter receives an in-app notification: "The shelter is reviewing your request and may contact you for more information"
And the pet remains listed as available (no hold)

Given I am viewing a request in "In Validation" status
When I click "Accept"
Then the request status changes to "accepted"
And the adopter receives a notification: "Congratulations! Your adoption request has been accepted"
And the pet's status changes to "on_hold"
And the adopter sees next-step instructions (shelter will contact them)

Given I am viewing a request
When I click "Decline"
Then I am prompted to provide a reason
And I can select from default reasons or write a custom reason
And the request status does NOT change until a reason is provided
And after submitting the reason, the status changes to "declined"
And the adopter receives a notification with the decline reason

Given I change the status of a request
When the update is saved
Then the status change is recorded in the request timeline
And the staff member who made the change is logged
And the timestamp is recorded
```

#### US-SHELTER-04: Decline with Reason
> **As a** shelter staff member,
> **I want to** provide a personalized reason when declining, or select from default options,
> **So that** the adopter understands why their request was not approved.

**Acceptance Criteria:**
```
Given I am declining an adoption request
When I am prompted for a reason
Then I see default decline reasons:
  1. "We don't think your profile matches with the pet's personality and needs"
  2. "The pet has specific requirements that don't align with your living situation"
  3. "We've found another adopter who is a better match for this pet"
  4. "The pet is no longer available for adoption"
  5. "We require additional information to proceed with your request"

And I can select one or more default reasons
And I can also type a custom reason in a free-text field
And I can combine defaults with custom text

Given I submit the decline with reasons
When the request is declined
Then the adopter sees the reason(s) in their notification and on the request detail page
And the reason is saved to the request record for audit purposes

Given I decline a request
When I do not provide any reason
Then the decline action is blocked
And I see a validation error: "Please provide at least one reason for declining"
```

---

## 2. Scope

### MVP Scope (Must-Have)

| Feature | Priority | Notes |
|---------|----------|-------|
| Adopter initiates request for a specific pet | P0 | Core action |
| Adopter views pet profile before requesting | P0 | Already exists from Phase 3 |
| Adopter views shelter information | P0 | Already exists from Phase 2 |
| Request links to adopter's User account | P0 | Not anonymous |
| Request includes adopter's onboarding profile | P0 | Personality, lifestyle, experience from `AdopterProfile` |
| Shelter views adopter profile on request | P0 | |
| Shelter changes status (In Validation / Accepted / Declined) | P0 | Three-status lifecycle |
| Decline with default or custom reasons | P0 | |
| Notifications (in-app) for status changes | P0 | |
| Email notifications for status changes | P0 | |
| Request timeline / status history | P0 | Visible to both parties |
| Adopter's "My Requests" dashboard page | P0 | List + detail view |
| Shelter's "Adoption Requests" management page | P0 | List + filter + detail |
| Shelter dashboard shows pending request count | P1 | Dashboard widget |
| Pet status changes to "on_hold" when accepted | P0 | Prevents double-acceptance |
| Duplicate request prevention (same adopter + same pet) | P0 | Business rule |

### Post-MVP (Future Considerations)

| Feature | Priority | Notes |
|---------|----------|-------|
| AI compatibility scoring on requests | Planned (Phase 5) | Auto-generated on submission |
| Adopter re-applies after decline (revised application) | Future | Requires re-onboarding or profile update |
| Meet-and-greet scheduling via platform | Future | Calendar integration |
| Document upload (vet records, references) | Future | |
| Multi-pet adoption request (one request for multiple pets) | Future | |
| Request expiration / auto-decline after X days | Future | |
| Shelter customizes default decline reasons | Future | Per-shelter configuration |
| Adopter appeals a declined request | Future | |
| WhatsApp notifications for status changes | Planned (Phase 6) | |
| Application fee collection | Future | Stripe integration |
| Bulk operations (decline multiple similar requests) | Future | |
| Adopter withdraws their own request | Future | MVP: contact shelter |

---

## 3. Information Architecture

### Key Data Entities

```
User (already exists)
  - id
  - email
  - name
  - role: "adopter" | "shelter_admin" | "shelter_staff"
  - verified_at
  - onboarding_completed_at
  - shelter_id (nullable — for shelter users)
  - discarded_at (nullable)

AdopterProfile (already exists, from 7_auth_and_onboarding_plan.md)
  - user_id (FK to User)
  - weekend_activity (jsonb, [])
  - activity_level (string, nullable)
  - ideal_companion (string, nullable)
  - pet_experience (string, nullable)
  - adoption_goals (jsonb, [])
  - daily_time_available (string, nullable)
  - personality (string, nullable)
  - adoption_priority (string, nullable)

Shelter (already exists, from 2_shelters_plan.md)
  - id
  - name
  - street, city, state, zip
  - phone, website
  - description
  - hours
  - status (active | inactive)
  - adoption_policies (jsonb, {})
  - discarded_at (nullable)

Pet (already exists, from 3_pets_plan.md)
  - id
  - shelter_id (FK to Shelter)
  - name, species, breed, age_category, size, sex
  - description, personality_traits (jsonb), medical_notes
  - status (available | on_hold | adopted | not_available | removed)
  - good_with_children, good_with_dogs, good_with_cats (boolean, nullable)
  - requirements (text, nullable)
  - adopted_at (datetime, nullable)
  - discarded_at (nullable)

AdoptionRequest (NEW — replaces complex AdoptionApplication from old plan)
  - id (bigint, PK)
  - pet_id (bigint, FK to Pet, NOT NULL)
  - adopter_id (bigint, FK to User, NOT NULL) — linked to adopter account
  - shelter_id (bigint, FK to Shelter, NOT NULL) — denormalized from pet
  - status (string, NOT NULL, default: "pending")
    Values: pending | in_validation | accepted | declined
  - decline_reasons (jsonb, nullable)
    Structure: ["default reason 1", "custom reason text", ...]
  - reviewed_by_id (bigint, FK to User, nullable) — shelter staff who acted
  - reviewed_at (datetime, nullable)
  - created_at (datetime, NOT NULL)
  - updated_at (datetime, NOT NULL)

AdoptionRequestTimelineEvent (NEW — status change log)
  - id (bigint, PK)
  - adoption_request_id (bigint, FK to AdoptionRequest, NOT NULL)
  - from_status (string, nullable) — null for initial creation
  - to_status (string, NOT NULL)
  - actor_id (bigint, FK to User, nullable) — null for system actions
  - metadata (jsonb, default: {}) — decline_reasons, notes, etc.
  - created_at (datetime, NOT NULL)
```

### Status Lifecycle

```
                    ┌─────────────────┐
                    │    pending      │  (initial state on submission)
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
     ┌────────────────┐ ┌──────────┐ ┌──────────┐
     │  in_validation │ │ accepted │ │ declined │
     └────────────────┘ └──────────┘ └──────────┘
              │              │
              │              │ (pet → on_hold)
              │              │
              └──────┬───────┘
                     │
                     ▼
              ┌──────────┐
              │ declined │  (if shelter declines after validation)
              └──────────┘

Note: "accepted" is a terminal status in MVP. Future phases may add
"adoption_completed" after the animal is physically adopted.
"declined" is always terminal — no appeal route in MVP.
```

### Key Relationships

```
Shelter ──has_many──> Pets
Shelter ──has_many──> AdoptionRequests (via pets)
User (adopter) ──has_one──> AdopterProfile
User (adopter) ──has_many──> AdoptionRequests
User (adopter) ──has_many──> Pets (through AdoptionRequests)
Pet ──belongs_to──> Shelter
Pet ──has_many──> AdoptionRequests
AdoptionRequest ──belongs_to──> Pet
AdoptionRequest ──belongs_to──> User (adopter)
AdoptionRequest ──belongs_to──> Shelter
AdoptionRequest ──has_many──> AdoptionRequestTimelineEvents
AdoptionRequestTimelineEvent ──belongs_to──> AdoptionRequest
AdoptionRequestTimelineEvent ──belongs_to──> User (actor, optional)
```

---

## 4. UX Flow

### Flow 1: Adopter Initiates Adoption Request

```
1. ADOPTER browses pets (/pets or /pets/:id)
2. Adopter finds a pet they're interested in
3. Adopter clicks on pet → views full pet profile
   - Sees photos, personality, medical, requirements
   - Sees shelter name (linked to shelter profile)
   - Sees "Request to Adopt" button

4. Adopter clicks "Request to Adopt"
   ──→ System checks: Is adopter onboarding complete?
       │
       ├── NO → Redirect to onboarding flow (see 7_auth_and_onboarding_plan.md)
       │         Cannot proceed until profile is complete
       │
       └── YES → Show confirmation step:
                  ┌──────────────────────────────────────┐
                  │ Confirm Adoption Request             │
                  │                                      │
                  │  Pet: [Photo] Bella — 3yr old Lab    │
                  │  Shelter: Happy Paws Rescue          │
                  │                                      │
                  │  Your Profile Summary:               │
                  │  • Personality: Calm & thoughtful    │
                  │  • Activity: Balanced                │
                  │  • Experience: Some experience       │
                  │  • Home: Apartment, 2-4hrs/day       │
                  │                                      │
                  │  [Edit Profile] [Submit Request]     │
                  └──────────────────────────────────────┘

5. Adopter clicks "Submit Request"
   ──→ System validates:
       │
       ├── Duplicate check: Has adopter already submitted
       │   a request for THIS pet?
       │   │
       │   ├── YES → Show error: "You've already submitted
       │   │          a request for this pet. You can view
       │   │          its status in your adoption requests."
       │   │
       │   └── NO → Continue
       │
       └── Availability check: Is pet still available?
           │
           ├── NO → Show error: "This pet is no longer
           │         available for adoption"
           │
           └── YES → Create AdoptionRequest (status: pending)

6. Confirmation shown:
   ┌─────────────────────────────────────────────────┐
   │ ✅ Request Submitted!                           │
   │                                                 │
   │ Your request to adopt Bella has been sent to    │
   │ Happy Paws Rescue. They'll review your profile  │
   │ and get back to you soon.                       │
   │                                                 │
   │ [View My Requests]  [Browse More Pets]          │
   └─────────────────────────────────────────────────┘

7. System actions:
   - Creates AdoptionRequest record (status: pending)
   - Creates AdoptionRequestTimelineEvent (to_status: pending)
   - Sends in-app notification to all shelter staff
   - Sends email notification to shelter admins
   - Sends confirmation email to adopter
   - Dispatches AI compatibility analysis job (if enabled — Phase 5)

8. ADOPTER redirected to /adopter/adoption_requests
   - Sees new request listed with "pending" badge
```

### Flow 2: Shelter Reviews and Decides

```
1. SHELTER STAFF logs in → sees dashboard
   - Dashboard shows: "3 new adoption requests" badge

2. Staff clicks "Adoption Requests" in sidebar
   ──→ Sees list of all requests for their shelter
       ┌──────────────────────────────────────────────┐
       │ Adoption Requests                Filters:    │
       │ ┌──────────────────────────────────────────┐ │
       │ │ Bella — Labrador Retriever               │ │
       │ │ Adopter: Maria G.  │ Pending ⏳          │ │
       │ │ Submitted: 2 hours ago                   │ │
       │ ├──────────────────────────────────────────┤ │
       │ │ Max — German Shepherd                    │ │
       │ │ Adopter: John D.   │ In Validation 🔍   │ │
       │ │ Submitted: 1 day ago                     │ │
       │ ├──────────────────────────────────────────┤ │
       │ │ Luna — Domestic Cat                      │ │
       │ │ Adopter: Sarah K.  │ Declined ✕          │ │
       │ │ Submitted: 3 days ago                    │ │
       │ └──────────────────────────────────────────┘ │
       │                                              │
       │ Filters: All | Pending | In Validation |     │
       │          Accepted | Declined                  │
       └──────────────────────────────────────────────┘

3. Staff clicks on a pending request (Bella)
   ──→ Sees full request detail page:

       ┌──────────────────────────────────────────────┐
       │ ← Back to Requests                           │
       │                                              │
       │ Adoption Request for Bella                   │
       │ ───────────────────────────────────────────  │
       │                                              │
       │ [Pet Profile Section]                        │
       │ Photo │ Name: Bella                          │
       │       │ Species: Dog, Labrador Retriever     │
       │       │ Age: 3 years (Adult), Size: Large    │
       │       │ Sex: Female, Spayed: Yes             │
       │       │ Personality: Friendly, Energetic,    │
       │       │   Good with kids, Good with dogs     │
       │       │ Medical: Up to date on vaccinations  │
       │       │ Requirements: Fenced yard preferred  │
       │       │   [View Full Pet Profile →]          │
       │                                              │
       │ [Adopter Profile Section]                    │
       │ Name: Maria G.                               │
       │ Location: Portland, OR                       │
       │ Personality: Calm & thoughtful               │
       │ Activity Level: Balanced                      │
       │ Pet Experience: Some experience              │
       │ Daily Time Available: 2-4 hours              │
       │ Living Situation: Apartment                  │
       │ Adoption Goals: Daily companion,              │
       │   Emotional support                          │
       │ Adoption Priority: "Looking for a calm dog   │
       │   to share my quiet home with"               │
       │   [View Adopter's Other Requests →]          │
       │                                              │
       │ [Request Timeline]                           │
       │ • Jun 24, 2026 — Request submitted (pending) │
       │                                              │
       │ [Actions]                                    │
       │ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │
       │ │In Validation│ │ Accept  │ │ Decline      │  │
       │ └──────────┘ └──────────┘ └──────────────┘  │
       └──────────────────────────────────────────────┘

4. STAFF takes an action:

   --- Option A: Mark as "In Validation" ---
   4a. Staff clicks "In Validation"
   4b. Optional: staff adds internal note (text area, not sent to adopter)
   4c. Confirmation: "Mark as In Validation?"
       [Cancel] [Confirm]
   4d. Status changes to "in_validation"
   4e. Adopter notified: "Happy Paws Rescue is reviewing your
       request for Bella and may contact you for more information."
   4f. Request appears in "In Validation" filter on shelter list
   4g. Staff can later Accept or Decline from this status

   --- Option B: Accept ---
   4a. Staff clicks "Accept"
   4b. Confirmation: "Accept this adoption request? This will
       put the pet on hold for this adopter."
       [Cancel] [Confirm]
   4c. Status changes to "accepted"
   4d. Pet status changes to "on_hold"
   4e. Other pending requests for this pet remain pending
       (but show "pet on hold" notice)
   4f. Adopter notified:
       "🎉 Congratulations! Your request to adopt Bella has
        been accepted! Happy Paws Rescue will contact you
        to arrange the next steps."
   4g. Staff sees confirmation with next-step info

   --- Option C: Decline ---
   4a. Staff clicks "Decline"
   4b. Decline reason dialog appears:
       ┌─────────────────────────────────────────┐
       │ Decline Reason                          │
       │ ─────────────────────────────────────── │
       │ Select reason(s):                       │
       │ ☐ We don't think your profile matches   │
       │   with the pet's personality and needs  │
       │ ☐ The pet has specific requirements     │
       │   that don't align with your situation  │
       │ ☐ We've found another adopter who is    │
       │   a better match for this pet           │
       │ ☐ The pet is no longer available        │
       │ ☐ We require additional information     │
       │                                         │
       │ Or add a custom reason:                 │
       │ ┌─────────────────────────────────────┐ │
       │ │ We feel Bella would do better in a  │ │
       │ │ home with a fenced yard given her   │ │
       │ │ high energy level.                  │ │
       │ └─────────────────────────────────────┘ │
       │                                         │
       │ [Back] [Submit Decline]                  │
       └─────────────────────────────────────────┘
   4c. Staff selects reasons + optionally adds custom text
   4d. Validation: at least one reason required
   4e. Status changes to "declined"
   4f. Pet remains "available" (no change)
   4g. Adopter notified with decline reason(s):
       "Your request to adopt Bella was declined.
        Reason: We don't think your profile matches
        with the pet's personality and needs."
```

### Notification Touchpoints

| Trigger | Adopter Notification | Shelter Notification |
|---------|---------------------|---------------------|
| Request submitted | ✅ Confirmation (in-app + email) | ✅ New request alert (in-app + email to admins) |
| Status → In Validation | ✅ "Shelter is reviewing" (in-app) | — (they made the change) |
| Status → Accepted | ✅ Congratulations + next steps (in-app + email) | — |
| Status → Declined | ✅ Reason provided (in-app + email) | — |
| Staff adds internal note | ❌ Not shared | — |

---

## 5. Risks and Considerations

### Duplicate Request Prevention

| Scenario | Handling |
|----------|----------|
| Adopter submits request for same pet twice | Block on creation. Check for existing `AdoptionRequest` with same `adopter_id` + `pet_id` where status is NOT `declined`. Show error: "You've already submitted a request for this pet." |
| Adopter submits for same pet after being declined | Allow (new attempt after decline). The previous decline creates a fresh opportunity — the adopter may have improved their situation. |
| Adopter submits for same pet that's on hold for them | Block — they already have an active/accepted request. |
| Adopter submits for different pet at same shelter | Allow — multiple requests across different pets are fine. |
| Race condition (double submit) | Use database unique index on `(adopter_id, pet_id)` with a condition `WHERE status != 'declined'` (partial index). Also use application-level lock/validation. |

### Privacy Considerations

| Data Point | Shared with Shelter? | Notes |
|------------|---------------------|-------|
| Adopter name | ✅ Yes | Required for identification |
| Adopter email | ✅ Yes | For direct contact |
| Adopter phone | ❌ No in MVP | Available if adopter chooses to provide later |
| Adopter address | ❌ No in MVP | Only city/state from profile |
| Adopter personality | ✅ Yes | From onboarding — helps match |
| Adopter activity level | ✅ Yes | From onboarding — helps match |
| Adopter pet experience | ✅ Yes | From onboarding — helps evaluate |
| Adopter living situation | ✅ Yes | Apartment/house from onboarding |
| Adopter daily time available | ✅ Yes | From onboarding — helps evaluate |
| Adopter adoption goals | ✅ Yes | From onboarding — helps match |
| Adoption priority text | ✅ Yes | Free text from onboarding |
| Adopter's other active requests | ✅ Yes | Visible to shelter (link) |
| Adopter's full address | ❌ No | Not collected in MVP |
| Adopter's password / auth data | ❌ Never | Never exposed |
| Shelter's internal notes | ❌ No | Not visible to adopter |

**Privacy principle:** Shelter sees what they need to evaluate the match — personality and lifestyle data, NOT contact information beyond name and email. Phone number and full address are withheld unless explicitly shared later in the process.

### Edge Cases

| Edge Case | Handling |
|-----------|----------|
| Pet is adopted by someone else while request is pending | Auto-decline pending requests for that pet with reason: "This pet has been adopted by another adopter." Run as a background job when pet status changes to "adopted". |
| Pet is marked as not_available | Hide "Request to Adopt" button. Existing pending requests remain but show notice: "This pet is currently unavailable." |
| Shelter is inactive / deleted | If shelter status is "inactive" or shelter is discarded, block new requests. Existing requests remain visible but show notice: "This shelter is currently inactive." |
| Shelter has no staff assigned | Request is created but no one to review it. Dashboard should indicate "unassigned requests." Admin should be notified to assign staff. |
| Adopter deletes their account | Adoption requests from deleted adopters are preserved (for audit). Status shown as "Adopter account deactivated." |
| Staff who reviewed leaves shelter | Request remains; reviewed_by_id is preserved (historical record). New staff can take over. |
| Two staff try to act on same request simultaneously | First action wins. Show "This request was just updated by another staff member" to the second actor. |
| Adopter has not completed onboarding | Block request initiation — redirect to onboarding. |
| Adopter submits during pet status transition (e.g., being marked adopted) | Validate pet availability at submission time INSIDE the transaction. If pet becomes unavailable between load and submit, show error. |
| Decline reason contains profanity | Basic server-side sanitization. Strip or reject offensive content. |
| Shelter accidentally accepts instead of declines | Allow reversal ONLY if done within 15 minutes of the action (soft undo). After that, requires contacting support or re-review. |
| Multiple staff reviewing same request | Non-blocking — anyone can view. Only one action (accept/decline/validate) takes effect. Timeline logs who did what. |

### Business Rules Summary

1. **One active request per pet per adopter** — An adopter can have at most one non-declined request for a given pet. Once declined, they can submit again.
2. **Onboarding required** — Adopter must complete the 8-question onboarding before initiating any request.
3. **Pet must be available** — Request can only be created for pets with status `available`.
4. **Decline requires reason** — At least one reason (default or custom) must be provided.
5. **Accepted → pet on hold** — When a request is accepted, the pet's status changes to `on_hold`.
6. **No hold on "In Validation"** — Marking as "In Validation" does NOT change the pet's availability. Shelters use this to signal they're actively reviewing.
7. **Audit trail** — Every status change is recorded with timestamp, actor, and metadata.
8. **Notifications** — All status changes trigger in-app notifications. Email notifications for: request submitted (adopter confirmation + shelter admin), accepted, declined.
9. **Re-review after decline** — Previously declined adopters can submit a new request for the same pet (they're not permanently blocked).
10. **Shelter data access** — Staff can only see requests for their own shelter (enforced via Pundit policy scope).

### Dependencies / Prerequisites

| Dependency | Phase | Status |
|------------|-------|--------|
| User accounts with adopter role | Phase 1 / 7 | Defined in `7_auth_and_onboarding_plan.md` |
| AdopterProfile with onboarding data | Phase 7 | Defined in `7_auth_and_onboarding_plan.md` |
| Pets with status management | Phase 3 | Defined in `3_pets_plan.md` |
| Shelters with staff management | Phase 2 | Defined in `2_shelters_plan.md` |
| Pundit authorization | Foundation | Already configured |
| In-app notification system | MVP | Simple flash/notice system; expand later |
| Action Mailer (email notifications) | Foundation | Already configured |
| i18n for all user-facing strings | Phase 6 | Defined in `6_i18n_plan.md` |

### Success Metrics

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Request submission rate | > 15% of pet profile views | Requests ÷ profile views |
| Time from submission to shelter first action | < 48 hours median | Timestamp diff |
| Request → Accepted rate | > 30% | Accepted ÷ total requests |
| Request → Declined with reason | 100% of declines | Audit log |
| Duplicate submission prevention rate | 0 duplicates | Error log count |
| Adopter satisfaction with process (post-decision survey) | > 3.5 / 5 | In-app survey |
| Shelter response rate (requests with at least one action) | > 90% | Requests with status change ÷ total requests |

---

## Technical Notes (Reference)

### Models
```ruby
# New models:
AdoptionRequest
  belongs_to :pet
  belongs_to :adopter, class_name: "User"
  belongs_to :shelter  # denormalized
  has_many :timeline_events, class_name: "AdoptionRequestTimelineEvent"

  enum :status, { pending: "pending", in_validation: "in_validation",
                  accepted: "accepted", declined: "declined" }

  validates :adopter_id, uniqueness: { scope: :pet_id,
    message: "already submitted a request for this pet",
    conditions: -> { where.not(status: :declined) } }

AdoptionRequestTimelineEvent
  belongs_to :adoption_request
  belongs_to :actor, class_name: "User", optional: true
```

### Service Objects (Proposed)
- `Adoptions::SubmitRequest` — creates request, validates duplicates + pet availability, triggers notifications
- `Adoptions::ProcessRequest` — handles status transitions (validate/accept/decline) with validations
- `Adoptions::DeclineRequest` — handles decline with reason collection
- `Adoptions::NotifyAdopter` — sends in-app + email notification on status change
- `Adoptions::NotifyShelter` — sends in-app + email notification on new request

### Controllers (Proposed)
- `AdoptionRequestsController` — public (adopter) create, index, show
- `Shelters::AdoptionRequestsController` — shelter staff index, show, update
- `Shelters::AdoptionRequests::DecisionsController` — accept/decline/validate actions

### Pundit Policies
- `AdoptionRequestPolicy` — adopter can create/index/show their own; shelter staff can index/show/update their shelter's

---

## Summary of Key Decisions vs. Original `4_adoptions_plan.md`

| Aspect | Original Plan (`4_adoptions_plan.md`) | This Plan |
|--------|--------------------------------------|-----------|
| Adopter identity | Anonymous (token-based) | Authenticated accounts (User model) |
| Adopter profile | Form fields at application time | Structured from onboarding (`AdopterProfile`) |
| Status lifecycle | 7 statuses (pending → under_review → approved/rejected/awaiting_response → completed/withdrawn/cancelled) | 4 statuses (pending → in_validation/accepted/declined) — simpler MVP |
| Decline reasons | Simple text field | Default options + custom text |
| Pet hold on approval | 48h hold with expiry | Permanent hold until changed |
| Questionnaire | Shelter-customizable or default | Not needed — onboarding data replaces it |
| Application editing | Via token link | Post-MVP |
| Meet-and-greet | Not tracked | Not in MVP |
| Multi-step pipeline | Complex state machine | Streamlined: validate → decide |
