# Plan: Authentication

**Domain:** Authentication
**Priority:** 1 (foundation for all other features)
**Status:** Draft

---

## User Stories

1. As a **shelter staff member**, I want to **create an account** so that I can manage my shelter's pets and adoption requests.
2. As a **registered user**, I want to **log in and log out** so that I can securely access my account.
3. As a **user**, I want to **reset my password** so that I can regain access if I forget it.
4. As a **shelter admin**, I want **role-based access** so that staff have appropriate permissions.
5. As a **user**, I want to **update my profile** so that my contact information stays current.
6. As an **API client**, I want **session-based authentication** so that API requests are authenticated.

---

## Description

Authentication is the foundational layer of the Tovitu platform. It enables shelters to register, staff to access their portals, and adopters to manage their applications. We use Rails' built-in `has_secure_password` (bcrypt) with `authenticate_by` for session management — no Devise or other auth gems.

The MVP supports two roles: **shelter admin** (full access to a shelter's management) and **shelter staff** (limited access scoped to assigned tasks). Adopters do not have accounts in the MVP; they interact via WhatsApp or email links. A future phase may add adopter accounts.

Password resets use token-based emails (Action Mailer with letter_opener in dev).

---

## Acceptance Criteria

### AC1: Registration
```
Given I am a new shelter staff member
When I submit a registration with name, email, password, and password confirmation
Then I receive a confirmation email
And my account is created but marked as unverified
And I am redirected to a "check your email" page

Given I click the verification link in my email
When the link is valid and not expired
Then my account is marked as verified
And I am logged in automatically
And I am redirected to my shelter dashboard
```

### AC2: Login
```
Given I have a verified account
When I submit valid email and password
Then I am logged in
And a session is created
And I am redirected to my dashboard

Given I have a verified account
When I submit an incorrect password
Then I am not logged in
And I see an "invalid email or password" error
And I am not told which field is incorrect (security)

Given my account is unverified
When I attempt to log in with valid credentials
Then I am not logged in
And I see a "please verify your email" message
And a new verification email is sent
```

### AC3: Logout
```
Given I am logged in
When I click "Log out"
Then my session is destroyed
And I am redirected to the login page
And I cannot access authenticated pages
```

### AC4: Password Reset
```
Given I have a verified account
When I request a password reset for my email
Then I receive a password reset email with a token link

Given I have a valid password reset token
When I submit a new password and confirmation
Then my password is updated
And I am logged in automatically
And the reset token is consumed (cannot be reused)

Given I have an expired password reset token
When I attempt to use it
Then I see a "link expired" error
And I am prompted to request a new reset
```

### AC5: Profile Management
```
Given I am logged in
When I update my name or email
Then my profile is updated
And I see a success message

Given I am logged in
When I change my email
Then a verification email is sent to the new address
And my email is marked as unverified until confirmed
```

### AC6: Authorization
```
Given I am a shelter staff member (not admin)
When I attempt to access shelter billing settings
Then I receive a 403 Forbidden response
And I am redirected to my dashboard with an error message

Given I am not logged in
When I attempt to access any authenticated page
Then I am redirected to the login page
```

---

## Business Rules

1. **Email uniqueness** — email must be unique across all users (case-insensitive).
2. **Password strength** — minimum 8 characters. No complexity requirements for MVP (can be added later).
3. **Session duration** — sessions expire after 24 hours of inactivity or 30 days absolute maximum.
4. **Rate limiting** — max 5 failed login attempts per email per 15 minutes. Account locked for 15 minutes after that.
5. **Verification expiry** — email verification links expire after 24 hours.
6. **Password reset expiry** — reset tokens expire after 1 hour.
7. **No adopter accounts** in MVP — adopters interact anonymously or via messaging.
8. **Audit logging** — log all login attempts (success/failure/IP/timestamp) for security monitoring.
9. **Concurrent sessions** — allow multiple sessions per user (they can be logged in on desktop + mobile).

---

## User Flow

### Registration Flow
1. User navigates to `/sign_up`
2. User fills in registration form (name, email, password, password confirmation)
3. System validates input (email format, password length, email uniqueness)
4. System creates User record (verified: false), generates verification token
5. System sends verification email
6. User sees "Please check your email" page
7. User clicks link in email
8. System verifies token, marks user as verified, logs user in
9. User is redirected to `/shelters/new` (to create their shelter) or existing shelter dashboard

### Login Flow
1. User navigates to `/login`
2. User enters email and password
3. System authenticates via `User.authenticate_by(email:, password:)`
4. If valid and verified → create session, redirect to dashboard
5. If valid but unverified → show error, re-send verification email
6. If invalid → increment failed attempts, show generic error
7. If locked out → show lockout message with retry time

---

## Edge Cases & Error States

| Edge Case | Handling |
|-----------|----------|
| User registers with existing email | Show "email already taken" error on the form |
| Verification link clicked twice | First click verifies; second shows "already verified" with login link |
| User never receives verification email | Provide "resend verification" link on login page |
| User tries to register with no password | Client + server-side validation |
| User pastes space in email field | Strip whitespace before validation |
| User with multiple tabs logs out in one | Other tab's next request redirects to login |
| Database constraint failure | Catch ActiveRecord::RecordNotUnique, show friendly error |
| Brute force attack | Rate limiting + lockout + audit logging |
| Email delivery fails | Log error, show "verification email could not be sent" with retry option |
| User deletes account | MVP: soft-delete (discarded_at); future: hard-delete after grace period |
| Token tampering | Tokens are signed (using SignedId / has_secure_token); invalid tokens show error |

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Registration completion rate | > 70% (started → verified) |
| Login success rate | > 95% |
| Password reset success rate | > 80% |
| Account lockout rate | < 5% of login attempts |
| Email delivery time | < 30 seconds for 95% of emails |

---

## Dependencies / Prerequisites

- Rails 8 `has_secure_password` (bcrypt gem)
- Action Mailer configured (letter_opener for dev, SendGrid/Mailgun/Postmark for prod)
- User model and migration
- Sessions table or cookie-based sessions (cookie-based for MVP, database sessions if needed later)

---

## Open Questions / Risks

1. **Should adopters have accounts in MVP?** Decision: No. Adopters interact via WhatsApp and email links. Revisit in Phase 7 (post-adoption).
2. **Cookie vs database sessions?** Cookie sessions are simpler. Risk: 4KB size limit. If we store many claims, switch to DB sessions.
3. **Email delivery provider?** To be decided before production. For dev, letter_opener is sufficient.
4. **Should we use Devise?** Decision: No. Rails auth (`has_secure_password` + `authenticate_by`) is sufficient for MVP. Avoids gem bloat and customization overhead.
5. **Magic link login for staff?** Consider as alternative to passwords for Phase 2. Low priority.
6. **OAuth (Google/Meta)?** Not in MVP. Could reduce friction for shelter registration. Evaluate after MVP.

---

## Technical Notes

### Models
```
User
  - email (string, unique, not null)
  - password_digest (string, not null)
  - name (string, not null)
  - role (string, default: "staff") — "admin" | "staff"
  - verified_at (datetime, nullable)
  - discarded_at (datetime, nullable) — for soft deletes
  - shelter_id (bigint, nullable) — belongs_to :shelter
```

### Controllers
- `Authentication::SessionsController` — create/destroy sessions
- `Authentication::RegistrationsController` — register new users
- `Authentication::PasswordsController` — forgot/reset password
- `Authentication::VerificationsController` — email verification

### Service Objects
- `Authentication::RegisterUser` — handles registration with verification token generation
- `Authentication::VerifyEmail` — verifies email token
- `Authentication::ResetPassword` — handles password reset flow
- `Authentication::SendVerificationEmail` — sends verification email

### Routes
```
resource :registration, only: [:new, :create], controller: "authentication/registrations"
resource :session, only: [:new, :create, :destroy], controller: "authentication/sessions"
resources :password_resets, only: [:new, :create, :edit, :update], controller: "authentication/passwords"
resource :verification, only: [:show], controller: "authentication/verifications"
```

### Testing Notes
- Request specs for all auth flows
- No controller specs
- Test token expiry edge cases using `travel_to`
- Test rate limiting with multiple rapid requests
- Test that unverified users cannot access authenticated pages
