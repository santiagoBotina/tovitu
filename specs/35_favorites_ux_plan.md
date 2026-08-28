# Plan: Favorites UX — Immediate Feedback & Post-Auth Import (REQ-07, REQ-08, REQ-09)

**Domain:** Frontend, Favorites (Saved Pets), Engagement
**Priority:** 1 (High)
**Status:** Draft
**Tracks:** Epic "Favoritos" (REQ-07, REQ-08, REQ-09)

---

## Overview

Saving and managing favorite pets is a core adoption-journey interaction, but today it feels backend-bound:

1. The heart button reflects state only after the server round trip, and rapid multi-select loses interactions.
2. Removing a saved pet from the favorites page requires a reload-like re-render; the card doesn't leave smoothly.
3. When a user saves pets **before** creating an account and then authenticates, the import of those pets happens with little to no status communication, so users are unsure whether their favorites made it.

This plan makes the favorites interaction feel immediate and trustworthy: optimistic UI with rollback, smooth removal, and a clearly communicated background import after authentication.

---

## Current State (confirmed in code)

- **Save button (`pets/_save_button.html.erb`):** signed-in users submit a `button_to` with `turbo_stream` — the heart reflects state only after the request completes; rapid consecutive clicks on different pets can drop or serialize poorly. Signed-out users use a client-side `pet-interest` controller storing interests locally (this side is already optimistic).
- **Saved pets page (`saved_pets/index.html.erb`):** a grid of pet cards, each with a save/remove button; removing currently relies on a server-driven re-render rather than an immediate animated removal.
- **Post-auth import (`SavedPetsController#import`):** after account creation the app can import locally saved pet IDs (capped at 20, best-effort, available pets only). The current UX gives a one-shot notice; there is no persistent "importing…" state, no automatic list refresh, and failures are not communicated in user-friendly terms.

---

## User Stories

> As an adopter browsing pets,
> I want the heart to react the instant I tap it,
> so that saving pets feels effortless and I can quickly shortlist several pets.

> As a returning adopter,
> I want the pets I removed to disappear from my saved list right away,
> so that my list always reflects what I actually want.

> As a new user who saved pets before signing up,
> I want to know my favorites are being brought over in the background,
> so that I trust nothing was lost when I created my account.

---

## Requirements & Proposed Behavior

### REQ-07 — Save favorites with immediate feedback

The heart interaction becomes optimistic:

1. Tapping the heart changes the visual state **immediately** (filled ↔ outline) with a small save/remove animation.
2. The user does not wait for the network to see the change.
3. Rapid consecutive saves on different pets all work; no interaction is lost.
4. Each interaction dispatches its corresponding backend request/job in the background.
5. The visual state must converge with the backend's final result: if the backend fails, the UI reverts (or self-corrects) and the user is notified in plain language.

**User flow:**
`Browse pets → tap heart → heart fills instantly (animation) → request dispatched in background → success: keep state; failure: revert + gentle notice`

**Edge cases:**
- Rapid toggling the **same** pet (save → unsave quickly): final state matches the **last** action; no race leaves the UI wrong.
- Offline / network failure: revert to previous state + non-technical message; retry is possible on next tap.
- Duplicate save (already saved): no error, no duplicate row, state stays saved.
- Signed-out visitors keep the current local-interest behavior (already optimistic) — this plan focuses on signed-in UX but must not regress the signed-out path.
- The nav bar heart counter (if shown) updates consistently with optimistic changes.

### REQ-08 — Remove favorites without reload

Removing a pet from the saved-pets page is immediate and animated:

1. Removal triggers a short exit animation (e.g., card collapse/fade).
2. The card disappears from the list without a page reload.
3. The backend receives the removal correctly.
4. Other saved pets remain visible and stable.
5. On failure, the card is restored (or the user is informed) — no silent loss of an item the user still wants.
6. Any favorites counter (navbar badge, dashboard) updates immediately.

**Edge cases:**
- Removing the last pet → the empty state appears in place of the grid (still no reload).
- Removing while the list is being filtered/sorted → no reordering side effects.
- Failure mid-removal → card returns to its pre-removal state with a brief, friendly notice.
- Reduced-motion preference → the exit animation is skipped; removal still happens immediately.

### REQ-09 — Communicate favorites import after authentication

After login/sign-up, locally saved favorites are imported in the background with clear status:

1. Immediately after authentication, the user is informed that their favorites are being imported and that it happens in the background.
2. The user can continue using Tovitu during the import.
3. On the **Saved pets** page, a visible notice appears while the import is active.
4. The notice disappears automatically when the import finishes.
5. The favorites list updates automatically when the import completes — **no manual refresh**.
6. Previously saved favorites are never lost during the process.
7. If the import fails, the user sees an understandable state (e.g., "we couldn't import all your favorites — tap to retry"), never a technical error.

**User flow:**
`Authenticate → toast/banner "Importing your favorites…" → continue browsing → Saved pets page shows progress notice → import completes → notice clears, list shows imported pets → (failure path) friendly retry state`

**Edge cases:**
- Import with zero local favorites → no notice at all (nothing to import).
- User authenticates and immediately opens Saved pets before import finishes → they see the "importing" notice, not an empty list.
- Import takes long / user navigates across pages → notice persists on the Saved pets page until done (server-driven state, not a client-only flash).
- Some pets from the local list are no longer available → those are skipped; the notice or summary communicates "N of M imported" so the user understands.
- User closes the tab mid-import → import still completes server-side; next visit shows the final list.
- Import for a shelter-user account (no individual adopters profile) → not applicable; no notice shown.

---

## Acceptance Criteria

- **AC-35-1 (REQ-07)** — Tapping the heart changes the visual state immediately (no waiting for the network).
- **AC-35-2 (REQ-07)** — A save/remove animation plays on toggle; disabled under `prefers-reduced-motion`.
- **AC-35-3 (REQ-07)** — Saving several pets consecutively processes every interaction; no clicks are lost.
- **AC-35-4 (REQ-07)** — The backend request/job is dispatched in the background for each interaction.
- **AC-35-5 (REQ-07)** — The UI converges with the backend result; on failure it reverts and notifies the user in plain language.
- **AC-35-6 (REQ-07)** — Rapid toggling the same pet ends in the state of the last action, with no race-condition mismatch.
- **AC-35-7 (REQ-08)** — Removing a saved pet plays an exit animation and the card disappears without reload.
- **AC-35-8 (REQ-08)** — The backend records the removal; remaining pets stay visible.
- **AC-35-9 (REQ-08)** — On removal failure the card is restored/informed; no silent loss.
- **AC-35-10 (REQ-08)** — Favorites counters (navbar badge, dashboard) update immediately on save/remove.
- **AC-35-11 (REQ-09)** — After authentication, the user is informed their favorites are being imported in the background.
- **AC-35-12 (REQ-09)** — The user can keep using Tovitu during the import.
- **AC-35-13 (REQ-09)** — The Saved pets page shows a status notice while the import is active, which disappears automatically on completion.
- **AC-35-14 (REQ-09)** — The list updates automatically at import completion; no manual refresh.
- **AC-35-15 (REQ-09)** — Pre-existing favorites are preserved through the import.
- **AC-35-16 (REQ-09)** — A failed import shows a comprehensible, retryable state (not a technical error).
- **AC-35-17** — All new strings localized (en/es); WCAG AA contrast; keyboard + screen-reader labels preserved for the heart button (`aria-pressed` reflects optimistic state).

---

## Success Metrics

- **Save-interaction latency**: perceived toggle time < 100 ms (optimistic) vs. current round-trip latency.
- **Saved-pet retention**: share of saved pets still saved after 24 h does not regress (optimistic saves must not create phantom saves).
- **Import completion rate**: % of users with local favorites who end up with those pets in their account (target: no drop vs. current sync import).
- **Support load**: no new "my favorites disappeared" reports.

---

## Test Strategy

- **Stimulus/controller specs** (JS): optimistic toggle, rapid toggling, revert on failure, animation under reduced motion.
- **Request specs**: save/remove endpoints still correct; import status endpoints reflect in-progress → done; failure path.
- **System/manual QA**: rapid multi-save on a real connection, offline toggle, removal on the saved-pets page, full post-auth import journey (success, partial, failure), cross-page navigation during import.
- **i18n check**: en/es parity for all new notices.

---

## Scope

**In scope:** optimistic save/remove UX for signed-in users; animated removal on the saved-pets page; post-auth import status communication + auto-refresh + failure/retry states; counter consistency.

**Out of scope:** Changing the storage of local (signed-out) interests; new favorite-list features (folders, notes, share); recommendation logic; the auth screens themselves (plan 34).

---

## Risks

- **State divergence** — optimistic UI that disagrees with the backend is worse than a slow UI; mitigation: strict converge-on-response rule, single source of truth per pet, revert + notify on failure.
- **Race conditions on rapid toggling** — mitigation: per-pet request queueing/cancellation semantics so the last action wins (Spec agent to define).
- **Import status persistence** — a client-only flash would be lost on navigation; mitigation: import status must be server-derived so it survives navigation and refreshes.
- **Duplicate/phantom favorites** — optimistic saves must be idempotent server-side.
- **Performance** — background dispatch must not block Turbo navigation; keep requests lightweight.

---

## Dependencies

- **Depends on plan 34** (auth): the post-auth import UX (REQ-09) is triggered from the authentication flow.
- **Depends on plan 33** (localization) for new notice copy.
- Precedes plan 37 (engagement) — the dashboard journey card will surface saved-pet milestones on top of this work.