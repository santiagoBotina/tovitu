# Plan: Completed Onboarding Checklist Dismissal (Bug 5.1)

**Domain:** Shelters, Dashboard
**Priority:** 3 (enhancement — no crash/data impact)
**Status:** Draft
**Tracks:** Bug report §5 (Enhancement)

---

## Overview

Bug 5.1 reports that once onboarding has been completed, the checklist should no longer occupy screen space on the shelter dashboard. A Dismiss/Hide/Clear action should permanently remove the completed checklist.

> ⚠️ **Duplicate of Bug 1.1.** This is the same feature as bug 1.1 ("Completed onboarding checklist cannot be dismissed"), already fully specified in `20_onboarding_bugfixes_plan.md` §"Bug 1.1 + Enhancement 5.1". **Implement once** — track the work under plan 20 and use this plan only as the acceptance/success reference for the enhancement framing. Do not build a second, conflicting implementation.

---

## Problem

- **Business value:** a fully onboarded shelter's dashboard should surface what matters next (pipeline, requests, quick actions), not a permanently-complete checklist. Removing dead weight reduces cognitive load and keeps the "Playground Standard" dashboard feeling deliberate.
- **User story:** As a shelter owner who has completed all onboarding steps, I want to dismiss the completed checklist so my dashboard shows only information I still need.

## Root Cause

- `app/views/shelters/dashboard/show.html.erb:43–54` unconditionally renders the checklist card.
- `app/views/shelters/dashboard/_checklist.html.erb` has no dismiss action and no persisted dismissed state.

## Proposed Solution (reference implementation in plan 20)

1. Show a **Dismiss/Hide** action only when `done_count == total_count` (all 6 steps complete).
2. Persist the dismissed state on the shelter (recommended: `checklist_dismissed_at` column on `shelters`, coordinated with the Data agent).
3. `Shelters::DashboardController#show` omits the checklist when dismissed.
4. Provide a subtle **restore** ("Show checklist") affordance.
5. Add locales in en/es.

## Acceptance Criteria

- **AC-5.1-1** A fully onboarded shelter sees a Dismiss/Hide action on the checklist card.
- **AC-5.1-2** Dismissing removes the checklist and persists across sessions/devices.
- **AC-5.1-3** A restore action exists and works.
- **AC-5.1-4** The action is never shown while any step is incomplete.
- **AC-5.1-5** No regression to progress bar / level-up / confetti behavior when the checklist is still active.

## Success Metrics

- % of fully-onboarded shelters that dismiss within 7 days of feature ship (> 0 proves the affordance is discoverable).
- No increase in shelters that then miss configuration changes (track via restore usage / support tickets).

## Scope

**In scope:** dismiss/restore UI, persistence, dashboard render logic, locales, specs.
**Out of scope:** hiding the checklist before completion; changes to the onboarding steps themselves.

## Relationship to Other Plans

- Implementation lives in plan `20_onboarding_bugfixes_plan.md` (Bug 1.1).
- The persistence field is a schema change — coordinate with the Data agent (per AGENTS.md ownership).
- UI styling follows `DESIGN.md` and plan `22`/`23` conventions (top-right actions, squared badges, i18n).
