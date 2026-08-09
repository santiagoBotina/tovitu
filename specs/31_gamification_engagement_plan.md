# Plan: Gamification & Product Engagement Improvement (Item 6.1)

**Domain:** Frontend, Engagement, Onboarding, Dashboard
**Priority:** 2 (Medium)
**Status:** Draft
**Tracks:** Product Improvements §6 (Gamification & Product Engagement)

---

## Overview

Tovitu already has gamification groundwork: the shelter onboarding experience (plan 19) introduced a mascot companion, personality results, progress bars, and a dashboard readiness meter; the individual dashboard (`app/views/dashboard/index.html.erb`) has an **Adoption Readiness progress bar**, a Life Preview goal card, and an onboarding completion card. The sidebar shows a static "Animal Ally" label in the user profile card.

This plan **improves how gamification is presented throughout the app**: clearer progress indicators, meaningful achievements/milestones, better visual feedback for completed actions, subtle animations, visible progress toward adoption-related goals, and gentle nudges to complete profiles/onboarding — **without making the app feel overly game-like**. Gamification must support the adoption journey, not distract from it.

---

## Current State (confirmed in code)

- **Dashboard readiness card** (`dashboard/index.html.erb:47–70`): "Adoption Readiness" title, percentage (`@readiness_percent`), a `progress-shimmer` bar (`h-3 rounded-full`, 1000ms transition), and a next-milestone line. Already good bones.
- **Life Preview Goal card** (lines 72–99): shows saved-pet count vs. a goal (clamped to 3), CTA to browse pets. Good existing pattern.
- **Onboarding card** (lines 379–400): gradient card prompting profile completion when `@show_onboarding` is true.
- **Sidebar profile card** (`shared/_sidebar.html.erb:56–66`): static "Animal Ally" label under the user's name — a **hardcoded, non-data-driven label** (no link to actual level/status).
- **Shelter onboarding gamification** (plan 19, implemented per specs `19_shelter_onboarding_gamification`): wizard mascot, personality badge, progress bar, checklist tiers.
- **No achievement/milestone system exists** in the data model. No points, no badges stored server-side. Dashboard top matches use `rand(85..99)` placeholder scores (dashboard/index.html.erb:185) — **not real data**.
- Existing animation utilities: `bento-enter` staggered reveals, `progress-shimmer`, `card-lift`, `score-pop`, `image-reveal` — reusable, dependency-free.

---

## User Stories

> As an adopter,
> I want to see my progress toward being adoption-ready and toward my goal of finding a pet,
> so that completing my profile and exploring pets feels rewarding and purposeful.

> As a shelter user,
> I want to see my shelter's setup progress and celebrate milestones,
> so that getting fully live feels like an achievement, not a chore.

> As a user,
> I want satisfying visual feedback when I complete meaningful actions,
> so that the app feels alive — without turning into a game.

---

## Proposed Improvements

### 1. Readiness meter — make it a true "Adoption Journey" indicator

- Keep the readiness percentage but make the **milestone structure explicit**: define 3–4 named journey stages (e.g., *Getting Started → Building Your Profile → Discovering Matches → Ready to Adopt*), computed from the same inputs that drive `@readiness_percent` today (profile completion, onboarding, saved pets, submitted requests).
- Render as a **stepped progress indicator** (segmented bar or milestone dots along the bar): current stage highlighted, next stage labeled ("Next: Complete your profile → 40%").
- Data source: extend the existing readiness service/presenter (Data/Domain agents to define the stage computation) — **no fabricated scores**; the placeholder `rand(85..99)` in dashboard matches should be removed or replaced with a real label ("Save pets to see your matches") until real matching exists.

### 2. Meaningful achievements / milestones (small, honest set)

Introduce a **lightweight, data-driven milestone list** (server-derived, not points):

| Milestone | Criteria (example) | Visual |
|---|---|---|
| Profile starter | Onboarding completed | Checkmark chip |
| First saved pet | ≥ 1 SavedPet | Heart icon chip |
| First application | ≥ 1 AdoptionRequest submitted | Paper-plane chip |
| Active applicant | ≥ 1 request in review | Clock chip |
| Publisher | First pet published (individuals/shelters) | Paw chip |

- Display: a **"Your journey" card** on the dashboard listing milestones with completed/unlocked states; completed ones get a filled chip + check, in-progress ones show a hint of the next action. No points, no levels, no leaderboards — milestones are *personal progress*, not competition.
- Storage: computed on read from existing models (no new tables at MVP); if server-computed cost is a concern, memoize/cache in the presenter. Add a `milestones` presenter/service in `lib/` (e.g., `Gamification::Milestones`), per domain-agent conventions.
- **Where it appears**: dashboard card + a compact strip on the profile/settings page ("Your adoption journey") to encourage profile completion.

### 3. Visual feedback for completed actions

- **Checklist/task completion**: when a user completes an action that advances a milestone (saves a pet, submits a request, completes onboarding, publishes a pet), show a **brief, non-blocking celebration**: existing `score-pop`/confetti-free pattern — e.g., a small "Milestone unlocked" toast (reuse flash/toast styling in DESIGN.md §5 Flash/Toast) or an inline chip that pops in.
- Use the existing `progress-shimmer` fill animation when percentages increase.
- All feedback **respects `prefers-reduced-motion`** (no bounce/pop under reduced motion; static chip appears instead).

### 4. Onboarding/profile completion nudges

- Strengthen the existing onboarding card: show **exactly what's missing** (e.g., "Add your lifestyle preferences to improve matches — 2 min") instead of a generic prompt.
- Link the profile settings page into the journey ("Your journey" strip on `authentication/profiles/edit.html.erb`) so completing profile fields feels connected to the readiness meter.
- Avoid nagging: show the nudge card only while onboarding is incomplete (as today); after that, surface it as a subtle journey strip, not a modal.

### 5. Sidebar label — make it honest and dynamic

- Replace the hardcoded "Animal Ally" in `_sidebar.html.erb:63` with a **data-driven label** derived from the journey stage (e.g., "Profile in progress" / "Ready to adopt" / shelter: "Live & active") — same small label styling, but real.
- Keep it tiny (one line) so it doesn't add chrome.

### 6. Shelter-side engagement (leverage plan 19)

- Shelter users already have the gamified onboarding; extend the *dashboard* shelter view (if present) with the same milestone strip (publish first pet, set policies, add staff, go live) mirroring the plan-19 checklist — keep it dashboard-side, not a new flow.

---

## Acceptance Criteria (6.1)

- **AC-6.1-1** Dashboard readiness card shows a stepped journey (stages) with a clear next milestone and its requirement — replacing the single generic next-milestone line.
- **AC-6.1-2** A "Your journey" milestone list renders on the dashboard with honest, server-derived milestones (profile starter, first saved pet, first application, etc.); no points, levels, or leaderboards.
- **AC-6.1-3** Completed actions (save pet, submit request, complete onboarding, publish pet) trigger a brief, non-blocking milestone feedback (toast/chip) that is disabled under `prefers-reduced-motion`.
- **AC-6.1-4** The onboarding nudge card shows what's missing and links to the relevant completion step; it disappears once onboarding is complete.
- **AC-6.1-5** The sidebar user label is data-driven (journey stage), not the hardcoded "Animal Ally".
- **AC-6.1-6** The placeholder `rand(85..99)` match scores on the dashboard are removed or replaced with honest empty/real states.
- **AC-6.1-7** Shelter dashboard shows a setup-progress strip (publish first pet, policies, staff, live) mirroring plan-19's checklist where a shelter dashboard exists.
- **AC-6.1-8** All new strings are i18n'd (en/es); WCAG AA contrast; keyboard/focus preserved.
- **AC-6.1-9** No new tables/points system; milestones computed from existing models (verifiable in review).

---

## Success Metrics

- **Onboarding completion rate** increases (or holds) among new users (baseline before/after).
- **Profile completion**: % of users with onboarding complete increases over a cohort period.
- **Engagement quality**: saved-pet and first-application conversion do not regress; users report the app feels "alive but not gamey" (founder/design review of the journey card).
- **Support load**: no increase in "how do I finish my profile" questions.

## Test Strategy

- **Unit/service specs**: milestone computation for each criterion (fresh user, partial profile, first saved pet, first request, published pet).
- **View specs**: journey card renders unlocked/locked states; sidebar label reflects stage; onboarding nudge shows missing item.
- **System/manual QA**: complete actions as individual + shelter; verify toast/chip appears once, reduced-motion disables animation; no dashboard layout regression.
- **i18n check**: en/es parity.

## Scope

**In scope:** journey/readiness stages on dashboard; milestone list (server-derived, no new tables); action feedback (toast/chip); sidebar label; onboarding nudge detail; shelter setup strip; removal of fake match scores.

**Out of scope:** points/badges/levels/leaderboards (explicitly excluded); AR/Home-Prep feature (coming soon — separate); full onboarding redesign (plan 19 scope); gamified notifications.

## Risks

- **Gamification creep** — the biggest risk; every element above is opt-in visual progress, no competition mechanics, and the review gate is "does this support adoption?" before "is this fun?"
- **Milestone definition churn** — keep criteria simple and documented in the presenter so product can tune thresholds without code changes.
- **Fake data leakage** — remove `rand(85..99)`; never invent scores.
- **Performance** — milestone computation must be cheap (single query batch in presenter); cache if needed.
