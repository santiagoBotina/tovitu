# Plan: Dashboard Views for Adopters and Shelters

**Domain:** Product, UX
**Priority:** 1 (improves core user experience after login — every authenticated user hits this page)
**Status:** Draft
**Timestamp:** 2026-06-24

---

## Overview

Every authenticated user lands somewhere after login. Today, adopters get redirected straight to the pets browse page, and shelters see a minimal dashboard with three hardcoded metric cards and an onboarding checklist. Neither experience feels like a command center — they feel like unfinished placeholders.

This plan defines proper dashboard views for both roles. For **adopters**, the dashboard is a welcoming personal landing page that matches the emotional tone of the adoption journey — a cheerful guide that shows where you are, what's next, and keeps you moving forward. For **shelters**, the dashboard is a command center for the adoption pipeline — status at a glance, quick access to priority actions, and a clear picture of what needs attention.

Both dashboards must feel unmistakably Tovitu: playful, bold, and friendly. No corporate metric obsession. No empty wastelands. Every state — first-time, returning, power user — feels intentional and delightful.

---

## Current State

### Adopter Dashboard — Missing entirely
- `DashboardController#index` exists but has **no route**. The action immediately redirects: adopters → `pets_path`, shelter users → `shelter_dashboard_path`.
- There is a `app/views/dashboard/index.html.erb` view with a welcome message, role label, and two cards (profile link + logout). It is **never rendered** because the controller action redirects before rendering.
- The sidebar (from plan #8) will list "Dashboard" as an adopter nav item pointing to `pets_path` as a stand-in. No real dashboard exists.
- After login, adopters land on `/pets` — a browse page, not a personal home page.

### Shelter Dashboard — Minimal placeholder
- `Shelters::DashboardController#show` renders at `/shelters/:shelter_id/dashboard`. It exists and is functional.
- **Hardcoded empty data:** `@active_applications = 0` and `@pending_tasks = []` — these don't query real data yet.
- **Metrics section:** Three cards showing total pets, active applications (always 0), and pending tasks (always empty).
- **Onboarding checklist:** A gradient-tinted card listing onboarding steps with progress bar. This is the most useful part — helps new shelters get set up.
- **Quick actions:** Three links — Add Pet, Manage Staff, Adoption Policies.
- There is no real-time data, no applications pipeline view, no team status, no notifications.
- The shelter dashboard controller sets `@total_pets`, `@active_applications`, `@pending_tasks` in `show` action.

### Cross-cutting gaps
- No `dashboard_path` route for the general case. After implementing real dashboards, we need a route that resolves to the correct dashboard per role.
- After login redirect: all users go through `DashboardController#index` which redirects — but there's no `root_path` override for authenticated users.
- No loading/skeleton states for dashboard content (none needed today since nothing queries async data, but some future dashboard widgets may be async).

---

## User Personas

### Adopter Personas

**New Adopter — "Just curious"**
- Just signed up, email verified, logged in for the first time.
- Has NOT completed the onboarding questionnaire (or partially completed).
- Has NOT browsed any pets yet.
- Emotional state: Excited but unsure where to start. Needs gentle guidance.
- Primary need: Clear, friendly CTA to complete profile and start browsing.

**Active Adopter — "Shopping around"**
- Completed onboarding profile.
- Has browsed pets, maybe favorited some (when favorites feature exists).
- Has submitted 1+ adoption requests — tracking statuses.
- Emotional state: Engaged, hopeful, possibly anxious about application outcomes.
- Primary need: Quick access to application statuses, continue browsing, revisit favorite pets.

**Returning Adopter — "Checking in"**
- Has prior history — past requests (accepted or declined), maybe even past adoptions.
- Logging in to check status on an active request or start a new search.
- Emotional state: Varies — could be excited (new search), nervous (awaiting decision), or reflective (past adoption).
- Primary need: Status updates at a glance, next-step clarity.

### Shelter Personas

**New Shelter — "Setting up shop"**
- Just registered the shelter, logged in for the first time.
- Has NOT added any pets yet.
- Has NOT completed shelter profile (hours, policies, staff).
- Emotional state: Motivated but overwhelmed — many setup tasks ahead.
- Primary need: Step-by-step onboarding checklist, clear "what now?" guidance.

**Active Shelter — "Managing the pipeline"**
- Has 3–20 pets listed. Has staff members. Has incoming adoption requests.
- Logging in daily or multiple times per week.
- Emotional state: Busy, needs efficiency. Time-sensitive decisions.
- Primary need: Pending counts, quick actions, application triage, team visibility.

**Established Shelter — "High volume"**
- 20+ pets listed. 3+ staff members. Steady flow of adoption requests.
- Logging in multiple times daily. May have multiple staff coordinating.
- Emotional state: Needs prioritization and overview. Can't afford to miss anything.
- Primary need: Dashboard as triage center — what needs attention first, team workload, adoption outcomes tracking.

---

## User Stories & Flows

### Adopter Dashboard

**US-AD-DB-01: First-time welcome**
> **As a** new adopter who just signed up,
> **I want to** see a warm, encouraging welcome with clear next steps,
> **So that** I know what to do first and feel excited to get started.

**US-AD-DB-02: Onboarding progress awareness**
> **As an** adopter who hasn't completed onboarding,
> **I want to** see my progress and a clear CTA to complete my profile,
> **So that** I understand the value of finishing and can do it in one click.

**US-AD-DB-03: Track adoption requests**
> **As an** adopter with active adoption requests,
> **I want to** see the status of each request at a glance,
> **So that** I know if my application is pending, being reviewed, accepted, or declined.

**US-AD-DB-04: Quick browse access**
> **As an** adopter,
> **I want to** start browsing pets from the dashboard with one click,
> **So that** I can easily discover potential matches.

**US-AD-DB-05: Personalized tip**
> **As an** adopter at any stage,
> **I want to** see a helpful, contextual tip or educational tidbit,
> **So that** I feel guided and informed throughout the adoption journey.

**US-AD-DB-06: Profile completeness indicator**
> **As an** adopter,
> **I want to** see how complete my profile is and what's missing,
> **So that** I can improve my chances of a good match.

**US-AD-DB-07: Empty state guidance**
> **As an** adopter with no activity yet,
> **I want to** see an encouraging empty state with clear CTAs,
> **So that** the page never feels broken or abandoned.

### Shelter Dashboard

**US-SH-DB-01: Pipeline overview**
> **As a** shelter staff member,
> **I want to** see counts of pending, in-validation, and accepted adoption requests,
> **So that** I know the state of my adoption pipeline at a glance.

**US-SH-DB-02: New request alerts**
> **As a** shelter staff member,
> **I want to** see when new adoption requests arrive,
> **So that** I can respond promptly and not miss potential matches.

**US-SH-DB-03: Onboarding progress (new shelter)**
> **As a** shelter that hasn't completed setup,
> **I want to** see an onboarding checklist with progress,
> **So that** I know what steps remain to go live.

**US-SH-DB-04: Quick actions**
> **As a** shelter staff member,
> **I want to** access common tasks (add pet, review apps, manage team) from the dashboard,
> **So that** I save time navigating through menus.

**US-SH-DB-05: Pet listing summary**
> **As a** shelter staff member,
> **I want to** see how many pets are available, on hold, and adopted,
> **So that** I understand my inventory at a glance.

**US-SH-DB-06: Team visibility (multi-staff shelters)**
> **As a** shelter admin,
> **I want to** see team members and recent activity,
> **So that** I know who's handling what.

**US-SH-DB-07: Recent activity**
> **As a** shelter staff member,
> **I want to** see a feed of recent activity (new requests, status changes, notes),
> **So that** I stay up to date without digging through pages.

**US-SH-DB-08: First-time shelter guidance**
> **As a** shelter that just registered,
> **I want to** see clear setup guidance and encouragement,
> **So that** I know exactly what to do to activate my shelter.

---

## Feature Specifications

### Adopter Dashboard Sections

The adopter dashboard is a single-page layout with stacked sections (not a dense grid of widgets). This keeps it calm and scannable — more like a friendly home page than a data dashboard.

---

#### Section 1: Welcome Banner
**Purpose:** Greet the user by name with warmth. Set the emotional tone. Show a contextual message based on journey stage.

**Content:**
- **Headline (Baloo 2, bold):** "Hey {name}! 🐾" (or "Welcome back, {name}! 🐾")
- **Subtitle (Poppins body, neutral-500):** Contextual message based on state:
  - *New user, no onboarding:* "Ready to find your perfect match? Let's start by telling us a bit about yourself."
  - *Onboarding complete, no requests:* "Your profile is all set! Start exploring pets that match your lifestyle."
  - *Has active requests:* "Let's check on your adoption requests!"
  - *All requests resolved:* "Great news — all your requests are sorted. Ready to find another friend?"

**Visual treatment:** Full-width, flat primary-50 tinted background (no gradient, per DESIGN.md rules), large rounded-xl card. Purple accent icon (paw or heart) near the greeting.

**CTA button:** Secondary-500 (teal) "Browse Pets" button for users who haven't browsed yet. Ghost-primary "View My Requests" for users with active requests.

**Empty/first-time state:** This is the first-time state — headline is encouraging, subtitle guides to onboarding or browsing.

**Returning user state:** Changes subtitle text based on data. Shows "Welcome back" variant if user has visited before (use `last_sign_in_at` or `current_sign_in_at`).

---

#### Section 2: Onboarding Progress (conditional)
**Purpose:** Only shown if adopter has NOT completed onboarding. Encourages completion with clear progress.

**Content:**
- **Progress bar:** Flat primary-500 fill, white/neutral-100 track, rounded-full.
- **Text:** "Your profile is {percent}% complete — tell us about yourself so we can find better matches!"
- **CTA:** "Complete Your Profile" button (primary-500, full width on mobile).
- **Number of questions remaining:** "Just {n} quick questions left."

**Visual treatment:** Card with white background, 1px neutral-200 border, rounded-xl. Purple progress bar. Compact — shouldn't dominate the page.

**Empty/first-time state:** Shows 0% with 8 questions remaining if user hasn't started.

**Returning user state:** Hidden entirely if onboarding is complete. (Can still be accessed from profile settings per plan #8.)

**CTA behavior:** Clicking navigates to the onboarding questionnaire flow (`/profile/onboarding`), pre-populated with existing answers if any.

---

#### Section 3: My Requests (conditional)
**Purpose:** Show adoption request statuses at a glance. The most important section for active adopters.

**Content:**
- **Section heading:** "My Requests" (Baloo 2 headline)
- **If 0 requests:** Empty state card with illustration/icon, "You haven't requested to adopt any pets yet. Start browsing to find your match!" + "Browse Pets" button.
- **If 1–3 requests:** Cards in a vertical list. Each card shows:
  - Pet thumbnail image (circle, 48px)
  - Pet name + breed
  - Status badge (colored chip: pending = warning/amber, in_validation = info/blue, accepted = teal/success, declined = neutral/gray)
  - Shelter name
  - Date submitted (relative: "2 days ago")
  - Click card → navigates to request detail page
- **If 4+ requests:** Show top 3 most recent + "View all {n} requests →" link.

**Visual treatment:** Stacked horizontal cards, each with pet avatar on left, info in middle, status chip on right. Clean, scannable. Each card is a link.

**Empty/first-time state:** Shows the empty state card with illustration + CTA.

**Returning user state:** Active requests prominently visible. Recently updated requests could show a small "NEW" indicator dot.

**CTA behavior:** "Browse Pets" → `pets_path`. "View all requests" → user's adoption requests list page (path to be defined in adoptions plan). Individual card → adoption request detail page.

**Data source:** `current_user.adoption_requests` (from plan #13) ordered by `updated_at DESC`.

---

#### Section 4: Quick Actions
**Purpose:** One-click access to primary actions. Always visible regardless of state.

**Content:**
- 2–4 action cards in a responsive grid (2 columns on mobile, 4 on desktop).
- Suggested actions:
  1. **Browse Pets** (paw icon) — `pets_path`. Description: "Find your new best friend."
  2. **My Profile** (person icon) — `edit_profile_path`. Description: "Update your preferences."
  3. **My Requests** (clipboard icon) — adoption requests path. Description: "Track your applications."
  4. **Favorites** (heart icon) — future path. Description: "Pets you've liked." (Can be omitted until favorites feature exists; replace with "Learn About Adoption" → tips page.)

**Visual treatment:** Small cards with icon, label, and one-line description. Hover shifts border to primary-100. Icon in primary-50 circle.

**Empty/first-time state:** Same cards, CTAs adjust contextually (e.g., "Browse Pets" is primary action).

**Returning user state:** Same cards — these are universal actions.

---

#### Section 5: Tip of the Day (optional, stretch goal)
**Purpose:** Show a helpful, contextual tip about the adoption journey. Builds trust and education. Makes the dashboard feel like a guide, not just a tool.

**Content:**
- Single tip, sourced from a curated list in locale files.
- Tips should be contextual to user state:
  - *New user:* "Did you know? Completing your profile helps us find pets that match your lifestyle — not just any pet, but the right one."
  - *Active searcher:* "Tip: Adoption applications can take 2–7 days. Shelters review each application carefully to find the best match."
  - *Has requests:* "Tip: Don't put all your hopes in one basket! You can submit requests for multiple pets at different shelters."
  - *General:* "Did you know? Tovitu uses AI to analyze your lifestyle and recommend pets with the highest compatibility."
- Rotate randomly on each page load from a pool of ~8–10 tips.

**Visual treatment:** Small card with info icon (primary-500) and subtle primary-50 background. No bold CTA — purely informational.

**Empty/first-time state:** Shows a getting-started tip.

**Returning user state:** Shows relevant stage-based tip.

**Note:** This is a stretch goal for MVP. If scope needs cutting, this section can be deferred.

---

#### Section 6: Ready to Adopt? (conditional, stretch goal)
**Purpose:** If the adopter has completed onboarding but has no active requests, show an encouraging CTA section.

**Content:**
- "You're all set! Your profile is complete and you're ready to find your match."
- Large teal "Browse Pets" button.
- Optional: A fun fact or stat — "Join {n} other adopters finding their match on Tovitu!"

**Empty/first-time state:** This IS the first-time state (after onboarding, before requests).

**Returning user state:** Hidden if user has requests. Could be replaced with "Ready for another?" if all previous requests were resolved.

---

### Shelter Dashboard Sections

The shelter dashboard is the command center — more data-dense than the adopter version, but still playful and clear. Uses a grid layout with distinct card areas.

---

#### Section 1: Greeting + Status Bar
**Purpose:** Welcome the shelter staff, show shelter name, and display a quick snapshot of urgent items.

**Content:**
- **Headline:** "{shelter_name} Dashboard" (Baloo 2)
- **Subtitle:** Day/date context. E.g., "Here's what's happening today."
- **Alert bar (conditional):** If there are pending requests that haven't been viewed, show a prominent bar: "🐾 {n} new adoption requests need your attention!" with "Review Now" link.

**Visual treatment:** No background tint (unlike adopter version). Clean, minimal header area. Alert bar uses secondary-50 background with secondary-600 text for urgency without alarm.

**Empty/first-time state:** Subtitle says "Let's get your shelter set up!" instead.

---

#### Section 2: Onboarding Checklist (conditional — new shelters only)
**Purpose:** Guide new shelters through setup steps. Same as the existing checklist but refined.

**Content (already exists):**
- Progress bar with percentage
- Checklist items with done/not-done indicators
- Items: Add your first pet, Configure adoption policies, Invite staff members, Set your hours, Complete your profile, Publish your shelter
- Each undone item links to the relevant page

**Visual:** Already exists — can be refined but keeps the same structure. Change gradient background to flat primary-50 tint per DESIGN.md guidelines (no gradients except navbar).

**Empty/first-time state:** All items show as undone with 0% progress.

**Returning user state:** Hidden entirely once onboarding is complete (all steps done). This declutters the dashboard for active shelters.

---

#### Section 3: Pipeline Overview (4 metric cards)
**Purpose:** At-a-glance counts for the adoption pipeline. The heartbeat of the shelter dashboard.

**Content:** 4 cards in a row (2×2 on mobile, 4 on desktop). Each card shows:
1. **Adoptable Pets** — Count of pets with status `available`. Icon: paw. Color: primary-500.
2. **Pending Requests** — Count of adoption requests with status `pending`. Icon: clock. Color: warning/amber.
3. **In Review** — Count of requests with status `in_validation`. Icon: search. Color: info/blue.
4. **Active Adoptions** — Count of requests with status `accepted`. Icon: heart. Color: success/teal.

Each card shows:
- Icon in colored circle
- Large number (Baloo 2 display)
- Label text
- Subtle trend indicator if data available (stretch: "↑ 3 from yesterday" style)

**Visual treatment:** White cards, 1px neutral-200 border, rounded-xl. Each has a colored accent icon circle matching its semantic color. Numbers are chunky and playful (Baloo 2). No chart or graph — just numbers.

**Empty/first-time state:** All cards show 0. Cards remain visible but feel empty. The "Adoptable Pets" card shows 0 with no negative connotation — "No pets listed yet" if clicked or hovered.

**Returning user state:** Real counts drive the numbers. Pending requests > 0 becomes an implicit alert.

**Data source:** Queries on `@shelter.pets` and `AdoptionRequest.joins(:pet).where(pets: { shelter_id: @shelter.id })`.

---

#### Section 4: Recent Activity Feed
**Purpose:** Show latest actions on the shelter's adoption pipeline — new requests, status changes, notes.

**Content:**
- List of recent events, newest first. Each event shows:
  - Icon (color-coded for event type)
  - Description: "New request from {adopter_name} for {pet_name}"
  - Timestamp (relative: "10 minutes ago")
  - Link to the relevant request detail page
- Show up to 5 events; "View all activity →" link if more exist.
- Event types to include:
  - New adoption request submitted
  - Request status changed (→ in_validation, → accepted, → declined)
  - Staff note added to a request
  - New team member joined
  - Pet status changed

**Empty state:** "No recent activity. As soon as adopters start requesting your pets, their activity will show up here."

**Visual treatment:** Stacked list with horizontal layout. Each row: icon | description | timestamp. Subtle divider between rows. Clean, scannable.

**Data source:** `AdoptionRequestTimelineEvent` (from plan #13) scoped to the shelter's requests, plus other audit events. For MVP, can start with just adoption request events and grow.

---

#### Section 5: Quick Actions
**Purpose:** One-click shortcuts to common tasks. Always visible.

**Content:** 3–4 action cards:
1. **Add a Pet** (plus icon) — `new_shelter_pet_path`
2. **Review Applications** (clipboard icon) — `shelter_adoption_applications_path`
3. **Manage Team** (users icon) — `shelter_staff_index_path`
4. **Configure Policies** (shield icon) — `edit_shelter_policies_path`

Same card design as adopter quick actions but with shelter-appropriate CTAs.

**Empty/first-time state:** "Add a Pet" highlighted as primary CTA.

**Returning user state:** Same cards — always visible.

---

#### Section 6: Team Status (conditional — multi-staff shelters)
**Purpose:** Show team members and who's online/active. Only relevant for shelters with 2+ staff.

**Content:**
- Avatars/initials of team members
- Online/offline indicator (if tracking — MVP could just list names/roles)
- "Manage Team" link
- Show max 5 members + overflow count

**Visual treatment:** Horizontal row of avatar circles with name below. Compact.

**Empty/first-time state:** Not shown for single-staff shelters or until more members are added.

**Returning user state:** Shown conditionally.

**Data source:** `@shelter.staff_members` (users with `shelter_id` = current shelter).

---

## UI/UX Considerations

### Layout

**Adopter Dashboard:**
- Single-column stacked layout (max-w-2xl or max-w-3xl centered) — calm, guided, narrative-like.
- Sections flow vertically: Welcome → Onboarding (conditional) → My Requests → Quick Actions → Tip.
- No sidebar widgets — the page IS the dashboard. Sidebar provides navigation.
- Responsive: single column on mobile, sections stack naturally. No multi-column grid needed.

**Shelter Dashboard:**
- Wider layout (max-w-5xl or max-w-6xl). Two-column grid at `md:` breakpoint.
- Top: Greeting + Alert bar (full width).
- Row 2: Pipeline metrics (2×2 responsive grid).
- Row 3: Two columns — Left (wider, ~65%): Recent Activity Feed. Right (~35%): Quick Actions + Team Status.
- Bottom (conditional): Onboarding checklist (full width, only for new shelters).
- More data-dense but still generous spacing. No cramped grids.

### Responsive breakpoints
- Mobile (< 768px): Single column, stacked sections. Full-width cards.
- Tablet (768–1024px): Shelter dashboard switches to 2-column for pipeline metrics + activity/actions.
- Desktop (> 1024px): Full layout as described.

### Empty states and first-time experiences

Every section has a considered empty state. No section should just not render — show the empty state with guidance.

| Section | Empty State Copy | CTA |
|---------|-----------------|-----|
| Adopter: My Requests | "You haven't requested to adopt any pets yet. Start browsing to find your match!" | "Browse Pets" |
| Shelter: Recent Activity | "Once adopters start requesting your pets, their activity will show up here." | "Add Your First Pet" |
| Shelter: Pipeline (all zeros) | Cards show "0" — no negative messaging, just neutral. Hovering explains what the section is. | — |
| Adopter: Tip Section | (Always shows a tip — no empty state) | — |
| Adopter: Onboarding (complete) | Hidden entirely | — |
| Shelter: Onboarding (complete) | Hidden entirely | — |

### Role-based differences

| Aspect | Adopter Dashboard | Shelter Dashboard |
|--------|------------------|-------------------|
| Tone | Warm, encouraging, personal | Efficient, capable, overview |
| Layout | Single column, narrative flow | Multi-column, grid, data-dense |
| Max content width | Narrower (max-w-2xl) | Wider (max-w-5xl) |
| Primary metric | Request statuses | Pipeline counts |
| Empty state handling | Playful, inviting | Practical, actionable |
| Onboarding checklist | Shows until profile complete | Shows until shelter fully set up |
| Tips | Adoption journey tips | Best practices for shelters |

### Loading states
- For MVP (Rails-rendered pages, no heavy async), loading states are minimal.
- **Skeleton cards:** Each metric card should have a CSS-only skeleton variant (pulsing neutral-200 shapes) that shows before Turbo Drive finishes loading the page. Use `<turbo-frame>` loading skeleton pattern.
- **Skeleton layout:** A simple grid of gray rectangles matching the card dimensions, with a shimmer animation.
- In practice, since these pages render server-side with mostly synchronous queries, loading states may be nearly instant. Skeleton states matter most for any future async widgets (e.g., AI-powered recommendations).

### Accessibility
- All status badges/chips include `aria-label` describing the status (e.g., `aria-label="Request status: pending"`).
- Empty state illustrations use `role="presentation"` and `aria-hidden="true"`.
- Metric cards use `aria-labelledby` to associate the number with its label.
- All interactive cards (quick actions, request cards) have visible focus rings and are keyboard navigable.
- Color is NEVER the only indicator of status — text labels accompany all colored badges.
- WCAG AA: 4.5:1 contrast for body text, 3:1 for large text (Baloo 2 counts as large text).

### Notification indicators
- If the shelter has unviewed/new adoption requests since last login, the dashboard alert bar shows prominently.
- For adopters, status changes since last visit could be indicated with a subtle "updated" dot on request cards.

---

## Route Design

### New routes needed

```ruby
# Adopter dashboard — a real route at /dashboard
get "/dashboard", to: "dashboard#index", as: :user_dashboard

# Or, more RESTfully:
resource :dashboard, only: [ :show ], controller: "dashboard"
```

The `/dashboard` route should resolve to the correct dashboard based on role:

- **Adopter:** Renders `app/views/dashboard/adopter/show.html.erb` (new view)
- **Shelter user:** Redirects to `shelter_dashboard_path(current_user.shelter_id)` — consistent with existing behavior.

Alternatively, create a dedicated `Adopter::DashboardController`:
```ruby
namespace :adopter do
  resource :dashboard, only: [ :show ]
end
```

**Recommended approach:** Keep `DashboardController#index` but instead of redirecting, render role-specific content:

```ruby
def index
  if current_user.adopter?
    @requests = current_user.adoption_requests.order(updated_at: :desc).limit(3)
    @onboarding_progress = current_user.onboarding_progress_percentage # helper
    render "adopter_dashboard"
  elsif current_user.shelter_user?
    redirect_to shelter_dashboard_path(current_user.shelter_id)
  end
end
```

This keeps one controller entry point while rendering different views. The route becomes:

```ruby
get "dashboard", to: "dashboard#index", as: :user_dashboard
```

And the sidebar (from plan #8) updates the "Dashboard" link for adopters from `pets_path` to `user_dashboard_path`.

---

## Acceptance Criteria

### AC-AD-01: Adopter Dashboard — New user (no onboarding, no requests)

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | Adopter sees a welcome greeting with their name | Visual inspection |
| 2 | Onboarding progress section is shown with 0% progress and 8/8 questions remaining | Visual inspection + data check |
| 3 | "Complete Your Profile" button is present and links to onboarding flow | Click + navigation test |
| 4 | "My Requests" section shows the empty state with "Browse Pets" CTA | Visual inspection |
| 5 | Quick Actions section shows 4 action cards (Browse Pets, My Profile, My Requests, 4th) | Visual inspection |
| 6 | A tip card is visible with a relevant first-time tip | Visual inspection |
| 7 | "Browse Pets" CTA links to `/pets` | Navigation test |

### AC-AD-02: Adopter Dashboard — Active user (onboarding complete, has requests)

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | Onboarding progress section is hidden | Visual inspection |
| 2 | "My Requests" section shows up to 3 request cards with pet name, status badge, shelter name, date | Visual inspection + data check |
| 3 | Each request card links to the request detail page | Click + navigation |
| 4 | Status badges use correct colors: pending=amber, in_validation=blue, accepted=teal, declined=gray | Visual inspection |
| 5 | If 4+ requests exist, "View all {n} requests" link appears after the top 3 | Visual + data check |
| 6 | Quick Actions section still visible | Visual inspection |
| 7 | Welcome greeting shows stage-appropriate subtitle | Visual inspection |

### AC-AD-03: Adopter Dashboard — Responsive

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | On mobile (< 768px), all sections stack in a single column | Resize browser |
| 2 | All CTAs have minimum 44px tap target | DevTools measurement |
| 3 | Text doesn't overflow or get cut off on narrow viewports | Test at 320px width |
| 4 | Quick action cards switch to 2-column grid on mobile, 4-column on desktop | Visual inspection |

### AC-AD-04: Adopter Dashboard — Accessibility

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | All status badges include `aria-label` text | Code review |
| 2 | All interactive cards are keyboard-focusable with visible focus ring | Tab through + visual |
| 3 | Empty state illustrations have `aria-hidden="true"` | Code review |
| 4 | Color alone does not convey status (text label always present) | Code + visual review |
| 5 | Page has a proper `h1` heading | Code review |

### AC-SH-01: Shelter Dashboard — New shelter (no pets, no requests, no staff)

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | Shelter sees "{Shelter Name} Dashboard" heading | Visual inspection |
| 2 | Onboarding checklist shows all steps with 0% progress | Visual inspection |
| 3 | Each undone step links to the relevant setup page | Click + navigation |
| 4 | Pipeline metric cards show 0 for all four metrics | Visual inspection |
| 5 | Recent Activity shows empty state with "Add Your First Pet" CTA | Visual inspection |
| 6 | Quick Actions show 4 cards (Add Pet, Review Applications, Manage Team, Policies) | Visual inspection |
| 7 | Team Status section is hidden (only 1 staff member) | Visual inspection |

### AC-SH-02: Shelter Dashboard — Active shelter (has pets, requests, staff)

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | Pipeline metrics show accurate counts from database | Data check across all 4 cards |
| 2 | Pending requests > 0 triggers alert bar: "🐾 {n} new adoption requests need your attention!" | Visual + data check |
| 3 | Recent Activity shows up to 5 events with correct timestamps and descriptions | Visual + data check |
| 4 | Onboarding checklist is hidden (all steps complete) | Visual inspection |
| 5 | Team Status section shows staff members if 2+ exist | Visual + data check |
| 6 | Clicking an activity event navigates to the relevant detail page | Click + navigation |

### AC-SH-03: Shelter Dashboard — Pipeline metric accuracy

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | "Adoptable Pets" = count of pets with `available` status for this shelter | SQL query comparison |
| 2 | "Pending Requests" = count of adoption requests with `pending` status for this shelter's pets | SQL query comparison |
| 3 | "In Review" = count of requests with `in_validation` status | SQL query comparison |
| 4 | "Active Adoptions" = count of requests with `accepted` status | SQL query comparison |

### AC-SH-04: Shelter Dashboard — Responsive

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | On mobile (< 768px), single column layout, sections stack | Resize browser |
| 2 | On desktop, pipeline metrics in a 4-column row; activity + actions in 2-column layout | Visual inspection |
| 3 | All interactive elements maintain 44px minimum tap target | DevTools |

### AC-SH-05: Shelter Dashboard — Performance

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | Dashboard page loads in under 500ms (with cached queries) | DevTools Network tab |
| 2 | All dashboard queries use eager loading to avoid N+1 (e.g., `pets.undiscounted.includes(:adoption_requests)`) | Code review + bullet gem |

### AC-GEN-01: Routing and redirects

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | `user_dashboard_path` (or equivalent) is a routed path accessible to authenticated users | `rails routes` |
| 2 | Authenticated adopters hitting `user_dashboard_path` see the adopter dashboard (not redirected) | Navigation test |
| 3 | Authenticated shelter users hitting `user_dashboard_path` are redirected to their shelter-specific dashboard | Navigation test |
| 4 | Unauthenticated users trying to access dashboard are redirected to login | Navigation test |
| 5 | After login, adopters land on dashboard (not pets page) | Flow test |
| 6 | After login, shelter users land on their shelter dashboard | Flow test |

### AC-GEN-02: i18n

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | All dashboard text uses `t()` or `I18n.t()` — no hardcoded user-facing strings | Code review |
| 2 | Locale strings exist for both `en.yml` and `es.yml` | File check |
| 3 | Dashboard renders correctly in both English and Spanish (no missing keys) | Visual + log inspection |

### AC-GEN-03: Sidebar integration (from plan #8)

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | Adopter sidebar "Dashboard" link points to `user_dashboard_path` | Code review |
| 2 | Activating the Dashboard link shows active state in sidebar | Visual inspection |
| 3 | Shelter sidebar "Dashboard" link continues to point to `shelter_dashboard_path` | Code review |

---

## Out of Scope

- **Favorites / saved pets widget** — No favorites feature exists yet. A "Favorites" quick action card is listed as optional but implementing favorites is out of scope.
- **AI-powered recommendations on dashboard** — No "recommended for you" section. AI matching is a future phase.
- **Charts, graphs, or data visualizations** — Pipeline metrics show numbers only. No bar charts, sparklines, or trend lines.
- **Customizable dashboard widgets** — Users cannot add/remove/reorder dashboard sections. Fixed layout.
- **Dashboard for unauthenticated users** — Not applicable.
- **Notification preferences** — No dashboard-level notification controls. Existing notification patterns (flash, in-app) are independent.
- **Archived/completed request history beyond basic listing** — No pagination or infinite scroll for request history in MVP. "View all" links to a dedicated page.
- **Shelter activity analytics** (adoption rates, time-to-adoption, etc.) — Future feature.
- **Multi-language support for dashboard tips beyond existing i18n** — Tips are locale-file-driven but pool is shared (contextual, not translated per region — just use i18n as existing).
- **Shelter dashboard for non-admin staff** — All shelter staff see the same dashboard in MVP. Role-based dashboard differences (admin vs. staff) are future.

---

## Risks & Unknowns

### Data availability
- **Adoption requests data:** The adoption requests feature (plan #13) is being designed in parallel. If it's not implemented before the dashboard, the "My Requests" section and pipeline metrics will show empty/zero states. Dashboard implementation should gracefully handle missing data by checking if the `AdoptionRequest` model/table exists.
- **AdoptionRequestTimelineEvent:** The activity feed relies on timeline events from plan #13. MVP could show simpler data (just adoption request creation + status changes) without timeline events if not yet available.
- **`current_user.adoption_requests` association:** Needs to exist before the dashboard can show request data. Coordinate implementation order with plan #13.

### Post-login redirect behavior
- Currently `DashboardController#index` redirects. If we make it render views, we must ensure the redirect behavior for shelter users (to their shelter dashboard) is preserved.
- If we change the authenticated root path, we need to handle the case where a shelter user hits `/dashboard` but hasn't created/joined a shelter yet — they should see a prompt to set up a shelter, not an error.

### Onboarding progress calculation
- **Adopter progress:** Percentage is calculated as (answered questions ÷ total questions) × 100. The onboarding has 8 questions. But some questions may be skip-able — need to confirm whether skipped counts as "answered." Proposal: skipped = incomplete for progress purposes.
- **Shelter progress:** Already exists via `ShelterPresenter#onboarding_progress`. Confirmed working.
- Need a `User#onboarding_progress_percentage` helper method or delegate to `AdopterProfile`/`ShelterProfile`.

### Dashboard performance with many requests
- For shelters with 50+ active requests, the pipeline metrics queries should be fast (simple counts on indexed columns). The activity feed should be limited to 5 items with an efficient query.
- For adopters with many requests, limit "My Requests" display to 3 and link to full list.

### Team status section data
- "Online" status requires presence tracking (not in MVP). Simplest MVP: just list staff names + roles. Skip online indicators.

### Tips content
- Tips need to be written by the product/founder. Propose starting with 5 general tips and expanding. Source them from `config/locales/en.yml` and `es.yml` under `dashboard.adopter.tips.*`.
- If tip section is cut from MVP, it's a clean deferral — no other section depends on it.

### Implementation order dependency
1. Plan #8 (sidebar navigation) should be implemented first — dashboard links need correct routes.
2. Plan #13 (adoption requests) should be implemented first or in parallel — dashboard "My Requests" and pipeline metrics depend on adoption request data.
3. Dashboard views can be implemented with graceful empty states in case plans #8 or #13 are delayed.

---

## Decision Log

| Decision | Options Considered | Chosen Approach | Rationale |
|----------|-------------------|-----------------|-----------|
| Adopter dashboard route | (a) New `Adopter::DashboardController`, (b) Existing `DashboardController#index` renders instead of redirecting | Existing controller, renders role-specific view | Simpler — one controller, one route entry. Avoids unnecessary namespacing at MVP stage. |
| Shelter dashboard: separate or unified | (a) Same `DashboardController` with branching, (b) Keep `Shelters::DashboardController` | Keep separate controller | Already exists and is well-structured. Different layout and data needs. Avoids overloading one controller. |
| Dashboard after login redirect | (a) Redirect to `user_dashboard_path`, (b) override `root_path` for authenticated users | Redirect to `user_dashboard_path` | Cleaner — root remains the landing page for unauthenticated users. Authenticated redirect is standard Rails pattern. |
| Tips section: included or deferred | (a) Include in MVP, (b) Defer to post-MVP | Include (stretch goal) | High value for user guidance, low implementation cost (static content). Can be cut without affecting other sections. |
| Adopter dashboard layout | (a) Grid/widget layout, (b) Single-column narrative | Single-column stacked | Matches the calm, guided tone. Grid layout feels too "metric dashboard" for an adopter. |
| Pipeline metric visual | (a) Cards with numbers, (b) Mini bar charts, (c) Donut charts | Cards with numbers | Numbers are unambiguous, fast to read, and match the bold/playful design system. |
