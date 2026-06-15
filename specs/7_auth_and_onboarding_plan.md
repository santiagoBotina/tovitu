# Plan: Authentication & Onboarding Flows

**Domain:** Authentication, User Profiles, Onboarding
**Priority:** 1 (foundation — supersedes `1_authentication_plan.md`)
**Status:** Draft

---

## Overview

This plan extends and partially supersedes the existing `1_authentication_plan.md`. The original plan assumed no adopter accounts in MVP. This revision introduces two distinct user roles — **adopter** and **shelter user** — each with separate login entry points, sign-up flows, and post-registration onboarding. The shelter user role encompasses both shelter admins and staff (as originally defined in `1_authentication_plan.md`).

### What changes from the original plan?

| Aspect | Original (`1_authentication_plan.md`) | New Plan |
|--------|--------------------------------------|----------|
| Adopter accounts | ❌ Not in MVP | ✅ Full accounts with login/signup |
| Login entry points | Single `/login` | Two: `/:locale/login/adopter` and `/:locale/login/shelter` |
| Admin login URL | Separate `/login/admin` | ❌ No separate URL — embedded in shelter flow |
| Landing page | None | Role-selection landing page at root |
| Post-registration | Redirect to shelter creation | Role-specific onboarding questionnaire |
| User model | Single `User` with role enum | Two models or STI: `Adopter` and `ShelterUser` |
| Role granularity | admin / staff | adopter / shelter_admin / shelter_staff |

---

## Scope

### In Scope (MVP)

- **Landing page** at `/:locale/` with role selection ("Start Adoption Journey" / "I represent a shelter")
- **Adopter authentication** — sign-up, login, password reset, email verification
- **Shelter user authentication** — sign-up, login, password reset, email verification (extends original plan)
- **Admin login embedded** within shelter login flow (no `/login/admin` URL) — admins log in via `/:locale/login/shelter` and are identified by role
- **Adopter onboarding** — 8-question conversational flow after first sign-up/login
- **Shelter onboarding** — 7-question conversational flow after first sign-up/login
- **Profile attributes** — structured profile data from onboarding responses for both roles
- **Session management** — login/logout, session expiry, concurrent sessions

### Out of Scope (Post-MVP)

- OAuth (Google/Meta/WhatsApp) login
- Magic-link authentication
- Adopter profile editing after onboarding (basic editing OK, but full profile management deferred)
- Shelter onboarding editing after completion
- Multi-language onboarding content
- AI-powered adopter-shelter matching from onboarding data (Phase 5)

---

## User Stories

### Authentication

1. As a **new adopter**, I want to **create an account** so that I can browse pets and submit adoption applications.
2. As a **returning adopter**, I want to **log in** so that I can continue my adoption journey.
3. As a **shelter staff member**, I want to **create an account** so that I can manage my shelter's pets and adoption requests.
4. As a **returning shelter user**, I want to **log in** so that I can access my shelter dashboard.
5. As a **shelter admin**, I want to **log in via the shelter login page** so that I can manage my shelter (no separate admin URL needed).
6. As a **registered user**, I want to **reset my password** so that I can regain access if I forget it.
7. As a **user**, I want to **log out** so that I can securely end my session.

### Landing & Role Selection

8. As a **visitor**, I want to **see a clear landing page** where I can choose my path — adopting or representing a shelter — so that I know where to go.
9. As a **visitor**, I want the **correct login/sign-up form to appear** based on my selection so that I don't have to search for the right form.

### Adopter Onboarding

10. As a **new adopter**, I want to **complete a short, conversational onboarding** after signing up so that the platform understands my lifestyle and preferences.
11. As a **new adopter**, I want to **answer questions using cards and chips** (not long forms or dropdowns) so that it feels quick and engaging (< 2 minutes).
12. As an **adopter**, I want my **onboarding responses to shape my profile** so that shelters can see who I am and pets can be recommended to me.

### Shelter Onboarding

13. As a **new shelter user**, I want to **complete a tailored onboarding** so that the platform understands my organization's needs and processes.
14. As a **shelter admin**, I want my **onboarding responses to shape our shelter profile** so that we present accurate information to potential adopters.

---

## Acceptance Criteria

### AC1: Landing / Role Selection Page

```
Given I am a visitor to Tovitu
When I navigate to the root URL (/:locale/)
Then I see a landing page with two clear options:
  - "Start Adoption Journey" (primary CTA)
  - "I represent a shelter" (secondary CTA)
And each option has a distinct visual treatment (icon/illustration)
And I see the Tovitu brand and a brief value proposition

Given I click "Start Adoption Journey"
When the page transitions
Then I am shown the adopter login/sign-up form

Given I click "I represent a shelter"
When the page transitions
Then I am shown the shelter login/sign-up form
```

### AC2: Adopter Login

```
Given I am on the adopter login form (/:locale/login/adopter)
When I enter a valid email and password for an existing adopter account
Then I am authenticated
And I am redirected to the adopter dashboard (or pet browsing page)

Given I am on the adopter login form
When I enter an incorrect email or password
Then I see a generic "Invalid email or password" error
And I am not told which field is incorrect

Given my adopter account is unverified
When I attempt to log in with valid credentials
Then I am not logged in
And I see a "Please verify your email" message
And a new verification email is sent
```

### AC3: Shelter User Login

```
Given I am on the shelter login form (/:locale/login/shelter)
When I enter a valid email and password for an existing shelter user
Then I am authenticated
And I am redirected to the shelter dashboard

Given I am a shelter admin
When I log in via /:locale/login/shelter
Then I access my shelter dashboard with admin permissions
And no separate admin login URL was needed

Given I am a shelter staff member (not admin)
When I log in via /:locale/login/shelter
Then I access my shelter dashboard with staff-level permissions
```

### AC4: Sign-Up (Both Roles)

```
Given I am on the login form for [adopter|shelter]
When I click "Create account" / "Sign up"
Then I see a registration form with: name, email, password, password confirmation

Given I submit a valid registration for [adopter|shelter]
When all fields pass validation
Then my account is created with status "unverified"
And a verification email is sent
And I am redirected to a "Check your email" page
And the role is set to [adopter|shelter_admin|shelter_staff]

Given I click the verification link in my email
When the link is valid and not expired
Then my account is marked as verified
And I am logged in automatically

Given this is my first login (account just verified)
Then I am redirected to the onboarding flow (not the dashboard)
```

### AC5: Adopter Onboarding — Interactive Flow

```
Given I am a newly verified adopter on their first login
When the onboarding begins
Then I see a conversational, single-page interactive flow with 8 questions
And the flow is designed to complete in < 2 minutes
And I can see my progress (e.g., "Question 3 of 8")

Given I am on question 1 ("What does a typical weekend look like for you?")
When I see the options
Then they are presented as multi-select chips/cards:
  - Relaxing at home
  - Going for walks
  - Outdoor adventures
  - Spending time with family
  - Exercising or sports
  - Visiting friends
  - Exploring new places
And I can select multiple options
And I can proceed after selecting at least one

Given I am on question 2 ("How active would you describe yourself?")
When I see the options
Then they are presented as single-select illustrated buttons:
  - Very calm
  - Mostly calm
  - Balanced
  - Active
  - Very active
And I can only select one

Given I am on question 3 ("Which sounds most like your ideal companion?")
When I see the options
Then they are presented as single-select cards with icons:
  - Calm friend
  - Playful companion
  - Affectionate pet
  - Independent pet
  - Social pet
And I can only select one

Given I am on question 4 ("How much experience do you have with pets?")
When I see the options
Then they are presented as single-select buttons:
  - First-time
  - Some experience
  - Years of experience
  - Very experienced
And I can only select one

Given I am on question 5 ("What are you hoping to gain from adopting?")
When I see the options
Then they are presented as multi-select chips:
  - Daily companion
  - More activity
  - Emotional support
  - Family pet
  - Friend for another pet
  - Meaningful way to help
And I can select multiple options

Given I am on question 6 ("How much time can you realistically dedicate to a pet each day?")
When I see the options
Then they are presented as single-select cards with time icons:
  - Less than 1 hour
  - 1–2 hours
  - 2–4 hours
  - More than 4 hours
And I can only select one

Given I am on question 7 ("Which personality feels closest to yours?")
When I see the options
Then they are presented as single-select cards with personality illustrations:
  - Calm and thoughtful
  - Friendly and social
  - Adventurous and energetic
  - Organized and routine-oriented
  - Flexible and spontaneous
And I can only select one

Given I am on question 8 ("What matters most to you when adopting a pet?")
When I see the input
Then it is a short text input with a 200-character maximum
And there is placeholder text prompting reflection
And I can optionally skip or submit blank

Given I complete all 8 questions
When I submit the onboarding
Then my responses are saved to my adopter profile
And I am redirected to the adopter dashboard / pet discovery page
And I see a "Profile complete!" success message

Given I close the browser mid-onboarding
When I return and log in
Then I am resumed at the question I left off (responses saved incrementally)
```

### AC6: Shelter Onboarding — Interactive Flow

```
Given I am a newly verified shelter user on their first login
When the onboarding begins
Then I see a conversational, single-page interactive flow with 7 questions
And the flow is designed to complete in < 2 minutes

Given I am on question 1 ("What best describes your organization?")
When I see the options
Then they are presented as single-select cards with icons:
  - Small rescue group
  - Independent shelter
  - Large shelter
  - NGO / Foundation
  - Foster-based rescue
And I can only select one

Given I am on question 2 ("Approximately how many pets do you currently manage?")
When I see the options
Then they are presented as single-select buttons:
  - Fewer than 20
  - 20–50
  - 50–100
  - More than 100
And I can only select one

Given I am on question 3 ("How involved are you in the adoption process?")
When I see the options
Then they are presented as single-select cards:
  - Basic screening (applications + approvals)
  - Interviews and follow-ups
  - Extensive matching (home visits, vet checks)
  - Long-term support (post-adoption follow-ups)
And I can only select one

Given I am on question 4 ("What matters most when approving an adopter?")
When I see the options
Then they are presented as multi-select chips:
  - Stable home
  - Previous pet experience
  - Available time
  - Financial preparedness
  - Family compatibility
  - Long-term commitment
And I can select multiple

Given I am on question 5 ("How do you usually communicate with adopters?")
When I see the options
Then they are presented as multi-select chips with icons:
  - WhatsApp
  - Email
  - Phone calls
  - In-person
  - Social media
And I can select multiple

Given I am on question 6 ("What is your biggest challenge today?")
When I see the options
Then they are presented as multi-select chips:
  - Finding qualified adopters
  - Managing applications
  - Following up with applicants
  - Communicating with adopters
  - Managing pet information
  - Tracking adoption outcomes
And I can select multiple

Given I am on question 7 ("What matters most to you when approving an adoption?")
When I see the input
Then it is a short text input with a 200-character maximum
And there is placeholder text prompting reflection
And I can optionally skip or submit blank

Given I complete all 7 questions
When I submit the onboarding
Then my responses are saved to the shelter profile
And I am redirected to the shelter dashboard with a welcome banner
And I see a "Profile complete! Let's set up your shelter" success message
```

### AC7: Session Management

```
Given I am logged in as any user type
When I click "Log out"
Then my session is destroyed
And I am redirected to the landing page

Given I have an active session
When I do not interact with the platform for 24 hours
Then my session expires
And I am prompted to log in on my next request

Given I am logged in on multiple devices
When I log in on a new device
Then my existing sessions remain active (concurrent sessions allowed)
```

### AC8: Profile Attributes from Onboarding

```
Given an adopter has completed onboarding
When any system component reads the adopter's profile
Then the following structured attributes are available:
  - weekend_activity: [array of selected options]
  - activity_level: very_calm | mostly_calm | balanced | active | very_active
  - ideal_companion: calm_friend | playful_companion | affectionate_pet | independent_pet | social_pet
  - pet_experience: first_time | some_experience | years_of_experience | very_experienced
  - adoption_goals: [array of selected options]
  - daily_time_available: less_than_1h | 1_to_2h | 2_to_4h | more_than_4h
  - personality: calm_thoughtful | friendly_social | adventurous_energetic | organized_routine | flexible_spontaneous
  - adoption_priority: [free text, max 200 chars]

Given a shelter user has completed onboarding
When any system component reads the shelter's profile
Then the following structured attributes are available:
  - organization_type: small_rescue | independent_shelter | large_shelter | ngo_foundation | foster_based
  - pet_count_range: under_20 | 20_to_50 | 50_to_100 | over_100
  - adoption_involvement: basic_screening | interviews | extensive_matching | long_term_support
  - approval_priorities: [array of selected options]
  - communication_channels: [array of selected options]
  - biggest_challenges: [array of selected options]
  - approval_philosophy: [free text, max 200 chars]
```

---

## Business Rules

1. **Email uniqueness** — email must be unique across ALL user types (adopter + shelter user). A single email cannot be used for both roles.
2. **Password strength** — minimum 8 characters. No complexity requirements for MVP.
3. **Session duration** — sessions expire after 24 hours of inactivity or 30 days absolute maximum.
4. **Rate limiting** — max 5 failed login attempts per email per 15 minutes. Account locked for 15 minutes after that.
5. **Verification expiry** — email verification links expire after 24 hours.
6. **Password reset expiry** — reset tokens expire after 1 hour.
7. **Onboarding is one-time** — onboarding is presented only on first login after email verification. Users cannot re-take onboarding in MVP (requires shelter/admin action to reset).
8. **Onboarding progress persistence** — if user abandons mid-onboarding, progress is saved per-question so they resume where they left off.
9. **Onboarding completion required for full access** — adopters cannot browse pets or apply until onboarding is complete. Shelter users cannot access their dashboard until onboarding is complete.
10. **Adopter role separation** — an adopter account cannot manage a shelter. A shelter user cannot adopt pets (same account cannot have both roles — use separate accounts).
11. **Audit logging** — log all login attempts (success/failure/IP/timestamp), onboarding completions, and profile changes.
12. **Concurrent sessions** — allow multiple sessions per user.
13. **Soft delete** — accounts are soft-deleted (discarded_at) rather than hard-deleted in MVP.

---

## User Flow

### Landing → Authentication → Onboarding (Complete Journey)

```
1. VISITOR arrives at /:locale/
2. Visitor sees landing page with two paths
3. Visitor selects path:
   a. "Start Adoption Journey" → adopter login/sign-up form
   b. "I represent a shelter" → shelter login/sign-up form
4. Visitor either:
   a. Logs in (existing user) → if onboarding complete → dashboard/pets
                               → if onboarding NOT complete → onboarding flow
   b. Signs up (new user) → verification email → clicks link → auto-logged in → onboarding flow
5. ONBOARDING FLOW:
   - Adopter: 8 conversational questions with card/chip UI
   - Shelter: 7 conversational questions with card/chip UI
6. Onboarding saved → user redirected to appropriate destination
   - Adopter: /:locale/pets (pet discovery)
   - Shelter: /:locale/shelter/dashboard (shelter management)
```

### Adopter Authentication Flow (Detailed)

```
1. Visitor clicks "Start Adoption Journey" on landing page
2. URL: /:locale/login/adopter
3. Form shows two tabs or toggle: "Log in" / "Sign up"
4. If Sign up:
   a. Fields: full name, email, password, confirm password
   b. Submit → Account created (verified: false), verification email sent
   c. "Check your email" page shown
   d. User clicks verification link → verified, auto-logged in
   e. First login detected → onboarding flow triggered
5. If Log in:
   a. Fields: email, password
   b. If valid + verified → logged in
   c. If first login after verify → onboarding
   d. If returning → redirect to pets index
   e. If valid + unverified → "verify your email" error, resend
   f. If invalid → generic error
   g. If locked out → lockout message
```

### Shelter User Authentication Flow (Detailed)

```
1. Visitor clicks "I represent a shelter" on landing page
2. URL: /:locale/login/shelter
3. Same login/sign-up toggle as adopter flow
4. Sign up → creates shelter user (role: shelter_admin for first user)
5. First login → shelter onboarding flow
6. Returning → shelter dashboard
7. Shelter admin embeds in this flow — no unique URL.
   Admins and staff are distinguished by their role attribute, not by login URL.
```

### Onboarding Interaction Flow (Both Roles)

```
1. Onboarding loads as a single-page interactive component (Turbo/Stimulus)
2. Questions presented one at a time with transitions
3. Progress bar shows "Question X of Y"
4. Each question type:
   - Multi-select: chip buttons, toggle on/off, minimum 1 selection
   - Single-select: card buttons, click to select, auto-advance or "Next" button
   - Text: textarea with character counter, optional
5. "Back" button available to revise previous answers
6. On final question: "Complete Profile" button
7. Submission saves all answers as structured data via API
8. Redirect to destination
```

---

## Edge Cases & Error States

| Edge Case | Handling |
|-----------|----------|
| User registers with existing email | Show "email already taken" error on form — same error for both roles |
| Same email used for adopter + shelter | Prevent — email uniqueness is global across all user types |
| Verification link clicked twice | First click verifies; second shows "already verified" with login link |
| User never receives verification email | "Resend verification" link on login page + "Check spam" tip |
| User closes browser mid-onboarding | Progress saved per-question; resume on next login |
| User tries to skip onboarding | Onboarding is mandatory — redirect back until complete |
| User submits onboarding with 0 selections on multi-select | Show inline validation — "Please select at least one option" |
| User enters >200 chars on text question | Character counter prevents exceeding limit; server-side truncation/validation |
| Adopter logs in but hasn't completed onboarding | Redirect to onboarding — cannot access pets or applications |
| Shelter user logs in but hasn't completed onboarding | Redirect to onboarding — cannot access dashboard |
| User with multiple tabs logs out in one | Other tab's next request redirects to landing page |
| Brute force attack | Rate limiting + lockout + audit logging |
| Email delivery fails | Log error, show "verification email could not be sent" with retry option |
| User deletes account | MVP: soft-delete (discarded_at); future: hard-delete after grace period |
| Token tampering | Tokens are signed (using SignedId / has_secure_token); invalid tokens show error |
| Admin accidentally creates staff account instead of admin | Only first user of a shelter gets admin role. Admin can promote staff via shelter settings. |
| Onboarding data contains profanity or offensive content | Basic server-side sanitization; defer advanced filtering to post-MVP |
| User is adopter + shelter staff (unusual) | Require separate accounts with different emails — no dual-role accounts |
| Shelter admin logs in before completing shelter registration | Shelter onboarding includes org details; redirect to complete if missing |

---

## Design Principles (Onboarding)

| Principle | Implementation |
|-----------|---------------|
| **Conversational tone** | Questions use natural language ("What does a typical weekend look like for you?") not form labels ("Weekend activity preference") |
| **< 2 minutes completion** | Max 8 questions, card-based selection, minimal text input, no loading between questions |
| **Card selection** | Each option is a visually distinct card with icon/illustration, tap/click to select |
| **Multi-select chips** | Chips toggle on/off with visual feedback; clear "X selected" indicator |
| **Single-choice buttons** | Pill buttons or cards that de-select others on tap |
| **No dropdowns** | Zero `<select>` elements in the entire onboarding flow |
| **No multi-page** | Single scrollable page or single-question-at-a-time with smooth transitions |
| **Mobile-first** | Cards stack vertically, touch targets ≥ 44px, no hover-dependent interactions |
| **Progress visibility** | "Question 3 of 8" + progress bar filling incrementally |
| **Illustrations** | Each question has a relevant illustration or emoji for visual engagement |
| **Back navigation** | Users can go back and change answers before final submission |
| **Skip option** | Text questions are optional; show "Skip" link for free-text fields |

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Landing page → login click rate | > 60% of visitors click a path |
| Registration completion rate (sign-up → verified) | > 70% |
| Onboarding completion rate (started → finished) | > 85% |
| Average onboarding completion time | < 2 minutes |
| Login success rate | > 95% |
| Password reset success rate | > 80% |
| Account lockout rate | < 5% of login attempts |
| Adopter onboarding abandonment rate | < 15% |
| Shelter onboarding abandonment rate | < 10% |
| Mobile onboarding completion rate | > 80% (comparable to desktop) |

---

## Dependencies / Prerequisites

- **Rails 8** `has_secure_password` + `authenticate_by` (already in place)
- **User model refactoring** — either STI (`Adopter`, `ShelterUser`) or role-based single `User` model with polymorphic profile
- **Onboarding models** — `AdopterProfile` / `ShelterProfile` to store structured onboarding data
- **Action Mailer** — verification emails, password reset (letter_opener for dev)
- **Hotwire (Turbo + Stimulus)** — for single-page onboarding interaction without full SPA
- **TailwindCSS** — for card/chip/button styling (already configured)
- **i18n** — all onboarding content in `config/locales/*.yml`

---

## Open Questions / Risks

1. **Single User model vs STI?** — A single `User` model with `role` enum (adopter / shelter_admin / shelter_staff) is simpler for authentication (one sessions controller, one `authenticate_by`). But it means shared validations and a single table for both types. STI (`Adopter < User`, `ShelterUser < User`) gives more flexibility but adds complexity. **Decision: Single `User` model with `role` enum + polymorphic `profile` association.** This keeps auth simple while allowing different profile data.

2. **Onboarding progress storage?** — Save question-by-question via AJAX (Turbo Streams) or save only on completion? **Decision: Save incrementally** to prevent data loss from abandonment. Each question triggers a background save as the user proceeds.

3. **Should adopters see pet recommendations after onboarding?** — Pets could be filtered by onboarding responses. This is a Phase 5 (AI) feature but a basic filter could surface relevant pets immediately. **Deferred to implementation discussion.**

4. **Adopter dashboard vs straight to pets?** — After onboarding, should adopters land on a dashboard or directly on the pet directory? **Decision: Pet directory** for MVP. A dashboard adds unnecessary complexity for a first-time adopter.

5. **Shelter onboarding + shelter registration merge?** — The original 2_shelters_plan.md requires shelter registration (name, address, etc.) after auth. The new onboarding covers org culture/preferences. How do these relate? **Decision: Onboarding comes first (after email verification), then redirect to shelter registration form** to collect name, address, etc. as defined in 2_shelters_plan.md. The onboarding data feeds into the shelter's profile.

6. **Onboarding content localization?** — All onboarding questions and options must support i18n (English + Spanish per 6_i18n_plan.md). This adds translation overhead but is architecturally required.

7. **Adoption applications linked to adopter accounts vs anonymous?** — The existing `4_adoptions_plan.md` assumes anonymous applications. With adopter accounts, applications can be linked to the adopter's user record. **Decision: Support both — adopter accounts are primary, but anonymous applications via token links remain as fallback.** This preserves the existing adoption flow while enabling richer profiles.

---

## Technical Notes

### Models

```
User
  - email (string, unique, not null)
  - password_digest (string, not null)
  - name (string, not null)
  - role (string, not null) — "adopter" | "shelter_admin" | "shelter_staff"
  - verified_at (datetime, nullable)
  - onboarding_completed_at (datetime, nullable)
  - discarded_at (datetime, nullable)
  - shelter_id (bigint, nullable) — belongs_to :shelter (only for shelter users)

AdopterProfile
  - user_id (bigint, not null, unique)
  - weekend_activity (jsonb, default: [])
  - activity_level (string, nullable)
  - ideal_companion (string, nullable)
  - pet_experience (string, nullable)
  - adoption_goals (jsonb, default: [])
  - daily_time_available (string, nullable)
  - personality (string, nullable)
  - adoption_priority (string, nullable) — max 200 chars
  - onboarding_step (integer, default: 0) — tracks progress through questions

ShelterProfile
  - shelter_id (bigint, not null, unique) — or user_id if pre-shelter-creation
  - organization_type (string, nullable)
  - pet_count_range (string, nullable)
  - adoption_involvement (string, nullable)
  - approval_priorities (jsonb, default: [])
  - communication_channels (jsonb, default: [])
  - biggest_challenges (jsonb, default: [])
  - approval_philosophy (string, nullable) — max 200 chars
  - onboarding_step (integer, default: 0)
```

### Controllers

- `LandingController` — root landing page with role selection
- `Authentication::SessionsController` — create/destroy sessions (handles both adopter + shelter)
- `Authentication::RegistrationsController` — register new users (role-aware)
- `Authentication::PasswordsController` — forgot/reset password
- `Authentication::VerificationsController` — email verification
- `Onboarding::Adopter::QuestionsController` — adopter onboarding CRUD
- `Onboarding::Shelter::QuestionsController` — shelter onboarding CRUD

### Service Objects

- `Authentication::RegisterUser` — registration with role assignment
- `Authentication::AuthenticateUser` — login with role-aware redirect
- `Authentication::SendVerificationEmail` — verification email
- `Authentication::VerifyEmail` — token verification
- `Authentication::ResetPassword` — password reset
- `Onboarding::Adopter::SaveResponse` — saves single question response
- `Onboarding::Adopter::Complete` — finalizes onboarding, marks as complete
- `Onboarding::Shelter::SaveResponse` — saves single question response
- `Onboarding::Shelter::Complete` — finalizes onboarding, marks as complete
- `Onboarding::DetermineDestination` — where to redirect after onboarding based on role

### Routes

```
# Landing
root "landing#index"

# Authentication
scope "(:locale)", locale: /en|es/ do
  get "login/adopter", to: "authentication/sessions#new_adopter"
  get "login/shelter", to: "authentication/sessions#new_shelter"
  
  resource :session, only: [:create, :destroy], controller: "authentication/sessions"
  resource :registration, only: [:new, :create], controller: "authentication/registrations"
  resources :password_resets, only: [:new, :create, :edit, :update], controller: "authentication/passwords"
  resource :verification, only: [:show], controller: "authentication/verifications"
  
  # Onboarding
  namespace :onboarding do
    namespace :adopter do
      resource :questions, only: [:show, :update]  # single-page interactive
      resource :completion, only: [:create]         # finalize
    end
    namespace :shelter do
      resource :questions, only: [:show, :update]
      resource :completion, only: [:create]
    end
  end
end
```

### Stimulus Controllers (Frontend)

- `onboarding-controller.js` — manages question progression, animation, progress bar
- `multi-select-controller.js` — chip toggle behavior for multi-select questions
- `single-select-controller.js` — card/pill selection for single-select questions
- `character-count-controller.js` — text input character counter for text questions

### Testing Notes

- Request specs for all auth flows (adopter + shelter)
- Request specs for onboarding submission (valid data, partial data, abandonment)
- Test that unverified users cannot access authenticated pages
- Test that onboarding-incomplete users are redirected back to onboarding
- Test onboarding progress persistence with `travel_to` for session scenarios
- Test rate limiting on login attempts
- Test role-based redirect after login (adopter → pets, shelter → dashboard)
- Test that shelter admin login does NOT have a separate URL path

---

## Relationship to Existing Plans

| Existing Plan | How This Plan Relates |
|---------------|----------------------|
| `1_authentication_plan.md` | ⚠️ **Partially superseded.** Role model expanded (adds adopter), login URLs restructured, landing page added. The shelter user auth (session management, password reset, verification) carries forward. |
| `2_shelters_plan.md` | ➕ **Extended.** Shelter onboarding (questions 1–7 above) feeds into the shelter profile. After onboarding, the user continues to shelter registration (name, address, etc.) as originally defined. |
| `4_adoptions_plan.md` | 🔗 **Linked.** Adopter onboarding data (`AdopterProfile`) provides structured data that can pre-fill adoption applications and feed AI compatibility analysis (Phase 5). |
| `6_i18n_plan.md` | 🔗 **Dependent.** All onboarding questions, options, and error messages must use locale keys. The onboarding flow must respect the `/:locale/` prefix. |

---

## Rejected Alternatives

| Alternative | Why Rejected |
|-------------|--------------|
| Devise gem for auth | Adds bloat for MVP. Rails built-in `has_secure_password` + `authenticate_by` is sufficient. Complexity of customizing Devise for two user types outweighs benefits. |
| Single login URL with role dropdown | Poor UX — forces users to self-identify with a dropdown. Two clear entry points is more user-friendly and allows role-specific UI (branding, messaging). |
| Separate admin login page (`/login/admin`) | Security through obscurity is not security. Embedding admin in shelter flow is simpler and avoids an extraneous route. Admins are identified by role, not URL. |
| Multi-page questionnaire for onboarding | Violates <2min design goal. Single-page with smooth transitions keeps users engaged and reduces abandonment. |
| No adopter accounts (as original plan) | Adopter accounts enable personalization, application tracking, AI matching, and retention (post-adoption follow-ups). Anonymous-only limits the platform's core value. |
| Third-party onboarding tool (Typeform, etc.) | Adds external dependency, cost, and UX inconsistency. Native Hotwire/Stimulus implementation is lightweight and keeps the experience cohesive. |
