# Plan: Dashboard Sidebar Fix, Role-Based Navigation & Profile Enhancements

**Domain:** Navigation, UI, User Profiles
**Priority:** 2 (improves existing foundation)
**Status:** Draft
**Timestamp:** 2026-06-23

---

## Overview

This plan addresses three connected improvements to the Tovitu platform's navigation and personalization. First, it fixes an incorrect sidebar active-state bug where "Shelters" is highlighted instead of "Dashboard" on certain pages. Second, it separates sidebar navigation options per user role (Adopter vs. Shelter), giving each role its own set of relevant links. Third, it enhances the profile/settings tab by making the onboarding questionnaire re-accessible after completion (for both roles) and surfacing shelter basic-info editing from the profile page.

The plan is purely about UX navigation and profile configuration — no new domain logic or backend workflows are introduced.

---

## Current State

### Sidebar (`app/views/shared/_sidebar.html.erb`)

The sidebar is a single partial shared across all authenticated users. It contains these links in order:

1. **Dashboard** → `root_path` — uses `current_page?(root_path)` to detect active state
2. **Shelters** → `shelters_path` — uses `request.path.start_with?('/shelters')` to detect active state
3. **Pets** → `pets_path` — uses `request.path.start_with?('/pets')` to detect active state
4. **Complete Profile (adopter)** — shown only if `current_user.adopter? && !onboarding_completed?`
5. **Complete Profile (shelter)** — shown only if `current_user.shelter_user? && !onboarding_completed?`
6. **Adoptions** → `#` (placeholder, "Coming soon")
7. **Settings** → `edit_profile_path` — uses `current_page?(edit_profile_path)` to detect active state
8. **Sign out** — always shown

**Key observations:**
- `root_path` maps to `LandingController#index` — there is **no general dashboard route** in `config/routes.rb`.
- The `DashboardController` exists (`app/controllers/dashboard_controller.rb`) but has **no route** — its `index` action redirects adopters to `pets_path` and shelter users to `shelter_dashboard_path`.
- For adopters who are signed in, there is no dedicated dashboard page (they see `pets#index` or the landing page).
- For shelter users, their dashboard is at `/shelters/:shelter_id/dashboard` — a path that starts with `/shelters`.

### Dashboard views

- **Adopter dashboard** — `DashboardController#index` redirects to `pets_path`. No actual dashboard view for adopters.
- **Shelter dashboard** — `Shelters::DashboardController#show` renders at `/shelters/:shelter_id/dashboard`. View at `app/views/shelters/dashboard/show.html.erb`.

### Profile settings (`Authentication::ProfilesController`)

- **`edit`** action renders `app/views/authentication/profiles/edit.html.erb` — a form for editing name and email.
- Shows a "Complete your profile" banner only when `current_user.onboarding_completed?` is false.
- **No link to re-edit preferences after onboarding is complete.**

### Onboarding questionnaire

- **Adopter onboarding** (`Onboarding::Adopter::QuestionsController`) — guarded by `require_onboarding_not_complete`. Once `onboarding_completed_at` is set, the questionnaire cannot be accessed.
- **Shelter onboarding** (`Onboarding::Shelter::QuestionsController`) — same guard. Once complete, inaccessible.
- Both store responses in `AdopterProfile` and `ShelterProfile` respectively.

### Shelter basic-info editing

- Already exists at `SheltersController#edit` (route: `/shelters/:id/edit`) and `SheltersController#update`.
- View renders a form for shelter name, address, contact, species, hours, status.
- Can be accessed via `edit_shelter_path(@shelter)`. Currently not linked from the profile settings page.

### Routes

```
root "landing#index"
resource :profile, only: [ :edit, :update ], controller: "authentication/profiles"
resources :shelters, only: [ :index, :show, :new, :create, :edit, :update ] do
  resource :dashboard, only: [ :show ], controller: "shelters/dashboard"
  ...
end
get "profile/onboarding", to: "onboarding/adopter/questions#show"
get "profile/shelter_onboarding", to: "onboarding/shelter/questions#show"
```

### Related existing specs

- `spec/requests/authentication/profiles_spec.rb` — tests profile edit/update (basic CRUD, no personalization tests)
- `spec/requests/shelters/dashboard_spec.rb` — tests shelter dashboard access
- No sidebar/navigation specs exist

---

## Requirements

### R1: Fix dashboard sidebar selection bug

**Problem:** When a shelter user navigates to their dashboard (`/shelters/:id/dashboard`), the "Dashboard" link in the sidebar is not highlighted. Instead, the "Shelters" link is incorrectly highlighted because `request.path.start_with?('/shelters')` evaluates to true for all paths starting with `/shelters`, including the shelter dashboard.

**Root cause:** The "Dashboard" link uses `current_page?(root_path)` for active-state detection. Since `root_path` is the public landing page (`LandingController#index`) and the user is on a different path, the check never returns true. Meanwhile, the "Shelters" link matches all `/shelters/*` paths.

**Expected behavior:** When viewing the shelter dashboard (`/shelters/:id/dashboard`), the "Dashboard" link should appear active and the "Shelters" link should appear inactive.

### R2: Separate sidebar per role

**Problem:** All authenticated users see the same sidebar, regardless of role. This is confusing because:
- Adopters don't need "Shelters" as a primary navigation item (they can discover shelters via search)
- Shelter users don't need "Pets" as a public browsing item (they manage their own pets through a dedicated interface)
- Each role has unique navigation needs

**Expected behavior:**

**Adopter sidebar:**
- Dashboard (redirects to pets today, could be a real dashboard later)
- Pets (browse adoptable pets)
- Adoptions (my applications — currently placeholder)
- Settings / Profile
- Sign out

**Shelter sidebar:**
- Dashboard (shelter dashboard at `/shelters/:id/dashboard`)
- My Pets (manage shelter pets — currently at `/shelter/pets`)
- Adoptions (manage adoption applications — currently at `/shelter/adoption_applications`)
- Staff (manage team — currently at `/shelters/:id/staff`)
- Adoption Policies (configure — currently at `/shelters/:id/policies`)
- Settings / Profile
- Sign out

### R3: Enhance profile tab with personalization

**3a. Edit preferences (questionnaire reinstatement for both roles)**

**Problem:** The onboarding questionnaire is a one-time flow. Once completed, there is no way for users to update their preferences or profile answers. For adopters, this means their lifestyle/preference data becomes stale. For shelter users, their organization profile descriptions can't be refined.

**Expected behavior:**
- From the Profile settings page (`/profile/edit`), both adopters and shelter users should see an "Edit preferences" button/link that re-opens the onboarding questionnaire.
- The questionnaire should start from the first question, pre-populated with existing answers.
- Saving preferences should update the existing `AdopterProfile` / `ShelterProfile` records without requiring re-completion of the onboarding flag.
- The `onboarding_completed?` guard should be bypassed when accessing from the profile page (using the existing `from_profile=true` mechanism).

**3b. Shelter basic info editing from profile**

**Problem:** Shelter users currently must navigate to the shelter edit page directly (`/shelters/:id/edit`). There is no link to this from the profile settings page.

**Expected behavior:**
- If the current user is a shelter user and belongs to a shelter (`current_user.shelter_id.present?`), the profile settings page should display a "Shelter Information" section with a link to edit the shelter's basic info.
- This links to `edit_shelter_path(current_user.shelter_id)`.

---

## Proposed Approach

### Approach for R1 — Fix sidebar active state

**Option A (recommended): Change dashboard active detection to use `request.path`**

Replace `current_page?(root_path)` in the Dashboard link with logic that checks for known dashboard paths:

```erb
<% dashboard_active = current_page?(root_path) ||
                     request.path.start_with?('/shelters/', '/pets') ||
                     request.path == dashboard_path %>
```

Wait — there is no `dashboard_path` or actual dashboard route for the general case. Let me reconsider.

**Recommended approach:** Create a helper method that determines which sidebar item should be active based on the current path and user role:

```ruby
# In app/helpers/navigation_helper.rb
def sidebar_dashboard_active?(user)
  if user.adopter?
    # For adopters, dashboard redirects to pets, so consider pets as "dashboard"
    current_page?(root_path) || request.path.start_with?('/pets')
  elsif user.shelter_user?
    # For shelter users, dashboard is the shelter dashboard
    request.path.include?('/dashboard') || request.path == root_path
  end
end
```

**Simpler approach (recommended for MVP):** Since the sidebar is about to be split per role anyway (R2), fix this by:
1. For **adopters**: Dashboard link goes to `pets_path` (their effective dashboard). Active state checks `request.path.start_with?('/pets')` or `current_page?(root_path)`.
2. For **shelter users**: Dashboard is the shelter dashboard path. Active state checks the shelter dashboard path.

**Implementation steps:**
1. Create `app/helpers/navigation_helper.rb` with sidebar active-state helpers.
2. Update the sidebar partial to use these helpers instead of `current_page?(root_path)`.
3. Remove the generic `DashboardController` route (or add a real dashboard route for future use).

### Approach for R2 — Separate sidebar per role

Refactor `_sidebar.html.erb` into role-specific sections:

```erb
<% if current_user.adopter? %>
  <!-- Adopter navigation -->
  <%= render "shared/adopter_sidebar" %>
<% elsif current_user.shelter_user? %>
  <!-- Shelter navigation -->
  <%= render "shared/shelter_sidebar" %>
<% end %>
```

Or keep a single partial but use conditional rendering with clearly separated blocks.

**Adopter sidebar items:**
1. Dashboard → `pets_path` (active: `/pets` or root)
2. Pets → `pets_path` (or a new browse path if dashboard is separate)
3. Adoptions → `#` (placeholder, "Coming soon")
4. Settings → `edit_profile_path`
5. Sign out

**Shelter sidebar items:**
1. Dashboard → `shelter_dashboard_path(current_user.shelter_id)`
2. My Pets → `shelter_pets_path`
3. Adoptions → `shelter_adoption_applications_path` (or placeholder)
4. Staff → `shelter_staff_index_path(current_user.shelter_id)`
5. Adoption Policies → `edit_shelter_policies_path(current_user.shelter_id)`
6. Settings → `edit_profile_path`
7. Sign out

**Note:** Some routes may need to be confirmed/created (e.g., `shelter_adoption_applications_path` exists under `namespace :shelter` in routes).

### Approach for R3 — Profile personalization

**3a. Re-enable questionnaire editing after completion**

1. Modify `Onboarding::Adopter::QuestionsController` and `Onboarding::Shelter::QuestionsController` to allow access when `from_profile=true` is passed, **regardless of onboarding completion status**.
   - The `require_onboarding_not_complete` before_action should be skipped when `from_profile=true`.
   - The complete/save logic should update existing profile data rather than requiring a fresh completion.

2. Add "Edit preferences" links on the profile edit page (`app/views/authentication/profiles/edit.html.erb`):
   - For adopters: link to `/profile/onboarding?from_profile=true`
   - For shelter users: link to `/profile/shelter_onboarding?from_profile=true`
   - Show these links always (not just when onboarding is incomplete).

3. Ensure the questionnaire completion action (`Onboarding::Adopter::CompletionsController` and `Shelter::CompletionsController`) handles the case where onboarding was already completed — either skip the completion step (since it's already marked complete) or just redirect back.

**3b. Link shelter basic-info editing from profile**

1. In `app/views/authentication/profiles/edit.html.erb`, after the name/email form, add a conditional section:
   ```erb
   <% if current_user.shelter_user? && current_user.shelter_id.present? %>
     <div class="mt-8 border-t pt-8">
       <h2>Shelter Information</h2>
       <p>Manage your shelter's basic details.</p>
       <%= link_to "Edit Shelter Info", edit_shelter_path(current_user.shelter_id) %>
     </div>
   <% end %>
   ```

2. Add corresponding locale strings.

---

## UI/UX Considerations

### Sidebar navigation patterns

- **Consistency:** Both role sidebars should share the same visual design (collapse/expand behavior, icon placement, hover states).
- **Icons:** Each sidebar item should retain its SVG icon. Shelter-specific items may need new icons (Staff → users icon, Policies → settings/shield icon).
- **Active state:** Use the same visual treatment (primary-50 bg, primary-700 text) across all active items.
- **Ordering:** Primary actions first (Dashboard, core domain items), then secondary (Settings), then sign out separated by a divider.
- **Mobile:** The existing mobile sidebar behavior (slide-out overlay) should be preserved.

### Profile page layout

- The profile page should be reorganized into logical sections:
  1. **Account Info** — name and email (existing form)
  2. **Preferences** — questionnaire re-edit links (new)
  3. **Shelter Info** — shelter edit link (new, shelter only)
- Each section should use a card-like container with a heading for visual separation.

### Accessibility

- Sidebar links already have `aria-label` on toggle button. Ensure new links have accessible labels.
- Active state should be conveyed to screen readers (use `aria-current="page"` on the active link).

---

## Risks & Unknowns

### R1 / R2 Risks

- **Dashboard route ambiguity:** There is currently no route for `DashboardController#index`. After the sidebar split, adopters will have "Dashboard" as a link. Where should it go? Possible options:
  - Option 1: Point to `/pets` (their effective dashboard today)
  - Option 2: Create a real adopter dashboard route with relevant content
  - Option 3: Keep the landing page `root_path` as the dashboard (current behavior, but poor UX)

  **Decision needed from founder.** For this plan, we'll assume **Option 1** (point to `/pets`) as the simplest path forward, with a note that this can evolve.

- **Shelter user without a shelter:** What should be shown in the sidebar for a shelter_user who hasn't created or joined a shelter yet? The shelter dashboard, pets, staff, and policies links all require a `shelter_id`. These should be hidden or disabled with a prompt to create/join a shelter.

### R3 Risks

- **Onboarding flow re-entry:** The existing onboarding questionnaire uses Stimulus controllers with a question-by-question save mechanism. When re-entering, the flow should pre-populate existing answers. This already works — the views read from `@profile.send(question[:key])` which will return existing data.
- **Completion logic:** The `Onboarding::Adopter::CompletionsController` and `Shelter::CompletionsController` set `onboarding_completed_at`. When re-editing from profile, this timestamp should **not** be modified (it stays as-is). The "Complete" button at the end of the flow should detect this case and redirect back to the profile page instead.
- **Skip behavior:** The "Skip" button should not be shown when re-editing from profile (since profiling is already complete, skipping makes no sense).

### Other unknowns

- **Adoption applications route:** The `shelter_adoption_applications_path` exists under `namespace :shelter` in routes but may need to be confirmed working. Sidebar can link to it with a placeholder state if the page isn't built yet.
- **Locale strings:** New sidebar labels and profile section headings need to be added to `config/locales/en.yml` and `config/locales/es.yml`.

---

## Acceptance Criteria

### AC-R1: Dashboard sidebar selection bug fixed

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | When a shelter user visits `/shelters/:id/dashboard`, the "Dashboard" link in the sidebar is highlighted (active state applied) | Visual inspection |
| 2 | When a shelter user visits `/shelters/:id/dashboard`, the "Shelters" link is **not** highlighted | Visual inspection |
| 3 | When any user is on the landing page (root), "Dashboard" is highlighted | Visual inspection |
| 4 | Active state uses the same visual classes across all sidebar items (primary-50 bg, primary-700 text) | Code review |
| 5 | All existing sidebar active states for other pages (Pets, Settings) remain correct | Visual inspection of each page |

### AC-R2: Sidebar separates per role

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | An **adopter** user sees only: Dashboard, Pets, Adoptions (disabled), Settings, Sign out | Visual inspection |
| 2 | A **shelter** user (with shelter) sees: Dashboard, My Pets, Adoptions, Staff, Adoption Policies, Settings, Sign out | Visual inspection |
| 3 | A **shelter** user (without shelter) sees limited items: Dashboard (disabled), Settings, Sign out, with prompt to create/join shelter | Visual inspection |
| 4 | The shelter user's Dashboard link goes to `shelter_dashboard_path(current_user.shelter_id)` and is highlighted when on that page | Visual + code review |
| 5 | The adopter's Dashboard link goes to `pets_path` (or a suitable adopter dashboard) and is highlighted when on pet-related pages | Visual + code review |
| 6 | Sign-out link and Settings link appear in both role versions | Visual inspection |
| 7 | Mobile sidebar behavior is preserved for both roles | Test on mobile viewport |
| 8 | Sidebar collapse/expand state persists correctly (via localStorage) | Manual test |

### AC-R3a: Edit preferences from profile

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | An **adopter** on the profile edit page sees an "Edit preferences" button/area | Visual inspection |
| 2 | Clicking "Edit preferences" opens the adopter onboarding questionnaire, pre-populated with existing answers | Visual inspection |
| 3 | A **shelter user** on the profile edit page sees an "Edit preferences" button/area | Visual inspection |
| 4 | Clicking "Edit preferences" opens the shelter onboarding questionnaire, pre-populated with existing answers | Visual inspection |
| 5 | After saving changes in the questionnaire, the user is redirected back to the profile page | Acceptance test |
| 6 | The `onboarding_completed_at` timestamp is **not** changed when re-editing preferences | Check database after edit |
| 7 | The "Skip" button is hidden when re-editing from profile | Visual inspection |
| 8 | The questionnaire start page title/subtitle reflects the re-edit context (e.g., "Edit your preferences" instead of "Complete your profile") | Visual inspection |

### AC-R3b: Shelter basic info from profile

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | A **shelter user** on the profile edit page sees a "Shelter Information" section | Visual inspection |
| 2 | The section includes a link to `edit_shelter_path(current_user.shelter_id)` | Code review |
| 3 | An **adopter** does **not** see the "Shelter Information" section | Visual inspection |
| 4 | A shelter user without a shelter assigned does not see the section (or sees a prompt to set up a shelter) | Visual inspection |
| 5 | Clicking the link navigates to the shelter edit form | Navigation test |

### General AC

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | All new/changed locale strings are added to `config/locales/en.yml` | Code review |
| 2 | No user-facing strings are hardcoded — all use `t()` or `I18n.t()` | Code review |
| 3 | Existing specs continue to pass after changes | `bundle exec rspec` |
| 4 | New request specs exist for any new controller behavior (e.g., questionnaire re-entry) | Code review |
| 5 | Sidebar renders correctly on mobile and desktop | Visual inspection |
| 6 | The sidebar does not break for unauthenticated users (they don't see the sidebar) | Visual inspection |

---

## File Change Summary

| File | Change Type | Description |
|------|-------------|-------------|
| `app/helpers/navigation_helper.rb` | **New** | Helper methods for sidebar active-state detection |
| `app/views/shared/_sidebar.html.erb` | **Modify** | Split into role-specific sections or extract partials |
| `app/views/shared/_adopter_sidebar.html.erb` | **New** (or inline) | Adopter-specific sidebar items |
| `app/views/shared/_shelter_sidebar.html.erb` | **New** (or inline) | Shelter-specific sidebar items |
| `app/views/authentication/profiles/edit.html.erb` | **Modify** | Add preferences section + shelter info section |
| `app/controllers/onboarding/adopter/questions_controller.rb` | **Modify** | Allow access when `from_profile=true` even if completed |
| `app/controllers/onboarding/shelter/questions_controller.rb` | **Modify** | Allow access when `from_profile=true` even if completed |
| `app/controllers/onboarding/adopter/completions_controller.rb` | **Modify** | Handle re-edit completion (don't change onboarding flag) |
| `app/controllers/onboarding/shelter/completions_controller.rb` | **Modify** | Handle re-edit completion (don't change onboarding flag) |
| `config/locales/en.yml` | **Modify** | Add new sidebar labels and profile section strings |
| `config/locales/es.yml` | **Modify** | Add Spanish translations for new strings |
| `spec/requests/authentication/profiles_spec.rb` | **Modify** | Add tests for preferences section and shelter info link |
| `spec/requests/onboarding/adopter/questions_spec.rb` | **New** (or add to existing) | Test re-entry from profile |
| `spec/requests/onboarding/shelter/questions_spec.rb` | **New** (or add to existing) | Test re-entry from profile |
| `spec/system/navigation/sidebar_spec.rb` | **New** | System tests for role-based sidebar rendering |

---

## Out of Scope

- Creating a full adopter dashboard page with widgets/stats — this plan only fixes navigation to existing pages.
- Building out the Adoptions management pages for shelters — the sidebar links to existing routes (which may be placeholder pages).
- Adding new profile fields or questionnaire questions.
- AI-powered matching or recommendations based on preferences.
- Multi-language support for questionnaire re-entry flows beyond existing i18n structure.

---

## Decision Log

| Decision | Options Considered | Chosen Approach | Rationale |
|----------|-------------------|-----------------|-----------|
| Adopter Dashboard destination | (a) root_path, (b) pets_path, (c) new dashboard page | `pets_path` | Simplest path; adopters effectively get a "pets browsing" dashboard. Can be replaced with a real dashboard later. |
| Single sidebar partial vs separate partials | (a) One partial with conditional blocks, (b) Two separate partials | Two partials | Cleaner separation; easier to maintain as each role's nav evolves independently. |
| Questionnaire re-entry: bypass vs dupe | (a) Reuse existing flow by removing guard, (b) Build separate edit flow | Bypass guard with `from_profile` param | Reuses all existing Stimulus controllers and views; minimal code change. |
