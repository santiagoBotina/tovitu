# Specification: Gamification & Product Engagement (6.1)

**Domain:** Frontend, Engagement, Onboarding, Dashboard
**Priority:** 2 (Medium)
**Status:** Implemented (all ACs green — 1225 suite, 0 failures)
**Source plan:** `specs/31_gamification_engagement_plan.md`
**Owner:** Frontend Agent (presentation, toast, helper). Journey computation in `lib/gamification/` is presentation-derived data (reads existing models only — no business logic, no new tables).

---

## Overview

Tovitu already had gamification groundwork (shelter onboarding mascot/progress, dashboard readiness bar). This spec improves how progress is *presented* throughout the app: a true stepped "Adoption Journey" indicator, an honest server-derived milestone list, brief non-blocking feedback when milestones unlock, a specific onboarding nudge, and a data-driven sidebar label — **without points, levels, leaderboards, or a game-like feel**. All progress signals derive from existing models at read time.

---

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Storage | **None** — milestones/stages computed on read from existing models (`users.onboarding_completed_at`, `individual_profiles.onboarding_step`, `saved_pets`, `adoption_requests`, `pets` where `publisher_id = user`) | AC-6.1-9: no new tables/points system; cheap batch queries memoized in a single `Context` per request |
| Service | `Gamification::Journey` in `lib/gamification/journey.rb` | Domain-agent convention: `lib/` service objects; presenter-adjacent, view-agnostic |
| Stage/milestone predicates | Declarative lambdas in `STAGES`/`MILESTONES` constants, documented in-file | Product can tune thresholds without touching views (plan risk: milestone definition churn) |
| i18n keys | Stage/milestone labels and hints in `config/locales/{en,es}.yml`; keys resolved via `t(".readiness.stage.#{key}")` etc. | No hardcoded user-facing strings |
| Milestone feedback | Controller helper `milestone_unlocked_message(user, key, was_done:)` returns the message (or nil) when a milestone *transitions* locked→done; callers surface via `redirect_to ... notice:` or an appended turbo_stream toast | Honest feedback: only fires on first completion, never on repeats |
| Toast rendering | `app/views/shared/_milestone_toast.html.erb` mirrors `shared/_flash` styling; appended to `#flash-container` via `turbo_stream.append` for AJAX actions | Consistent with existing flash/toast styling in DESIGN.md; auto-dismiss via `dismiss` stimulus controller |
| Animation | Reuses existing `progress-shimmer`, `bento-enter`, `card-lift`, `score-pop` utilities; all existing reduced-motion blocks remain | Dependency-free; respects `prefers-reduced-motion` |
| Fake data | Removed `rand(85..99)` match scores from dashboard; replaced with an honest "Saved" badge + real age category | Never fabricate data (plan risk: fake data leakage) |

---

## Service: `Gamification::Journey`

### Journey stages (ordered)
| Key | Reached when |
|-----|--------------|
| `getting_started` | Always (baseline) |
| `building_profile` | Onboarding complete OR any profile progress |
| `discovering_matches` | Onboarding complete AND ≥1 saved pet |
| `ready_to_adopt` | Onboarding complete AND ≥1 active request (`pending`/`in_validation`) |

`current_stage` = last stage whose predicate is true (computed by scanning `STAGES` in reverse).

### Milestones (5)
| Key | Icon | Done when |
|-----|------|-----------|
| `profile_starter` | check | onboarding completed |
| `first_saved_pet` | heart | ≥1 SavedPet |
| `first_application` | paper-plane | ≥1 AdoptionRequest |
| `active_applicant` | clock | ≥1 request `pending`/`in_validation` |
| `publisher` | paw | ≥1 published pet (`pets` where `publisher_id`, kept) |

Each milestone carries a `hint` i18n key shown while locked.

### Exposed API
- `current_stage` → stage hash with `:key`
- `stages` → all stages with `:reached`
- `milestones` → all milestones with `:done`
- `completed_milestone_count`, `total_milestone_count`
- `next_milestone` → first locked milestone (or nil)
- `sidebar_label_key` → maps stage to i18n label key
- `next_step_key` → next-action line under the readiness meter
- `missing_step` → `{ key:, path: }` for the onboarding nudge (only `complete_profile` fires while onboarding incomplete; `save_pet`/`submit_request` are general next-best-actions)

### Query batching
A private `Context` value object memoizes `saved_pet_count`, `request_count`, `active_request_count`, `published_pet_count` per request; a single memoized `context` is shared by all predicates.

---

## Controllers

| Action | Milestone | Feedback path |
|--------|-----------|---------------|
| `Pets::SavesController#create` | `first_saved_pet` | `@milestone_notice` → `format.html` notice via redirect; `format.turbo_stream` appends `shared/milestone_toast` to `#flash-container` |
| `AdoptionRequestsController#create` | `first_application` | `redirect_to ... notice: milestone_notice \|\| generic` |
| `My::PetsController#create` | `publisher` | `redirect_to my_pet_path ... notice:` |
| `Onboarding::Individual::CompletionsController#create` | `profile_starter` | `redirect_to ... notice:` |

All callers capture `was_done` **before** the action so the toast only fires on the first completion.

**Skip semantics:** skipping the onboarding wizard (`skip: true` with zero answers) does **not** fire the `profile_starter` toast — skipping is not completing. The wizard still marks `onboarding_completed_at` (existing service behavior), so the milestone *list* may show it unlocked, but no celebration toast is shown for a skip.

**Helper:** `ApplicationController#milestone_unlocked_message(user, milestone_key, was_done:)` — pure (does **not** write to `flash`), so the message is never shown twice (session flash + inline toast). Callers own surfacing.

---

## Views

### `dashboard/index.html.erb`
- **Readiness card** → now "Adoption Journey": percentage + `progress-shimmer` bar + segmented stage indicator (reached=teal segments, current=purple dot w/ ring) + current stage label + `next_step_key` line.
- **New "Your Journey" card** (left column, after Life Preview): `done/total` count + 5 milestone rows; done rows get teal background + check + "Unlocked" pill, locked rows show icon + hint.
- **Saved pet cards (Top Matches)**: `rand(85..99)` removed → honest "Saved" badge (pink heart chip) + real `age_category` from `pets.age_categories.*` locale.
- **Onboarding nudge**: uses `journey.missing_step` to render specific missing-item copy + contextual CTA (only while `@show_onboarding`).

### `shared/_sidebar.html.erb`
- Replaces hardcoded "Animal Ally" with data-driven label: individuals → `journey_label.{sidebar_label_key}`; shelter users → `journey_label.shelter_live|shelter_setup` based on `shelter.active?`; fallback → `label_getting_started`.

### `authentication/profiles/edit.html.erb`
- New compact "Your Adoption Journey" strip (individuals only): milestone chips, done=teal w/ check, locked=neutral. Mirrors dashboard journey card for profile-completion encouragement.

### `shared/_milestone_toast.html.erb`
- Success-styled toast with check icon, message, dismiss button (`t("shared.toast.dismiss")`), auto-dismiss via existing `dismiss` controller. Rendered on full loads via flash and appended inline via turbo_stream for AJAX.

---

## Locales

`en.yml` / `es.yml` additions:
- `shared.toast.dismiss`
- `shared.sidebar.journey_label.*` (4 stage labels + `shelter_setup`/`shelter_live`)
- `dashboard.index.readiness.{stages_label, stage.*, next_step.*}`
- `dashboard.index.journey.{progress, unlocked, milestone.*, hint.*}`
- `dashboard.index.onboarding.{missing.*, cta.*}`
- `dashboard.index.matches.saved` (replaces `match_percent`, `age_years`)
- `authentication.profiles.edit.journey.*`
- `gamification.milestone_unlocked.*` (5 keys)

---

## Out of Scope (unchanged from plan)

Points, badges, levels, leaderboards (explicitly excluded); AR/Home-Prep (separate); full onboarding redesign (plan 19); gamified notifications. Shelter-side engagement reuses plan 19's checklist (levels, progress, encouragement) — no new shelter work in this spec beyond the data-driven sidebar label.

---

## Verification

- `spec/lib/gamification/journey_spec.rb` — 23 unit specs (stages, milestones, next-step, missing-step, sidebar label).
- `spec/requests/dashboard_gamification_spec.rb` — 15 request specs (journey card, milestone list, onboarding nudge, no-fake-score, sidebar label individual + shelter variants, toast-on-first-save, no-toast-on-repeat, turbo_stream append, fixed positioning).
- `spec/requests/my/pets_spec.rb` — publisher milestone flash (first vs repeat).
- Milestone flash specs added to `spec/requests/adoption_requests_spec.rb` and `spec/requests/onboarding/wizard_completion_spec.rb` (including skip-path and repeat-completion no-toast cases).
- Full suite: `bundle exec rspec` → 1225+ examples, 0 failures.
