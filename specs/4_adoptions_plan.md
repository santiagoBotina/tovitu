# Plan: Adoptions

**Domain:** Adoptions
**Priority:** 4 (core workflow)
**Status:** Draft

---

## User Stories

1. As a **prospective adopter**, I want to **submit an adoption application** so that I can start the process of adopting a pet.
2. As a **shelter staff member**, I want to **review adoption applications** so that I can evaluate potential adopters.
3. As a **shelter staff member**, I want to **approve or reject applications** so that I can manage the adoption pipeline.
4. As a **shelter staff member**, I want to **communicate with applicants** so that I can ask follow-up questions.
5. As a **prospective adopter**, I want to **check my application status** so that I know where I am in the process.
6. As a **shelter admin**, I want to **configure a custom application questionnaire** so that I can ask the right questions for my shelter.
7. As a **shelter staff member**, I want to **record adoption outcomes** so that we maintain accurate records.

---

## Description

The Adoptions domain manages the entire adoption lifecycle — from the initial application through to the final decision. It is the core workflow that brings together pets, shelters, and adopters.

The MVP focuses on a structured application workflow: an adopter fills out a questionnaire (either shelter-specific or default), the shelter reviews and either approves, rejects, or requests more information. If approved, the adoption is finalized with a record of the outcome.

The adoption process feeds into the AI components (Phase 5) for compatibility analysis and post-adoption support (Phase 7).

Applications are currently anonymous (no adopter account). Adopters provide their contact information in the application form, and communication happens via email and/or WhatsApp (Phase 6).

---

## Acceptance Criteria

### AC1: Submit Adoption Application
```
Given I am viewing a pet's profile
When I click "Apply to Adopt"
Then I see the adoption application form

Given I fill in the adoption application form
When I provide: full name, email, phone, address, housing type, current pets, pet experience, and answer the shelter's questionnaire
And I submit the form
Then an adoption application is created with status "pending"
And the shelter is notified (email + in-app)
And I see a confirmation message with the application reference number
And I receive a confirmation email

Given I submit an incomplete application (missing required fields)
When I click submit
Then I see validation errors on the form
And no application is created
```

### AC2: Application Questionnaire
```
Given a shelter has configured a custom questionnaire
When an adopter applies for one of their pets
Then the application form includes the shelter's custom questions

Given a shelter has not configured a custom questionnaire
When an adopter applies for one of their pets
Then the application form uses the default Tovitu questionnaire

Given the default questionnaire includes:
  - Why are you interested in this pet?
  - Where will the pet live (indoor/outdoor)?
  - How many hours will the pet be alone per day?
  - Have you owned pets before? Tell us about them.
  - Who is your veterinarian (if applicable)?
  - All household members agree to this adoption?
  - Landlord permission confirmed (if renting)?
```

### AC3: Review Applications
```
Given I am a shelter staff member
When I view the applications dashboard
Then I see all applications sorted by submission date (newest first)
And I can filter by status: pending, under_review, approved, rejected, withdrawn

Given I open an application
When I view the details
Then I see:
  - Applicant's contact information and answers
  - The pet details
  - AI compatibility score (if available — Phase 5)
  - Notes from other staff members
  - Status history / timeline
```

### AC4: Process Application
```
Given I am reviewing a pending application
When I approve the application
Then the status changes to "approved"
And the applicant receives an approval notification
And the pet's status changes to "on_hold"
And other pending applications for this pet are notified that the pet is no longer available (optional)

Given I am reviewing a pending application
When I reject the application
Then I must provide a rejection reason
And the status changes to "rejected"
And the applicant receives a rejection notification with the reason

Given I am reviewing a pending application
When I request more information
Then the status changes to "awaiting_response"
And a notification is sent to the applicant requesting additional information
And a timeline entry is created with the specific questions

Given an application is "awaiting_response"
When the applicant provides the requested information
Then the status changes back to "under_review"
And the shelter is notified
```

### AC5: Finalize Adoption
```
Given an application is approved
When a staff member records the adoption as complete
Then the application status changes to "completed"
And the pet's status changes to "adopted"
And the adoption date is recorded
And the applicant receives a congratulations message
And a post-adoption record is created (for Phase 7)

Given an approved application
When the adoption does not proceed (adopter backs out, failed meet-and-greet)
Then the staff can mark it as "withdrawn" by applicant or "cancelled" by shelter
And the pet's status changes back to "available"
And a clear reason is recorded
```

### AC6: Withdraw Application
```
Given I have submitted an application
When I withdraw my application (via email link or phone)
Then the status changes to "withdrawn"
And the shelter is notified
And the pet's availability is unaffected
```

---

## Business Rules

1. **One application per pet per email** — an adopter can only apply once per pet. If withdrawn/rejected, they cannot re-apply for the same pet.
2. **Multiple applications** — an adopter can apply for multiple pets simultaneously.
3. **Application status lifecycle** — `pending` → `under_review` → `approved` / `rejected` / `awaiting_response` → `completed` / `withdrawn` / `cancelled`.
4. **Pet hold on approval** — when an application is approved, the pet goes on hold for 48 hours. If adoption isn't finalized, hold expires and pet goes back to available.
5. **Rejection reason required** — staff must provide a reason when rejecting. Reasons are templated for consistency and legal safety.
6. **Data retention** — applications are kept for 2 years after completion/withdrawal for audit purposes.
7. **No account required** — adopters apply without an account in MVP. They identify themselves via email.
8. **Status check via token** — adopters receive a token link in their confirmation email to check status without logging in.
9. **Confidentiality** — application data is only visible to shelter staff with access to that shelter.

---

## User Flow

### Adopter Application Flow
1. Adopter views pet profile → clicks "Apply to Adopt"
2. Adopter fills in application form (contact info + questionnaire)
3. System validates → creates application → sets status = "pending"
4. System sends confirmation email with status link (token-based)
5. Shelter staff receives notification (in-app + email)
6. Adopter waits for shelter response

### Shelter Review Flow
1. Staff sees new application notification
2. Staff opens application, reviews answers
3. Staff takes action:
   a. **Approve** → system sets pet on hold, sends approval notification
   b. **Reject** → system sends rejection with reason
   c. **Request info** → system sends questions, sets status to awaiting_response
4. If approved → staff schedules meet-and-greet (offline for MVP)
5. After meet-and-greet → staff finalizes or cancels adoption

### Application Expiry Flow
1. Pet approved for adopter A → pet set to on_hold
2. 48 hours pass without finalization
3. System sends reminder to both staff and adopter
4. After 72 hours without action → hold expires
5. Pet returns to "available" status
6. Application marked as "expired"
7. Next pending applicant (if any) is notified (future)

---

## Edge Cases & Error States

| Edge Case | Handling |
|-----------|----------|
| Adopter applies for same pet twice | Show "you've already applied for this pet" error |
| Adopter's email bounces | Flag application, notify staff, log delivery failure |
| Shelter staff approves without meet-and-greet | Allow (shelter's process may vary) |
| Pet is adopted by someone else while application is pending | Auto-reject pending applications for that pet with a "pet no longer available" message |
| Adopter claims they never submitted | Use confirmation email + timestamp as proof |
| Staff accidentally rejects | Allow reversal if within 24 hours (soft delete rejection) |
| Multiple approvals for same pet | Lock: once approved, pet goes on hold; no other applications can be approved |
| Adopter provides false info | Shelter's responsibility to verify. System notes that verification is recommended. |
| Application contains offensive content | Allow shelter to mark as spam; flag account/email |
| Staff leaves shelter mid-review | Applications remain; new staff picks up |
| Adopter wants to update application | Allow editing while status is pending only (via token link) |

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Application submission rate | > 15% of pet profile views |
| Application → approval rate | > 30% |
| Approval → completed adoption rate | > 70% |
| Average time from application to decision | < 5 days |
| Withdrawn/cancelled rate | < 20% |
| Adopter satisfaction (survey) | > 4/5 |

---

## Dependencies / Prerequisites

- Pets (Phase 3) — applications are for specific pets
- Shelters (Phase 2) — applications are managed by shelters
- Authentication (Phase 1) — staff must be logged in to review
- Action Mailer — confirmation and notification emails
- AI (Phase 5) — optional enhancement for compatibility scoring

---

## Open Questions / Risks

1. **Meet-and-greet scheduling?** Not in MVP. Shelters handle scheduling externally (phone/email). Could integrate calendar in Phase 2.
2. **Application fee?** Not in MVP. Some shelters charge application fees. Consider Stripe integration post-MVP.
3. **Reference checking?** Shelters manually check references. Automated reference requests could be added later.
4. **Credit check / background check?** Not in MVP. Some shelters do this. Keep as a note for future.
5. **Multi-pet applications?** MVP: one application per pet. Future: apply for multiple pets in one application.
6. **Adopter account vs anonymous?** Decision: Anonymous for MVP. Token-based status checking. Adopter accounts may be added if retention/engagement requires it.
7. **Application scoring/ranking?** Could order applications by AI compatibility. Deferred to Phase 5.

---

## Technical Notes

### Models
```
AdoptionApplication
  - pet_id (bigint, not null)
  - shelter_id (bigint, not null) — denormalized for query performance
  - status (string, not null, default: "pending")
  - applicant_name (string, not null)
  - applicant_email (string, not null)
  - applicant_phone (string, nullable)
  - applicant_address (text, nullable)
  - housing_type (string, nullable) — house | apartment | condo | other
  - current_pets (text, nullable) — description of current pets
  - pet_experience (text, nullable) — experience level
  - questionnaire_answers (jsonb, default: {})
  - notes (text, nullable) — staff notes
  - rejection_reason (string, nullable)
  - token (string, not null, unique) — for adopter status checking
  - reviewed_by_id (bigint, nullable) — staff who reviewed
  - completed_at (datetime, nullable)
  - withdrawn_at (datetime, nullable)
  - hold_expires_at (datetime, nullable)
  - discarded_at (datetime, nullable)

AdoptionNote
  - adoption_application_id (bigint, not null)
  - user_id (bigint, not null) — staff who wrote note
  - content (text, not null)
  - pinned (boolean, default: false)

AdoptionTimelineEvent
  - adoption_application_id (bigint, not null)
  - event_type (string, not null) — created | approved | rejected | info_requested | info_received | completed | withdrawn | expired
  - metadata (jsonb, default: {})
  - created_at (datetime, not null)
```

### Service Objects
- `Adoptions::SubmitApplication` — creates application, generates token, sends confirmation
- `Adoptions::ProcessApplication` — approve/reject/request_info with notifications
- `Adoptions::FinalizeAdoption` — marks as completed, updates pet status
- `Adoptions::WithdrawApplication` — adopter withdraws via token
- `Adoptions::AddNote` — staff adds internal notes
- `Adoptions::CheckStatus` — adopter retrieves status via token
- `Adoptions::ExpireHold` — cron job to expire pet holds after 48h

### Controllers
- `AdoptionApplicationsController` — public submit
- `AdoptionApplications::StatusController` — public status check via token
- `Shelters::AdoptionApplicationsController` — staff review dashboard

### Routes
```
resources :adoption_applications, only: [:new, :create]  # public
resource :application_status, only: [:show], controller: "adoption_applications/status"  # token-based

namespace :shelter do
  resources :adoption_applications, only: [:index, :show, :update] do
    resources :notes, only: [:create], controller: "adoption_applications/notes"
    member do
      patch :approve
      patch :reject
      patch :request_info
      patch :finalize
      patch :cancel
    end
  end
end
```

### Testing Notes
- Test full application lifecycle (pending → approved → completed)
- Test adopter cannot apply twice for same pet
- Test 48h hold expiry
- Test token-based status access without login
- Test notification delivery on status changes
- Test authorization: staff can only see own shelter's applications
