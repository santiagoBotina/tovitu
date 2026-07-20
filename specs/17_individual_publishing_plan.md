# Plan: Individual Pet Publishing

**Domain:** Adoptions, Pets, Authentication
**Priority:** 3 (expands supply — core growth lever)
**Status:** Draft
**Date:** 2026-07-20

---

## Overview

Currently, Tovitu has a binary entity model: **Shelters** (organizations that publish pets) and **Adopters** (individuals who adopt them). This misses a key persona: a single person who finds a pet in need and wants to publish it for adoption themselves — someone who is neither a shelter organization nor a traditional adopter.

This plan proposes **redefining the "adopter" entity into a more general "individual" entity** that can both adopt pets **and** publish them. This avoids creating a third user type while enabling the full use case.

---

## Design Decision

**Chosen approach:** Rename `adopter` → `individual` as the user role, making it a general-purpose identity for natural persons (as opposed to organizations/shelters).

| Aspect | Current | Proposed |
|--------|---------|----------|
| User role value | `adopter` | `individual` |
| Database enum | `'adopter'` in CHECK constraint | `'individual'` in CHECK constraint |
| Profile model | `AdopterProfile` | `IndividualProfile` |
| Onboarding namespace | `Onboarding::Adopter::*` | `Onboarding::Individual::*` |
| Route path | `/onboarding/adopter/*` | `/onboarding/individual/*` |

**What does NOT change:**
- `adopter_id` in `adoption_requests` — this column represents "the user acting as an adopter in this specific transaction," not their permanent role. It remains semantically correct.
- `AdoptionRequest` model name — the concept of "adoption request" is still valid regardless of who published the pet.

---

## 1. User Stories

### US-INDIV-01: Register as an Individual
> **As a** person who found a pet in need,
> **I want to** sign up as an individual (not a shelter),
> **So that** I can publish a pet for adoption.

**Acceptance Criteria:**
```
Given I am a new user
When I visit the signup page
Then I see the option to register as an "Individual" (alongside "Shelter")
And the role "individual" replaces the previous "adopter" label

Given I complete registration with role "individual"
When I confirm my email
Then my account is created with role "individual"
And I can proceed to publish a pet or adopt one
```

### US-INDIV-02: Publish a Pet as an Individual
> **As an** authenticated individual,
> **I want to** publish a pet I found for adoption,
> **So that** potential adopters can find and apply for it.

**Acceptance Criteria:**
```
Given I am logged in as an individual with a verified account
When I navigate to my dashboard
Then I see a "Publish a Pet" action

Given I click "Publish a Pet"
When I fill in the pet details (name, species, breed, age, size, sex, description, photos)
And I submit the form
Then the pet is created with my user_id as publisher
And the pet appears in public search results marked as "Listed by an individual"
And I see a success confirmation

Given I have not completed my profile setup
When I try to publish a pet
Then I can still proceed (profile completion is not required to publish)
```

### US-INDIV-03: Manage My Published Pets
> **As an** individual publisher,
> **I want to** see and manage the pets I've published,
> **So that** I can update their status or edit their details.

**Acceptance Criteria:**
```
Given I am logged in as an individual who has published pets
When I visit my dashboard
Then I see a list of my published pets with their current status

Given I select a published pet
When I edit its details
Then the changes are saved and visible to the public

Given I mark a pet as adopted
When the status changes
Then the pet no longer appears in available search results
And any pending adoption requests are notified
```

### US-INDIV-04: Receive and Manage Adoption Requests
> **As an** individual publisher,
> **I want to** receive and respond to adoption requests for my pet,
> **So that** I can find a good home for the pet.

**Acceptance Criteria:**
```
Given I have published a pet
When an adopter submits an adoption request for it
Then I am notified (email and/or in-app)
And I can view the request details including the applicant's profile

Given I review an adoption request
When I approve or decline it
Then the adopter is notified of my decision
And the pet's status updates accordingly
```

---

## 2. Data Model Changes

### 2.1 User Role Migration

**Current CHECK constraint:**
```sql
CHECK (role IN ('adopter', 'shelter_admin', 'shelter_staff', 'admin', 'staff'))
```

**Proposed:**
```sql
CHECK (role IN ('individual', 'shelter_admin', 'shelter_staff', 'admin', 'staff'))
```

**Migration strategy:**
- Add the new `'individual'` value to the CHECK constraint
- Migrate all existing `'adopter'` values to `'individual'`
- Remove `'adopter'` from the CHECK constraint

**User model changes:**
```ruby
# app/models/user.rb
# Deprecate:
#   scope :adopter         → rename to scope :individual
#   def adopter?           → keep as alias or rename to individual?
#   def shelter_user?      → keep unchanged
#
# Add:
  scope :individual, -> { where(role: :individual) }
  def individual?
    role == "individual"
  end
  # Keep adopter? as alias during transition
  def adopter?
    individual?
  end
```

### 2.2 AdopterProfile → IndividualProfile

**Rename table:** `adopter_profiles` → `individual_profiles`

**Migration:**
```ruby
rename_table :adopter_profiles, :individual_profiles
```

**Model:**
```ruby
# app/models/individual_profile.rb (replaces adopter_profile.rb)
class IndividualProfile < ApplicationRecord
  belongs_to :user

  # Keep existing columns as-is (activity_level, ideal_companion, etc.)
  # These represent the individual's preferences for adopting
end
```

**Why keep the profile columns?** The profile stores adoption-oriented preferences (activity level, personality, pet experience, etc.). These remain relevant because:
- When an individual ADOPTS, the profile helps shelters evaluate them
- When an individual PUBLISHES, the profile is not needed but doesn't hurt

**Add an alias in User:**
```ruby
# User model
has_one :individual_profile, dependent: :destroy
# Keep old association working during transition
alias_method :adopter_profile, :individual_profile
```

### 2.3 Pet Model — Support Individual Publishers

**Current:**
```ruby
Pet
  belongs_to :shelter  # NOT NULL
```

**Proposed:**
```ruby
Pet
  belongs_to :shelter, optional: true
  belongs_to :publisher, class_name: "User", optional: true

  validate :must_have_shelter_or_publisher

  private

  def must_have_shelter_or_publisher
    if shelter_id.blank? && publisher_id.blank?
      errors.add(:base, :must_have_shelter_or_publisher)
    end
  end
```

**Migration:**
```ruby
# Make shelter_id nullable
change_column_null :pets, :shelter_id, true

# Add publisher reference
add_reference :pets, :publisher, foreign_key: { to_table: :users }, null: true

# Add index for publisher lookups
add_index :pets, :publisher_id
```

**Pet scopes:**
```ruby
scope :shelter_listed, -> { where.not(shelter_id: nil) }
scope :individual_listed, -> { where.not(publisher_id: nil) }
```

### 2.4 AdoptionRequest — Handle Individual Publishers

**Current:**
```ruby
AdoptionRequest
  belongs_to :pet
  belongs_to :adopter, class_name: "User"
  belongs_to :shelter  # NOT NULL
```

**Proposed:**
```ruby
AdoptionRequest
  belongs_to :pet
  belongs_to :adopter, class_name: "User"
  belongs_to :shelter, optional: true  # Make optional

  # Derive the responsible party from the pet
  def responsible_party
    shelter || pet.publisher
  end

  def individual_publisher?
    shelter_id.nil? && pet.publisher.present?
  end
```

**Migration:**
```ruby
# Make shelter_id nullable in adoption_requests
change_column_null :adoption_requests, :shelter_id, true
```

### 2.5 Summary of All Migrations

| # | Migration | Impact |
|---|-----------|--------|
| 1 | Update users CHECK constraint — add `'individual'`, remove `'adopter'` | Schema change |
| 2 | Rename `adopter_profiles` → `individual_profiles` | Table rename |
| 3 | Make `pets.shelter_id` nullable | Column change |
| 4 | Add `pets.publisher_id` → FKs to users | Column add |
| 5 | Make `adoption_requests.shelter_id` nullable | Column change |
| 6 | Update indexes for new lookups | Indexes |

---

## 3. Domain Layer Changes

### 3.1 New Service: `Pets::Publish`

```ruby
# lib/pets/publish.rb
class Pets::Publish < ApplicationService
  param :publisher  # User (individual)
  param :attributes # Hash

  def call
    pet = Pet.new(attributes.merge(publisher: publisher))

    # Validate photos
    # Similar validation logic as Pets::Create but for shelter_id = nil

    if pet.save
      Result.success(pet)
    else
      Result.failure(pet.errors)
    end
  end
end
```

This parallels `Pets::Create` but is specifically for individual publishers. `Pets::Create` stays for shelters.

### 3.2 Modified Service: `Pets::Update`

**Current:** Assumes `pet.shelter.present?` for policy checks.
**Change:** Add support for `pet.publisher.present?` — if the pet belongs to an individual, allow them to update.

### 3.3 Modified Service: `Pets::ChangeStatus`

**Current:** Checks `shelter_id` for ownership.
**Change:** Allow `publisher_id` as an alternative ownership check.

### 3.4 Modified Service: `Adoptions::SubmitRequest`

**Current:**
```ruby
AdoptionRequest.create!(
  pet: pet,
  adopter: adopter,
  shelter: pet.shelter,
  status: :pending
)
```

**Change:** Make shelter assignment dynamic:
```ruby
AdoptionRequest.create!(
  pet: pet,
  adopter: adopter,
  shelter: pet.shelter,  # may be nil
  status: :pending
)
```

No code change needed if `shelter_id` is already optional — but verify that downstream logic handles `shelter_id` being nil.

### 3.5 Modified Service: `Adoptions::ProcessRequest`

**Current:** Sends notifications to shelter.
**Change:** When `request.shelter.nil?`, send notifications to `request.pet.publisher` instead.

### 3.6 Modified Service: `Adoptions::NotifyShelter`

**Current:** Sends email to shelter staff.
**Change:** When there's no shelter, this should not be called. `NotifyAdopter` already works. May need a new `Adoptions::NotifyPublisher` or modify `NotifyShelter` to handle both.

### 3.7 Modified Query: `Pets::Search`

**Current:** Filters by shelter attributes, joins with shelters.
**Change:** Include pets published by individuals. If a pet has no shelter, skip shelter-based joins (use LEFT JOIN instead of INNER JOIN).

### 3.8 Onboarding Changes

**Rename namespace:** `Onboarding::Adopter` → `Onboarding::Individual`

```ruby
# lib/onboarding/determine_destination.rb
def adopter_destination
  # ... becomes ...
def individual_destination

# Route mapping:
# Onboarding::Adopter::QuestionsData  →  Onboarding::Individual::QuestionsData
# Onboarding::Adopter::SaveResponse   →  Onboarding::Individual::SaveResponse
# Onboarding::Adopter::Complete       →  Onboarding::Individual::Complete
```

The onboarding questions themselves (lifestyle, experience, preferences) remain the same — they represent the individual's adoption profile, which is still useful when they apply to adopt.

---

## 4. Authorization Changes

### 4.1 Pundit Policies

**`PetPolicy`:**
```ruby
# Current: Only shelter staff can create/update/destroy pets
# Change: Also allow individual publishers to manage their own pets

def create?
  user.individual? || user.shelter_admin? || user.shelter_staff?
end

def update?
  # Shelter staff can update their shelter's pets
  return true if user.shelter_admin? && record.shelter_id == user.shelter_id
  return true if user.shelter_staff? && record.shelter_id == user.shelter_id
  # Individual can update their own pets
  return true if user.individual? && record.publisher_id == user.id
  false
end

def destroy?
  update?  # Same rules as update
end

# Scope: Individuals can see their own pets regardless of status
class Scope
  def resolve
    if user.individual?
      scope.where(publisher_id: user.id).or(scope.searchable)
    else
      # existing shelter logic
    end
  end
end
```

**`AdoptionRequestPolicy`:**
```ruby
# Current: shelter_user can manage requests for their shelter
# Change: individual publisher can manage requests for their pets

def manage?
  return true if user.shelter_user? && record.shelter_id == user.shelter_id
  return true if user.individual? && record.pet.publisher_id == user.id
  false
end
```

### 4.2 Controller Authorization

New checks need to handle the case where `current_user` is an `individual` and is managing their published pets.

---

## 5. Controller & Route Changes

### 5.1 Public Routes (Minor Changes)

**`Authentication::RegistrationsController`:**
- Change signup form: "Adopter" label → "Individual" label
- Change default role value in the form: `'adopter'` → `'individual'`

**`Authentication::SessionsController`:**
- Rename `/login/adopter` → `/login/individual` (or keep as alias)
- Rename view partial: `_adopter_form.html.erb` → `_individual_form.html.erb`
- Update i18n keys

**Renamed routes:**
```ruby
# Current
get "login/adopter" → "authentication/sessions#new_adopter"
namespace :onboarding do
  namespace :adopter do
    resource :questions, only: [:show, :update]
    resource :completion, only: [:create]
  end
end

# Proposed
get "login/individual" → "authentication/sessions#new_individual"
get "login/adopter" → redirect("login/individual")  # backward compat
namespace :onboarding do
  namespace :individual do
    resource :questions, only: [:show, :update]
    resource :completion, only: [:create]
  end
end
# Keep old routes working during transition
namespace :onboarding do
  namespace :adopter, as: :adopter_onboarding do
    # Redirect or alias
  end
end
```

### 5.2 Individual Pet Management Routes

New namespace for individual publishers to manage their pets:

```ruby
# config/routes.rb
namespace :my do
  resources :pets, controller: "pets" do
    member do
      patch :change_status
    end
    resources :photos, only: [:create, :destroy, :update]
  end

  resources :adoption_requests, only: [:index, :show] do
    resource :decision, only: [:new, :create]
  end
end
```

This mirrors `namespace :shelter` but for individuals.

### 5.3 New Controllers

| Controller | Actions | Purpose |
|------------|---------|---------|
| `My::PetsController` | index, show, new, create, edit, update, destroy, change_status | Manage published pets |
| `My::PhotosController` | create, destroy, update | Manage pet photos |
| `My::AdoptionRequestsController` | index, show | View incoming requests |
| `My::AdoptionRequests::DecisionsController` | new, create | Accept/decline requests |

### 5.4 Dashboard Controller Update

**`DashboardController`:**
- Currently serves adopter dashboard (readiness %, saved pets)
- Add individual publisher actions (publish a pet, list my published pets)

```ruby
# app/controllers/dashboard_controller.rb
def index
  if current_user.individual?
    @published_pets = current_user.published_pets.kept
    @pending_requests = AdoptionRequest.pending_for_publisher(current_user)
    # existing adoption readiness logic stays
  elsif current_user.shelter_user?
    # existing shelter dashboard
  end
end
```

---

## 6. View Changes

### 6.1 Pet Cards & Show (Public)

**Pet card** (`_pet_card.html.erb` or equivalent):
- Currently shows "by [Shelter Name]"
- For individual-listed pets, show "Listed by an individual" or similar badge

**Pet show page:**
- Show publisher info section
- For shelter pets: shelter logo + name (existing)
- For individual pets: "Listed by [Publisher Name]" or "Rehomed by an individual"

### 6.2 Individual Publishing Flow

**New views under `app/views/my/pets/`:**
- `index.html.erb` — list of published pets with status badges
- `new.html.erb` — pet creation form (similar to shelter pet form)
- `edit.html.erb` — edit form
- `show.html.erb` — pet detail with management actions

### 6.3 Individual Onboarding Views

**Rename: `app/views/onboarding/adopter/` → `app/views/onboarding/individual/`**

### 6.4 Authentication Views

**Rename/reference:**
- `app/views/authentication/sessions/new_adopter.html.erb` → `new_individual.html.erb`
- `app/views/authentication/sessions/_adopter_form.html.erb` → `_individual_form.html.erb`
- Update registration form labels

---

## 7. i18n Changes

### 7.1 Role Labels

```yaml
# config/locales/en.yml
authentication:
  role_toggle:
    individual: "Individual"
    shelter: "Shelter"
    # Remove: adopter: "Adopter"
```

### 7.2 Onboarding Keys

```yaml
# Rename keys (not just labels — structure change)
onboarding:
  individual:  # was "adopter:"
    title: "Tell us about yourself"
    questions: ...
```

### 7.3 Pet Publishing Keys

```yaml
# config/locales/pets/en.yml
pets:
  listed_by:
    shelter: "Listed by %{shelter_name}"
    individual: "Listed by an individual"
  publisher:
    shelter: "Organization"
    individual: "Individual"
```

### 7.4 Dashboard Keys

```yaml
# config/locales/en.yml
dashboard:
  individual:
    published_pets: "My Published Pets"
    publish_new: "Publish a Pet"
    incoming_requests: "Adoption Requests"
```

### 7.5 Navigation Keys

Update breadcrumbs, menu items, and sidebar labels referencing "adopter".

### 7.6 Transition Period

Keep old i18n keys working during migration with aliases or fallbacks.

---

## 8. User Model Impacts

### 8.1 User Association for Published Pets

```ruby
# app/models/user.rb
class User < ApplicationRecord
  # ... existing code ...

  # For individuals who publish pets
  has_many :published_pets, class_name: "Pet", foreign_key: :publisher_id, dependent: :destroy

  # Renamed from adopter_profile
  has_one :individual_profile, dependent: :destroy
  # Keep backward compat
  alias_method :adopter_profile, :individual_profile

  # Role scopes
  scope :individual, -> { where(role: :individual) }

  # Role checks
  def individual?
    role == "individual"
  end
  alias_method :adopter?, :individual?  # backward compat
end
```

### 8.2 Onboarding Completion Check

```ruby
def onboarding_completed?
  # For individuals: check individual_profile completion
  # (unchanged logic, just renamed association)
  individual_profile.present? && onboarding_completed_at.present?
end
```

---

## 9. Search & Discovery

### 9.1 Pet Search Updates

**`Pets::Search` query:**
- Currently uses `INNER JOIN shelters` — change to `LEFT JOIN` to include individual-listed pets
- Add filter for publisher type: `?publisher=shelter` or `?publisher=individual`
- Mark individual-listed pets differently in results

### 9.2 Index View Updates

- Pet cards show publishing source (shelter vs individual)
- Filter option: "Source" → "Shelters" / "Individuals" / "All"

---

## 10. Email Notifications

### 10.1 New Mailer Methods or Modifications

**`AdoptionMailer`:**

| Method | Current Behavior | New Behavior |
|--------|-----------------|--------------|
| `new_request_notification` | Notifies shelter admins | Notifies shelter admins OR individual publisher |
| `request_confirmation` | Confirms to adopter | Unchanged |
| `status_changed` | Notifies adopter | Unchanged + also notify shelter/publisher |

Add `new_request_notification_to_publisher` for individual publishers or modify existing method to accept a `User` (publisher) instead of a list of shelter admins.

---

## 11. Migration Strategy

### Phase 1: Rename (Low Risk, Mechanical)
**Estimated effort: 2-3 days**

1. Update database CHECK constraint — add `'individual'`, migrate values, remove `'adopter'`
2. Rename table `adopter_profiles` → `individual_profiles`
3. Update User model (scopes, methods, aliases)
4. Update IndividualProfile model
5. Rename onboarding namespace (`Onboarding::Adopter` → `Onboarding::Individual`)
6. Update routes for onboarding
7. Rename onboarding views
8. Update i18n keys
9. Update session/registration views and routes
10. Run full test suite to catch breakage

**Rollback plan:** This phase is mostly mechanical renames. If something breaks, the old names can be kept as aliases.

### Phase 2: Individual Publishing (Feature Work)
**Estimated effort: 3-4 days**

1. Make `pets.shelter_id` nullable + add `publisher_id`
2. Make `adoption_requests.shelter_id` nullable
3. Create `Pets::Publish` service
4. Update `Pets::Search` to include individual-listed pets
5. Create `My::PetsController` + views
6. Create `My::AdoptionRequestsController` + decision flow
7. Update `PetPolicy` and `AdoptionRequestPolicy`
8. Update `Adoptions::SubmitRequest` and `Adoptions::ProcessRequest`
9. Update dashboard for individual publishers
10. Add notifications for individual publishers
11. Update pet cards/show to show publisher type

**Rollback plan:** Feature-flag individual publishing behind a setting. If issues arise, individual publishing can be disabled while adoption (the original flow) continues working.

### Phase 3: Polish & Cleanup
**Estimated effort: 1-2 days**

1. Remove backward-compat aliases (e.g., `adopter?` method — keep as alias but mark deprecated)
2. Update all remaining i18n references
3. Update specs and factories
4. Documentation updates
5. QA pass on all flows

---

## 12. Files Changed (Complete Inventory)

### Phase 1 — Rename

| Type | File(s) |
|------|---------|
| Migration | `db/migrate/*_rename_adopter_to_individual.rb` |
| Migration | `db/migrate/*_rename_adopter_profiles_table.rb` |
| Model | `app/models/user.rb` (scopes, methods) |
| Model | `app/models/adopter_profile.rb` → `app/models/individual_profile.rb` |
| Model | `app/models/adoption_request.rb` (if scope references change) |
| Service | `lib/onboarding/determine_destination.rb` |
| Service | `lib/onboarding/adopter/*.rb` (move to `individual/`) |
| Controller | `app/controllers/onboarding/adopter/*` → `individual/*` |
| Controller | `app/controllers/authentication/sessions_controller.rb` |
| Controller | `app/controllers/authentication/registrations_controller.rb` |
| View | `app/views/onboarding/adopter/` → `individual/` |
| View | `app/views/authentication/sessions/new_adopter.*` → `new_individual.*` |
| View | `app/views/authentication/sessions/_adopter_form.*` → `_individual_form.*` |
| Policy | `app/policies/adopter_profile_policy.rb` → `individual_profile_policy.rb` |
| Route | `config/routes.rb` |
| i18n | `config/locales/en.yml`, `es.yml` |
| i18n | `config/locales/adoptions/en.yml` |
| Factory | `spec/factories/adopter_profiles.rb` → `individual_profiles.rb` |
| Spec | `spec/models/adopter_profile_spec.rb` → `individual_profile_spec.rb` |
| Spec | `spec/lib/onboarding/adopter/*` → `individual/*` |
| Spec | `spec/requests/onboarding/adopter/*` → `individual/*` |
| Spec | All files referencing `:adopter` role in factories |

### Phase 2 — Publishing

| Type | File(s) |
|------|---------|
| Migration | `db/migrate/*_add_publisher_to_pets.rb` |
| Migration | `db/migrate/*_make_shelter_id_nullable.rb` |
| Model | `app/models/pet.rb` (associations, validations) |
| Model | `app/models/user.rb` (published_pets association) |
| Model | `app/models/adoption_request.rb` (optional shelter) |
| Service | `lib/pets/publish.rb` (new) |
| Service | `lib/pets/update.rb` (modify) |
| Service | `lib/pets/change_status.rb` (modify) |
| Service | `lib/pets/search.rb` (modify) |
| Service | `lib/adoptions/submit_request.rb` (modify) |
| Service | `lib/adoptions/process_request.rb` (modify) |
| Service | `lib/adoptions/notify_shelter.rb` (modify or new notify_publisher) |
| Controller | `app/controllers/my/pets_controller.rb` (new) |
| Controller | `app/controllers/my/photos_controller.rb` (new) |
| Controller | `app/controllers/my/adoption_requests_controller.rb` (new) |
| Controller | `app/controllers/my/adoption_requests/decisions_controller.rb` (new) |
| Controller | `app/controllers/dashboard_controller.rb` (modify) |
| Controller | `app/controllers/pets_controller.rb` (modify index) |
| View | `app/views/my/pets/` (new directory) |
| View | `app/views/my/adoption_requests/` (new directory) |
| View | `app/views/pets/_pet_card.html.erb` (modify) |
| View | `app/views/pets/show.html.erb` (modify) |
| View | `app/views/dashboard/index.html.erb` (modify) |
| Policy | `app/policies/pet_policy.rb` (modify) |
| Policy | `app/policies/adoption_request_policy.rb` (modify) |
| Route | `config/routes.rb` (add `namespace :my`) |
| Mailer | `app/mailers/adoption_mailer.rb` (modify) |
| Mailer views | `app/views/adoption_mailer/` (modify) |
| i18n | `config/locales/en.yml`, `es.yml` (add dashboard keys) |
| i18n | `config/locales/pets/en.yml`, `es.yml` (add publisher keys) |

### Phase 3 — Cleanup

| Type | File(s) |
|------|---------|
| All files | Remove deprecated aliases, update specs, fix stale comments |

---

## 13. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **Breaking existing adopter accounts** during role rename | Medium | High | Run migration in transaction, test with production-like data. Keep `adopter?` as alias. |
| **Links/bookmarks to `/onboarding/adopter/*` break** | High | Medium | Add route redirects from old paths to new ones. Keep during transition. |
| **API clients sending "adopter" role** | Low (MVP stage) | Low | Accept "adopter" in params and normalize to "individual" during transition. |
| **Search complexity** — mixing shelter and individual pets in search results | Medium | Medium | Use LEFT JOIN, add publisher_type virtual column. Thorough testing of search query. |
| **Individual publisher spam or abuse** | Medium | High | Add rate limiting for pet publishing. Consider phone verification requirement for publishers. |
| **Feature creep** — trying to build too much at once | Medium | Medium | Phase the work. Phase 1 is just rename. Phase 2 adds publishing. Don't add messaging/chat in this scope. |

---

## 14. Open Questions

1. **Naming**: Is `individual` the right term? Alternatives: `person`, `community_member`, `member`. The key is that it contrasts clearly with "shelter" (organization).
2. **AdoptionRequest decisions**: When an individual publishes and also wants to adopt the same pet (unlikely), what happens?
3. **Verification**: Should individual publishers be required to verify their identity (phone, ID) before publishing? Current MVP likely does not require this, but the model should support it.
4. **Pet transfer**: If an individual publishes a pet and a shelter wants to take over, should there be a transfer mechanism? Out of scope for MVP.
5. **Onboarding for publishers**: Should individual publishers be required to complete the adoption-oriented onboarding before publishing? Probably not — the onboarding questions are about adoption preferences, not publishing. A publisher might never adopt.
6. **Display name**: Should the individual's name be shown on the pet listing, or should it be anonymous ("Listed by a community member")? Privacy consideration.

---

## 15. Not in Scope (for this implementation)

- Messaging/chat between individual publishers and adopters (handled by `Messaging::*` services when implemented)
- AI life previews for individual-listed pets (can be added later)
- Verification/trust system for individual publishers
- Fee/payment processing
- Transfer of pets between shelters and individuals
- Mobile app changes

---

## 16. Success Metrics

| Metric | How to Measure |
|--------|---------------|
| Individual publishers can sign up and publish a pet | E2E test passes |
| Existing adopter accounts continue working after migration | All existing specs pass |
| Individual-listed pets appear in search results | Search query returns them correctly |
| Individual publishers receive and can respond to adoption requests | Request flow works end-to-end |
| Zero regression in shelter publishing flow | Shelter publishing specs pass unchanged |
| i18n coverage complete | No `t()` fallbacks in views |
