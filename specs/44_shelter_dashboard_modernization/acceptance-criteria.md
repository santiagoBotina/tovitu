# Acceptance Criteria: Shelter Dashboard Modernization (Story 1.4)

**Source plan:** `specs/44_shelter_dashboard_modernization_plan.md`

---

## AC-1: Design consistency

**Given** I open the shelter dashboard
**Then** it uses the same design language as the adopter dashboard: `rounded-xl` cards with 1px `neutral-200` borders and restrained shadows, `font-display` headings, `text-neutral-*` body copy, consistent buttons with focus rings, and `bento-enter` staggered entrance motion

**Given** I open the shelter dashboard
**Then** it does not replicate the adopter dashboard's layout — it remains operational and shelter-specific (metrics, alerts, quick actions, team)

---

## AC-2: Welcome / overview area

**Given** I open the shelter dashboard
**Then** the header shows a personalized title and a contextual summary derived from real counts (pending requests / adoptable pets)

**Given** the shelter has a logo attached
**Then** the logo appears in the header's shelter-identity avatar; otherwise an initials tile is shown

---

## AC-3: Metrics are data-backed with clear zero states

**Given** my shelter has applications and pets in various states
**Then** the four metric cards (Adoptable pets, Pending requests, In review, Active adoptions) show real counts from application/pet data — never hardcoded values

**Given** a metric is zero
**Then** it shows `0` with neutral styling and a helpful hint, not an error-looking state

**Given** I navigate via Turbo (e.g., checklist completion, policy update)
**Then** metric markup never flashes broken/empty — counts are server-rendered and stable

---

## AC-4: Actionable content is prioritized

**Given** there are pending requests
**Then** the alert bar appears with a "Review Now" action

**Given** I view recent activity
**Then** each activity item links directly to its adoption request management screen

**Given** there are adoptable pets missing a photo or description
**Then** a "Pets needing attention" section lists them (max 5) with a badge naming what's missing and a link to complete the profile

---

## AC-5: Empty states provide next steps

**Given** a shelter with no pets and no requests
**Then** a hero empty state shows welcome copy with a primary "Add Your First Pet" action and a secondary action (policies for admins, public page otherwise)

**Given** the recent-activity card is empty
**Then** it shows a clear empty state with a next-step CTA

---

## AC-6: Quick actions are correct, prominent, and mobile-friendly

**Given** I view quick actions
**Then** "Add a Pet" and "Review Applications" appear as the most prominent actions

**Given** I am staff (not admin)
**Then** admin-gated actions (Manage Team, Configure Policies, Shelter Profile) are hidden and no broken links render

**Given** I am an admin
**Then** Manage Pets (always), Manage Team, Configure Policies, and Shelter Profile actions render and navigate to the correct destinations

**Given** I am on mobile
**Then** all quick-action tap targets are comfortably large and the grid collapses cleanly

---

## AC-7: Existing functionality preserved

**Given** I visit the dashboard for the first time with no pets
**Then** the welcome overlay still appears and can be dismissed

**Given** the onboarding checklist is shown
**Then** it renders with the same completion/dismiss/restore behavior and the same Turbo Stream targets (`#onboarding-checklist`, `#progress-bar`)

**Given** policies or checklist state update via Turbo Stream
**Then** the dashboard widgets refresh without breaking

**Given** I am staff (not admin)
**Then** the admin-only sidebar sections remain hidden

---

## AC-8: Responsive behavior

**Given** I view on a small screen
**Then** metrics stack 1-up (full width) → 2-up → 4-up; activity and quick actions stack vertically; nothing overflows horizontally

**Given** I view on tablet and desktop
**Then** the layout uses the wider dashboard container and multi-column arrangement consistent with the adopter dashboard

---

## AC-9: Localization

**Given** the locale is English
**Then** all new/changed dashboard strings render in English

**Given** the locale is Spanish
**Then** all new/changed dashboard strings render in Spanish

**And** no new user-facing strings are hardcoded in views

---

## AC-10: Regression

**Given** the test suite runs
**Then** `spec/requests/shelters/dashboard_spec.rb` passes unchanged (counts, authorization, admin-gating)

**And** new dashboard view specs cover: welcome identity, metrics from controller data, activity links, quick-action paths + gating, pets-needing-attention, empty states, team overflow