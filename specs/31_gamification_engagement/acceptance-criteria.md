# Acceptance Criteria: Gamification & Product Engagement (6.1)

All criteria from `specs/31_gamification_engagement_plan.md` §Acceptance Criteria.

---

## AC-6.1-1: Stepped Adoption Journey on dashboard

```
Given I am an individual user on my dashboard
When I view the readiness card ("Adoption Journey")
Then I see a percentage and a progress bar
And I see a stepped indicator with up to 4 journey stages
    (Getting Started → Building Your Profile → Discovering Matches → Ready to Adopt)
And the current stage is highlighted (purple dot with ring)
And reached stages are teal, unreached are neutral
And below the bar I see the current stage label
And I see a "Next:" line naming the concrete next step
    (e.g. "Next: Complete your profile to unlock better matches")

Given I am a fresh user (no onboarding, no pets, no requests)
Then the current stage is "Getting Started"
And the next step prompts profile completion

Given I have an active request in review
Then the current stage is "Ready to Adopt"
And the next step reads "Your request is with the shelter…"
```

Verified by `spec/requests/dashboard_gamification_spec.rb` (stages render; current-stage label; next-step variants in `spec/lib/gamification/journey_spec.rb`).

---

## AC-6.1-2: "Your Journey" milestone list

```
Given I am an individual user on my dashboard
When I view the "Your Journey" card
Then I see 5 milestones with locked/unlocked states:
    Profile starter, First saved pet, First application, Active applicant, Publisher
And I see a "done/total" progress count (e.g. "1/5 milestones")
And done milestones show a teal chip + check + "Unlocked" pill
And locked milestones show an icon + a hint of the next action
And no points, levels, or leaderboards appear anywhere

Given I am a fresh user
Then all 5 milestones are locked with hints

Given I have completed onboarding, saved a pet, and have a request in review
Then those milestones are unlocked; the rest remain locked
```

Verified by `spec/lib/gamification/journey_spec.rb` (per-milestone predicates) and `spec/requests/dashboard_gamification_spec.rb`.

---

## AC-6.1-3: Milestone feedback on completed actions

```
Given I save my FIRST pet (or submit my first request, or complete onboarding, or publish my first pet)
When the action succeeds
Then I see a brief, non-blocking success toast:
    "Milestone unlocked: First saved pet 🎉" (or equivalent per action)

Given I perform the SAME action a second time
Then NO milestone toast appears (feedback only fires on first completion)

Given I save a pet via AJAX (Turbo Stream)
Then the toast is appended inline to the flash container
And it is fixed-positioned (top-right overlay, same as shared/_flash)
And it auto-dismisses and can be dismissed manually

Given I skip the onboarding wizard instead of completing it
Then NO "Profile starter" milestone toast appears
And I see the plain "you can complete your profile anytime" skipped notice

Given I have prefers-reduced-motion enabled
Then no pop/bounce plays; the toast appears statically
```

Verified by `spec/requests/dashboard_gamification_spec.rb` (first vs repeat, turbo_stream append/no-append, fixed-positioning, skip-path absence), `spec/requests/my/pets_spec.rb` (publisher), `spec/requests/adoption_requests_spec.rb` (first application), `spec/requests/onboarding/wizard_completion_spec.rb` (profile starter, skip-path).

---

## AC-6.1-4: Onboarding nudge with specific missing item

```
Given I am an individual user with onboarding incomplete
When I view my dashboard
Then I see the onboarding card
And it names exactly what's missing (e.g. "Add your lifestyle preferences…")
And the CTA links to the relevant completion step (profile onboarding)

Given I have completed onboarding
Then the onboarding card does not appear
```

Verified by `spec/requests/dashboard_gamification_spec.rb` (nudge shows for incomplete; absent for complete) and `#missing_step` in `journey_spec.rb`.

---

## AC-6.1-5: Data-driven sidebar label

```
Given I am an individual user
Then my sidebar profile label reflects my journey stage
    (e.g. "Getting started" / "Profile in progress" / "Discovering matches" / "Ready to adopt")
And it is NOT the hardcoded "Animal Ally"

Given I am a shelter user with an active shelter
Then the label is "Live & active" (or "Setting up" when not yet active)
And the shelter sidebar never shows the hardcoded "Animal Ally"
```

Verified by `spec/requests/dashboard_gamification_spec.rb` (no "Animal Ally"; label per stage, including shelter live/setup variants).

---

## AC-6.1-6: No fabricated match scores

```
Given I view my dashboard "Top Matches" with saved pets
Then I do NOT see a fabricated percentage match score
And I see an honest "Saved" badge + the pet's real age category

Given I have no saved pets
Then I see the empty state prompting me to save pets
```

Verified by `spec/requests/dashboard_gamification_spec.rb` (body does not match `/\d+% Match/`).

---

## AC-6.1-7: Shelter setup-progress strip

```
Given I am a shelter user on the shelter dashboard
Then I see the plan-19 gamified checklist (levels, progress bar, encouragement)
    covering: publish first pet, set policies, add staff, go live
And my sidebar label reflects live/setup status
```

Already provided by the plan-19 shelter dashboard checklist (`shelters/dashboard/_checklist.html.erb`); sidebar label verified by AC-6.1-5.

---

## AC-6.1-8: i18n + accessibility

```
Given the locale is English or Spanish
Then every new string renders in the active locale (en/es parity)
And milestone toast labels are localized ("shared.toast.dismiss", "gamification.milestone_unlocked.*")

Given I navigate by keyboard
Then the journey indicator, milestone rows, and toasts remain accessible
And WCAG AA contrast is preserved (teal/neutral/purple tokens per DESIGN.md)
```

Verified by locale-key presence in `config/locales/{en,es}.yml` and rendering specs.

---

## AC-6.1-9: No new tables / points system

```
Given a code review of this feature
Then no new database tables were added for gamification
And no points/levels/leaderboards exist in the data model
And milestones/stages are computed from existing models at read time
```

Verified by `git diff db/` — only the plan-32 notifications tracking migration exists (unrelated).

---

## Summary

All 9 acceptance criteria satisfied. Full suite: 1225 examples, 0 failures.
