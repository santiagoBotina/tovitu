# Plan: Internationalization (i18n) — English & Spanish

**Domain:** Infrastructure / UI
**Priority:** Medium
**Status:** Draft

---

## User Stories

1. As a **Spanish-speaking user**, I want to **use the platform in Spanish** so that I can navigate and understand the interface.
2. As an **English-speaking user**, I want to **use the platform in English** (default) without any extra steps.
3. As a **user**, I want to **switch between languages** easily from any page.
4. As a **shelter admin**, I want **email notifications in my preferred language** so that I can act on them immediately.

---

## Description

The platform currently has ~150 hardcoded English strings across views, controllers, mailers, service objects, presenters, and models. This plan adds Rails i18n infrastructure and Spanish translations with zero external dependencies.

---

## Acceptance Criteria

### AC1: Default Language is English
```
Given a visitor navigates to /
Then the interface is displayed in English
And the URL shows no locale prefix (plain /shelters, /session/new)
```

### AC2: Spanish Language via URL Prefix
```
Given a visitor navigates to /es/shelters
Then the interface is displayed in Spanish
And all navigation links include the /es/ prefix
```

### AC3: Language Switcher
```
Given a visitor is viewing any page
When they click "Español" in the language toggle
Then the page reloads in Spanish with the /es/ prefix
And they remain on the same page
```

### AC4: Mailers Respect Locale
```
Given a user has locale set to es
When they trigger a password reset email
Then the email subject and body are in Spanish
```

### AC5: Error Messages are Translated
```
Given a Spanish-speaking user submits an invalid form
Then validation error messages are shown in Spanish
```

### AC6: Service Errors are Translated
```
Given a Spanish-speaking user tries to create a shelter without verifying email
Then the error message is in Spanish
```

---

## Implementation Approach

### Locale Switching: Path Prefix

All routes wrapped in `scope "(:locale)", locale: /en|es/`. Default locale `:en` means `/shelters` resolves to English. `/es/shelters` resolves to Spanish.

### Service Object Errors

Use `I18n.locale` directly (thread-safe global in Rails). Service objects call `I18n.t("errors.key")` at the point of failure.

### Scope

All user-facing text:
- Views (30 files, ~100 strings)
- Controllers (12 files, ~20 flash messages)
- Mailers (2 files + 6 templates, ~25 strings)
- Service objects (`lib/`, ~20 error messages)
- Presenters (`shelter_presenter.rb`, ~8 strings)
- Models (1 custom validation)
- PWA manifest

---

## Implementation Steps

### Step 1: Locale Configuration

**`config/application.rb`:**
```ruby
config.i18n.default_locale = :en
config.i18n.available_locales = [:en, :es]
```

**`config/initializers/locale.rb`:**
```ruby
Rails.application.config.i18n.fallbacks = true
```

### Step 2: Route Scoping

Wrap all user-facing routes in:
```ruby
scope "(:locale)", locale: /en|es/ do
  # all existing routes
end
```

Health check and root stay unscoped. Root redirects to locale-prefixed path or uses default locale.

### Step 3: Locale Detection

**`app/controllers/application_controller.rb`:**
```ruby
before_action :set_locale

private

def set_locale
  I18n.locale = params[:locale] || I18n.default_locale
end

def default_url_options
  { locale: I18n.locale }
end
```

### Step 4: Translation Files

**`config/locales/en.yml`** — domain-organized keys:

```yaml
en:
  layouts:
    application:
      title: "Tovitu"
  shared:
    error_messages:
      heading: "prohibited this from being saved"
  dashboard:
    index:
      welcome: "Welcome, %{name}"
      role: "You are logged in as %{role}"
      profile:
        title: "Profile"
        description: "Update your name and email"
      logout:
        title: "Log out"
        description: "End your current session"
  shelters:
    index:
      title: "Find a Shelter"
      subtitle: "Browse shelters near you and discover pets waiting for a home."
      city: "City"
      city_placeholder: "Any city"
      state: "State"
      all_states: "All states"
      species: "Species"
      dog: "Dog"
      cat: "Cat"
      other: "Other"
      search: "Search"
      view_shelter: "View Shelter →"
      empty_title: "No shelters found"
      empty_body: "Try adjusting your search filters to find more shelters."
      clear_filters: "Clear all filters"
    new:
      title: "Register Your Shelter"
      subtitle: "Tell us about your shelter to get started."
      name_label: "Shelter Name"
      name_placeholder: "Happy Paws Rescue"
      street_label: "Street Address"
      street_placeholder: "123 Main St"
      city_label: "City"
      city_placeholder: "Portland"
      state_label: "State"
      state_prompt: "Select state"
      zip_label: "ZIP Code"
      zip_placeholder: "97201"
      phone_label: "Phone Number"
      phone_placeholder: "503-555-0123"
      website_label: "Website (optional)"
      website_placeholder: "https://example.com"
      description_label: "About Your Shelter (optional)"
      description_placeholder: "Tell potential adopters about your mission..."
      species_label: "Species Served"
      hours_label: "Hours of Operation (optional)"
      hours_placeholder: "Mon-Fri 9-5, Sat 10-2"
      submit: "Register Shelter"
      login_prompt: "Already have an account?"
      login_link: "Log in"
    show:
      back: "Back to all shelters"
      location: "Location"
      contact: "Contact"
      hours: "Hours"
      adoption_process: "Adoption Process"
      adoption_fee: "Adoption Fee"
      minimum_age: "Minimum Age"
      minimum_age_text: "Adopters must be at least %{age} years old."
      home_visit: "Home Visit"
      home_visit_text: "A home visit is required as part of the adoption process."
      available_pets: "Available Pets"
      pets_coming_soon: "Pets coming soon!"
      no_pets_yet: "This shelter hasn't listed any pets yet."
    edit:
      title: "Edit Shelter Profile"
      name_label: "Shelter Name"
      street_label: "Street Address"
      city_label: "City"
      state_label: "State"
      zip_label: "ZIP Code"
      phone_label: "Phone Number"
      website_label: "Website"
      description_label: "About Your Shelter"
      species_label: "Species Served"
      hours_label: "Hours of Operation"
      hours_placeholder: "Mon-Fri 9-5, Sat 10-2"
      status_label: "Status"
      active: "Active"
      inactive: "Inactive"
      submit: "Save Changes"
    dashboard:
      show:
        title: "%{name} Dashboard"
        subtitle: "Manage your shelter, pets, and team."
        onboarding: "Onboarding Checklist"
        progress: "%{percent}% complete"
        total_pets: "Total Pets"
        active_applications: "Active Applications"
        pending_tasks: "Pending Tasks"
        quick_actions: "Quick Actions"
        add_pet: "Add Pet"
        add_pet_desc: "List a new pet"
        manage_staff: "Manage Staff"
        manage_staff_desc: "Invite team members"
        adoption_policies: "Adoption Policies"
        adoption_policies_desc: "Configure requirements"
    staff:
      index:
        title: "Staff Management"
        current_staff: "Current Staff"
        empty_staff: "No staff members yet."
        pending_invitations: "Pending Invitations"
        invited_ago: "Invited %{time} ago"
        expired: "Expired"
        pending: "Pending"
        invite_new: "Invite New Staff"
        email_label: "Email Address"
        email_placeholder: "colleague@example.com"
        send_invitation: "Send Invitation"
        remove_confirm: "Are you sure you want to remove %{name}?"
        remove: "Remove"
    policies:
      edit:
        title: "Adoption Policies"
        adoption_fee: "Adoption Fee ($)"
        minimum_age: "Minimum Adopter Age"
        fee_description: "Fee Description"
        fee_placeholder: "Covers vaccinations, spay/neuter, and microchipping"
        home_visit: "Home Visit Required"
        home_visit_desc: "A staff member will visit the adopter's home before approval."
        fenced_yard: "Fenced Yard Required"
        fenced_yard_desc: "Adopters must have a securely fenced yard."
        vet_reference: "Vet Reference Required"
        vet_reference_desc: "Adopters must provide a veterinary reference."
        other_requirements: "Other Requirements"
        other_placeholder: "Adopter must live within 50 miles\nAdopter must have previous pet experience"
        one_per_line: "One requirement per line."
        submit: "Save Policies"
  registrations:
    new:
      title: "Create an account"
      subtitle: "Join Tovitu to manage pet adoptions"
      name_label: "Full name"
      email_label: "Email address"
      password_label: "Password"
      password_hint: "Minimum 8 characters"
      confirm_label: "Confirm password"
      submit: "Create account"
      login_prompt: "Already have an account?"
      login_link: "Log in"
    check_email:
      title: "Check your email"
      body: "We sent a verification link to your email address. Please click the link to verify your account."
      didnt_receive: "Didn't receive the email?"
      resend: "Resend verification"
      back: "Back to login"
  sessions:
    new:
      title: "Welcome back"
      subtitle: "Log in to your Tovitu account"
      email_label: "Email address"
      password_label: "Password"
      forgot_password: "Forgot password?"
      submit: "Log in"
      signup_prompt: "Don't have an account?"
      signup_link: "Create account"
  passwords:
    new:
      title: "Forgot your password?"
      subtitle: "Enter your email and we'll send you a reset link"
      email_label: "Email address"
      submit: "Send reset link"
      login_prompt: "Remember your password?"
      login_link: "Log in"
    check_email:
      title: "Check your email"
      body: "If an account with that email exists, we've sent a password reset link. Please check your email."
      back: "Back to login"
    edit:
      title: "Reset your password"
      subtitle: "Enter your new password below"
      password_label: "New password"
      password_hint: "Minimum 8 characters"
      confirm_label: "Confirm new password"
      submit: "Reset password"
  profiles:
    edit:
      title: "Edit profile"
      name_label: "Full name"
      email_label: "Email address"
      verified: "Verified"
      pending_verification: "Pending verification"
      submit: "Update profile"
      back: "Back"
  verifications:
    expired:
      title: "Link expired"
      body: "This verification link has expired. Verification links are valid for 24 hours."
      resend: "Resend verification email"
      back: "Back to login"
    already_verified:
      title: "Already verified"
      body: "Your email has already been verified. You can log in below."
      login: "Log in"
  authentication_mailer:
    verification:
      subject: "Verify your email address"
      greeting: "Welcome to Tovitu, %{name}!"
      body: "Thank you for creating an account. Please verify your email address by clicking the button below:"
      cta: "Verify Email Address"
      expires: "This link will expire in 24 hours."
      ignore: "If you did not create an account, please ignore this email."
    password_reset:
      subject: "Reset your password"
      title: "Reset your password"
      body: "We received a request to reset your password. Click the button below to create a new one:"
      cta: "Reset Password"
      expires: "This link will expire in 1 hour."
      ignore: "If you did not request a password reset, please ignore this email."
    email_changed:
      subject: "Your email address has been changed"
      title: "Email address changed"
      body: "This email is to confirm that your Tovitu account email address has been changed."
      contact: "If you did not make this change, please contact support immediately."
    footer: "© 2026 Tovitu. All rights reserved."
  flash:
    sessions:
      create:
        success: "Logged in successfully."
      destroy:
        success: "Logged out successfully."
      require_authentication: "Please log in to continue."
      require_no_authentication: "You are already logged in."
    registrations:
      create:
        success: "Account created! Please check your email to verify your account."
    passwords:
      create:
        success: "If your email is registered, you will receive a password reset link."
      edit:
        expired: "Invalid or expired password reset link. Please request a new one."
        already_expired: "Password reset link has expired. Please request a new one."
      update:
        success: "Password has been reset successfully."
    verifications:
      show:
        success: "Email verified successfully! Welcome to Tovitu."
    profiles:
      update:
        email_changed: "Profile updated! Please check your new email to verify the change."
        success: "Profile updated successfully."
    shelters:
      create:
        success: "Shelter registered successfully! Welcome to Tovitu."
      update:
        success: "Shelter profile updated successfully."
    staff:
      create:
        success: "Staff member added successfully."
      destroy:
        success: "Staff member removed successfully."
    invitations:
      create:
        success: "Invitation accepted! Welcome to the shelter."
    policies:
      update:
        success: "Adoption policies updated successfully."
    unauthorized: "You are not authorized to perform this action."
    record_not_unique:
      email: "This email is already registered. Please try logging in or use a different email."
      generic: "A database constraint was violated. Please try again."
  errors:
    authenticate_user:
      locked: "Account temporarily locked. Try again in %{seconds} seconds."
      unverified: "Please verify your email before logging in. A new verification email has been sent."
      invalid: "Invalid email or password"
    verify_email:
      invalid: "Invalid verification link"
      expired: "Verification link has expired"
    resend_verification:
      already_verified: "User is already verified"
    reset_password:
      invalid: "Invalid password reset link"
      expired: "Password reset link has expired"
    register_shelter:
      unverified: "Email must be verified before creating a shelter"
      has_shelter: "You already belong to a shelter"
    update_profile:
      not_admin: "Only shelter admins can update the profile"
      wrong_shelter: "You can only edit your own shelter"
    invite_staff:
      not_admin: "Only shelter admins can invite staff"
      wrong_shelter: "You can only invite staff to your own shelter"
      invalid_email: "Invalid email format"
      already_member: "%{email} is already a member of this shelter"
      other_shelter: "%{email} already belongs to another shelter"
    remove_staff:
      not_admin: "Only shelter admins can remove staff"
      wrong_shelter: "You can only manage your own shelter"
      cannot_remove_self: "Cannot remove yourself"
      not_member: "%{name} does not belong to this shelter"
      last_admin: "Cannot remove the last admin. Promote another staff member to admin first."
    accept_invitation:
      invalid: "Invalid invitation token"
      expired: "Invitation has expired"
      accepted: "Invitation has already been accepted"
  activerecord:
    errors:
      models:
        shelter:
          attributes:
            species_served:
              must_be_array: "must be an array"
  presenters:
    shelter:
      status_active: "Active"
      status_inactive: "Inactive"
      onboarding:
        add_pet: "Add your first pet"
        policies: "Configure adoption policies"
        staff: "Invite staff members"
        hours: "Set your hours"
        profile: "Complete your profile"
        publish: "Publish your shelter"
```

**`config/locales/es.yml`** — same structure with Spanish translations.

**`config/locales/es-rails.yml`** — Rails default validation translations for Spanish.

### Step 5: Replace Hardcoded Strings

| Layer | Pattern | Example |
|-------|---------|---------|
| Views | `t(".key")` | `<%= t(".title") %>` |
| Controllers | `t("flash.shelters.create.success")` | `redirect_to ..., notice: t("flash.shelters.create.success")` |
| Mailer subjects | `t(".subject")` | `mail to: ..., subject: t(".subject")` |
| Mailer views | `t(".greeting", name: @user.name)` | `<%= t(".greeting", name: @user.name) %>` |
| Service objects | `I18n.t("errors.key")` | `Result.failure(I18n.t("errors.register_shelter.unverified"))` |
| Presenters | `I18n.t("presenters.shelter.status_active")` | badge label text |
| Models | Already i18n-ready | Custom message from `activerecord.errors.models.shelter.attributes.species_served.must_be_array` |
| Flash from array errors | `Array(result.errors).join(", ")` | Stays as-is — errors already translated |

### Step 6: Locale Switcher UI

Add to `app/views/layouts/application.html.erb`:
```erb
<span class="text-sm">
  <% if I18n.locale == :en %>
    <%= link_to "Español", url_for(locale: :es), class: "..." %>
  <% else %>
    <%= link_to "English", url_for(locale: :en), class: "..." %>
  <% end %>
</span>
```

### Step 7: PWA Manifest

Update `manifest.json.erb` to use `t("layouts.application.title")`.

### Step 8: Update Specs

Existing assertions against English strings continue to work since default locale is `:en`. For future Spanish coverage:
- Add request specs with locale prefix
- Test flash messages via locale keys

---

## Business Rules

1. **Default locale** is `:en` — un-prefixed URLs serve English.
2. **Locale is sticky** — once set via URL, it persists in all generated URLs via `default_url_options`.
3. **Locale is not stored in session** — URL-based only (SEO-friendly).
4. **Invalid locale** (`/fr/shelters`) returns 404 for the route.
5. **Brand name** (`Tovitu`) is never translated.
6. **US state list** in `us_states` helper is never translated (static data).
7. **AI prompts** in `config/prompts/` are not translated.

---

## Dependencies / Prerequisites

- Rails i18n is built-in — no gems needed.
- Existing authentication and shelter domains fully implemented.

---

## Open Questions / Risks

1. **Mailer locale** — mailers run in a background job (Sidekiq). Must ensure `I18n.locale` is set correctly in the job context. Options: pass locale as a job argument, or store user's preferred locale on the User model.
2. **Turbo Streams** — locale switcher should work with Turbo Drive (full page navigation). No special handling needed for path-prefix approach.
3. **Test maintenance** — specs that assert against specific English strings will break if default locale is changed. Mitigation: keep default `:en` permanently.

---

## Edge Cases & Error States

| Edge Case | Handling |
|-----------|----------|
| Locale param is missing | Defaults to `:en` |
| Locale param is invalid (`/fr/...`) | Route doesn't match, returns 404 |
| Background job sends mail | Pass locale as job argument or use user's stored locale |
| Error page rendered without locale | Error pages in default locale only |
| Locale switcher on non-scoped route | Switcher hidden or redirects to locale-prefixed root |
| `pluralize("error", count)` | Define pluralization rules in `es.yml` for Spanish |

---

## Success Metrics

| Metric | Target |
|--------|--------|
| All user-facing strings translated to Spanish | 100% coverage |
| No hardcoded English strings remain in views/controllers/mailers | 0 strings |
| Existing test suite passes without modification | All green |

---

## Technical Notes

- Rails i18n is built-in and requires no additional gems.
- `I18n.t` with lazy lookup (`t(".key")`) resolves relative to the current view path or controller action.
- `default_url_options` in `ApplicationController` ensures locale is carried across all generated URLs.
- Route scoping with optional group `(/:locale)` ensures backward compatibility.
- Spanish validation messages can be partially sourced from `rails-i18n` gem or written manually.
