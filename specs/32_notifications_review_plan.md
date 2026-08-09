# Plan: Notifications Review & Channel Strategy (Items 7.1 – 7.2)

**Domain:** Notifications, Email, Messaging
**Priority:** 1 (High) — review first; implementation scoped after findings
**Status:** Implemented — Phase A + B complete, Phase C documented pending founder sign-off
**Tracks:** Product Improvements §7 (Notifications)

> **Implementation record (2026-08-09):** The audit matrix lives in
> [`specs/notifications/matrix.md`](./notifications/matrix.md). Phase A (email gaps:
> welcome wired, dedup guard, delivery tracking, `set_locale` fix, footer link) and
> Phase B (per-kind email toggles + precedence fix + i18n) are implemented and tested.
> Phase C items that are code (table-driven `EmailRouting` registry, per-kind model in
> the preferences UI) are implemented; items requiring product/founder sign-off
> (channel matrix, web-push/SMS/digest/WhatsApp deferrals) are recorded in the matrix
> as decisions D1–D10 pending sign-off.
>
> **Review follow-ups (2026-08-09):** real delivery outcomes are now written back onto
> the `Notification` record via `Notifications::DeliveryTracker` (D12); the `in_app`
> preference is honored (no record when in-app disabled — D11); dead `lib/adoptions/notify_*`
> services removed (D13). All 1248 examples green.

---

## Overview

Two related items:

- **7.1** Review the current email notification system: which events generate emails, which notifications are missing, timing, clarity, duplicates, and user control.
- **7.2** Evaluate additional notification channels (in-app, push, WhatsApp, SMS, browser) and define a per-event **channel strategy** — not "everything through every channel."

This plan is **review + strategy first, implementation second**. The deliverables are: (a) a documented audit of the current notification/email behavior, (b) a prioritized list of gaps and fixes, and (c) a channel-by-event recommendation matrix. Implementation tickets derive from the matrix.

---

## Current State (confirmed in code)

### Notification kinds (data model)
`app/models/notification.rb` defines 10 kinds:
`request_submitted`, `request_in_validation`, `request_accepted`, `request_declined`, `request_withdrawn`, `info_requested`, `info_received`, `message_received`, `pet_status_changed`, `welcome`.

### Delivery orchestration
`lib/notifications/deliver.rb` — single entry point (`Notifications::Deliver.call(recipient:, kind:, notifiable:, title:, body:, ...)`):
1. Creates the `Notification` **record** (this IS the in-app notification).
2. Checks `NotificationPreference` via `kind_enabled?(kind, channel)` (supports per-kind overrides in `per_kind_overrides`, though the UI only exposes 3 global toggles).
3. Dispatches to `deliver_email` / `deliver_whatsapp` based on preferences.

### Email delivery map (confirmed in `deliver.rb`)

**Key distinction:** a kind can be *declared* (in the enum), *triggered* (production code actually calls `Deliver` with it), and *emailed*. Only 5 kinds are ever triggered today; the other 5 have no production call sites at all.

| Kind | Triggered today? | Email delivered? | Implementation |
|---|---|---|---|
| request_submitted | ✅ (adopter + shelter staff / publisher) | ✅ adopter → `request_confirmation`; others → `new_request_notification` | `AdoptionMailer` |
| request_accepted / declined / in_validation | ✅ (via `ProcessRequest`) | ✅ `status_changed` | `AdoptionMailer` |
| request_withdrawn | ✅ (via `WithdrawRequest`) | ✅ `request_withdrawn` | `AdoptionMailer` |
| info_requested / info_received | ❌ **No production call sites** | ⚠️ routes to `status_changed` (generic) — moot until triggered | `AdoptionMailer` |
| message_received | ❌ **No production call sites** | ❌ **Not implemented** (log only) | — |
| pet_status_changed | ❌ **No production call sites** | ❌ **Not implemented** (log only) | — |
| welcome | ❌ **No production call sites** | ❌ **Not implemented** (log only; claims AuthenticationMailer) | — |

### Preference model & UI
- `NotificationPreference` (`app/models/notification_preference.rb`): `in_app`, `email`, `whatsapp` booleans; `whatsapp_phone`; `whatsapp_verified_at`; supports `per_kind_overrides` JSON but **no UI exposes per-kind overrides**.
- UI (`app/views/notification_preferences/edit.html.erb`): three global toggles (In-App, Email, WhatsApp). WhatsApp has a phone field + verification flow (`notification-bell` Stimulus controller). Some UI copy is **hardcoded English** ("Receive notifications inside the app", "Receive email notifications") instead of i18n — must fix.
- Defaults: `in_app = true`, `email = true`, `whatsapp = false` (`defaults_for`).

### Where notifications are triggered (confirmed)
- `lib/adoptions/submit_request.rb` (3 branches: adopter + per shelter-staff / publisher), `withdraw_request.rb` (2 branches), `process_request.rb` (1 — status changes/decisions). `DeclineRequest` delegates to `ProcessRequest`; decline reasons are stored in timeline-event metadata.
- **Dead kinds:** `welcome`, `pet_status_changed`, `message_received`, `info_requested`, `info_received` have **zero production call sites** — no code ever delivers them. These are *missing events*, not just missing emails. The audit must record a wire / defer / remove decision per kind.
- **Parallel domain layer:** `app/domains/adoptions/*` (legacy, not wired to controllers) contains `ProcessApplication` with `approve / reject / request_info / info_received / cancel` actions on the separate `AdoptionApplication` model — the only place `info_requested`/`info_received` semantically occur, and it never calls `Notifications::Deliver`. The live flow is `AdoptionRequest` + `lib/adoptions/*`; the legacy layer is a hygiene risk (see Risks).
- No notifications for: account welcome at registration, saved-pet activity, pet published, profile-completion nudges, lifecycle reminders (e.g., "application still in review"), or shelter setup nudges.

### WhatsApp
- `deliver_whatsapp` is a **stub** (no provider integration yet; commented "implemented when WhatsApp provider is ready"). Messaging vendor isolation exists via `Messaging::*` service objects per AGENTS.md.

---

## Item 7.1 — Email notification review

### Problems

1. **Missing emails**: `message_received`, `pet_status_changed`, `welcome` are declared kinds with no email implementation (silently logged).
2. **Missing events, not just emails**: `welcome`, `pet_status_changed`, `message_received`, `info_requested`, `info_received` are **never triggered anywhere** in production code (no call sites). Decisions are needed to wire the event, defer, or remove the kind.
3. **Generic email for distinct events**: `info_requested` / `info_received` reuse `status_changed` — the email subject/body likely doesn't communicate "we asked for more info" vs. "your status changed." (Only relevant if the kinds are kept and triggered.)
4. **Timing**: emails are sent immediately at event time via `deliver_later`; no batching/digest, no delay for human-verifiable events.
5. **Clarity**: `status_changed` is one mailer method for accepted/declined/in_validation — subjects are per-status but body copy needs review for each status.
6. **Duplicates risk**: a single event can produce multiple notifications (e.g., submit_request notifies adopter + shelter staff + publisher) — need to confirm no double-send for the same recipient+event.
7. **No per-kind control in UI**: users can only toggle all email on/off, not choose "don't email me about X."
8. **i18n leak + broken mailer locale**: hardcoded English in the preferences UI; `AdoptionMailer#set_locale` assigns `@locale` (used only in CTA URLs) but **never wraps rendering in `I18n.with_locale`** — email content renders in whatever locale was active at enqueue time, while the link points to `@adopter&.locale`. For `new_request_notification` to shelter staff, `@adopter` is always present, so staff receive links in the *adopter's* language (mixed-language emails).
9. **Silent delivery failures**: `deliver_email` swallows all exceptions (log-only), and `ProcessRequest#deliver_notifications` only warns on failure. No delivery status on the `Notification` record, no retry — "I never got notified" issues are undebuggable.
10. **Preference precedence bug**: `NotificationPreference#kind_enabled?` checks `per_kind_overrides` *before* the global toggle, so a stale per-kind override can resurrect email after the user disables the global toggle — and there's no UI to clear overrides.
11. **Declined-reason coupling**: the `status_changed` mailer renders `@request.decline_reasons`, which `DeclineRequest` stores only in timeline-event metadata — the mailer depends on timeline parsing (works, but fragile).

### Proposed Review Process

1. **Produce a notification matrix** (document in `/specs/notifications/` — owner: Product; e.g., `specs/notifications/matrix.md`): event → kind → recipients → **triggered today?** → email today → recommended email → timing → per-kind control → **proposed new kinds** (with priority).
2. **Audit each of the 10 kinds** for: who should be notified (adopter, publisher, shelter staff), what email copy says, whether the email adds value or is noise. Split "declared but never triggered" from "triggered but no email" and record a **wire / defer / remove** decision per kind.
3. **Close the obvious gaps** (recommended Phase 1 scope):
   - Implement `welcome` email (or deliberately skip with a decision: AuthenticationMailer has `verification` already — a welcome/onboarding email is high-value). Note: `welcome` also needs a **trigger** (registration flow) — decide where it fires.
   - Implement `message_received` email when messaging lands (Phase 2 of messaging; gate on that) — note in matrix. It also needs a trigger from `Messaging::*`.
   - Decide `info_requested`/`info_received`: the live `AdoptionRequest` flow has no "request info" action today (the concept exists only in the legacy `ProcessApplication` layer). Either build the feature into the live flow and wire notifications, or remove the kinds.
   - Decide `pet_status_changed`: wire it from `Pets::ChangeStatus` to saved/watching users (saved-pet activity) or remove the kind.
   - Split `info_requested`/`info_received` into distinct mailer methods with clear subjects/copy (only if the kinds are kept and triggered).
   - Review `status_changed` copy per status.
4. **Dedup check**: ensure one email per (recipient, event, kind); add a guard **inside `Notifications::Deliver`** (before record creation), not at call sites.
5. **User control**: extend the preferences UI to per-kind toggles (at least for email) OR document a simpler model (e.g., "Email me: [request updates] [messages] [news]") — recommend the simpler category model over a 10-row matrix for MVP. Decide **override precedence** explicitly (recommend: global OFF wins over per-kind overrides) and add a test.
6. **i18n**: fix hardcoded strings; **fix `AdoptionMailer#set_locale`** to render inside `I18n.with_locale` and resolve locale per recipient type (adopter vs publisher vs shelter staff) — with mailer specs asserting each path.
7. **Deliverability & observability**: review `ApplicationMailer` defaults (from address, reply-to), batching needs, and unsubscribe expectations (transactional emails may be exempt from bulk-unsubscribe, but a clear "manage notifications" link in footers is good practice). **Add delivery tracking** (e.g., `email_delivered_at` / `email_failed_at` on `Notification`, or a delivery log) so silent email failures are visible and retryable.
8. **Enumerate proposed new kinds** in the matrix (beyond the existing 10): hold expiry (ties to `hold_expires_at` + `ExpireHold`), pet published, saved-pet activity, profile-completion nudges, in-review reminders — with priority and recommended channel.

### Acceptance Criteria (7.1)

- **AC-7.1-1** A completed notification matrix exists in specs, covering all 10 declared kinds **plus proposed new kinds**, documenting event, recipients, **triggered today?**, current vs. recommended email behavior, timing, and per-kind control.
- **AC-7.1-2** Every declared kind has a recorded decision: wired + working email, wired + defer (follow-up ticket), or **removed as dead kind**. Every "wired" kind has a real production call site.
- **AC-7.1-3** `info_requested`/`info_received` have distinct mailer methods with clear subjects/copy (no generic `status_changed` reuse) **if the kinds are kept and triggered**; otherwise the removal decision is recorded.
- **AC-7.1-4** No duplicate email is sent for a single (recipient, event) occurrence — guarded inside `Notifications::Deliver` and verified by test.
- **AC-7.1-5** Users can control email at a meaningful granularity (per-category or per-kind) via the preferences UI — no longer all-or-nothing. Global OFF wins over per-kind overrides (tested).
- **AC-7.1-6** All preferences UI strings are i18n'd (en/es); `AdoptionMailer#set_locale` is fixed to render inside `I18n.with_locale` and resolves locale correctly for adopter, publisher, and shelter-staff recipients (mailer specs per recipient type).
- **AC-7.1-7** Emails include a "manage notification preferences" link (or equivalent control) in the footer.
- **AC-7.1-8** Email delivery outcomes are tracked (sent/failed) on the `Notification` record or a delivery log; a failed email is visible and retryable, not silently swallowed.

---

## Item 7.2 — Additional notification channels & strategy

### Problems

- Everything is email + in-app today; WhatsApp is a stub.
- No channel strategy: we don't know which events should be urgent (push/WhatsApp), routine (email), or ambient (in-app).

### Proposed Channel Evaluation

Evaluate each channel against: setup cost, user value, urgency fit, and vendor dependencies. Current state:

| Channel | Status today | Vendor | Notes |
|---|---|---|---|
| In-app | ✅ Live (record + bell + index) | — | Real-time via ActionCable is a future enhancement (`deliver.rb` comment) |
| Email | ✅ Live (partial) | SMTP | Most complete; gaps in 7.1 |
| WhatsApp | 🔧 Stub | WhatsApp Business API | Planned in stack; opt-in + verified phone exists; high urgency potential |
| Push (mobile/web) | ❌ Not present | — | PWA exists (`app/views/pwa`) — web push feasible; mobile app later |
| SMS | ❌ Not present | — | High cost/urgency-only; likely out of MVP |
| Browser notifications | ❌ Not present | — | Cheap; pairs with PWA |

### Recommended Channel Strategy (draft matrix — refine with founder)

| Event kind | Urgency | Recommended channels |
|---|---|---|
| request_submitted (to shelter/publisher) | High | In-app + Email (+ WhatsApp if opted-in, shelter staff) |
| request_submitted (confirmation to adopter) | Routine | In-app + Email |
| request_accepted | High | In-app + Email + WhatsApp (adopter) |
| request_declined | High | In-app + Email (+ WhatsApp) — sensitive; copy matters |
| request_in_validation | Routine | In-app + Email |
| request_withdrawn | Routine | In-app + Email |
| info_requested / info_received | Medium | In-app + Email |
| message_received | Medium | In-app (+ Email digest optional; avoid per-message email) |
| pet_status_changed | Medium | In-app + Email |
| welcome / onboarding | Routine | Email (welcome), In-app nudge |
| Re-engagement (saved pets, in-review reminders) | Low/Medium | In-app + optional Email digest (weekly) |

**Principles:**
1. **Urgency decides channel**: High urgency → WhatsApp/push; Routine → email; Ambient → in-app only.
2. **Opt-in only** for interruptive channels (WhatsApp, push, SMS).
3. **No event through every channel** — every event gets a primary + at most one secondary channel.
4. **Digest for low-urgency** (e.g., message_received, saved-pet activity) rather than per-event email.
5. **Browser/web push** is the cheapest interruptive win given the PWA; evaluate before mobile push.
6. **SMS deferred** — high cost, low differentiation at MVP; revisit post-launch.

### Proposed Changes

1. Finalize the channel matrix with the founder (product decision) and record it in the notification matrix doc — including **proposed new kinds** (hold expiry, pet published, saved-pet activity) so channels are decided once, not retrofitted.
2. Implement per-channel opt-in UX (preferences UI): WhatsApp verified + push opt-in; keep in-app always-on with a mute option.
3. Phase the builds: (a) complete email gaps (7.1), (b) WhatsApp delivery for the high-urgency kinds once provider is ready (via `Messaging::*` — keep vendor isolation), (c) web push via PWA service worker as a stretch, (d) ActionCable real-time in-app as a stretch.
4. Add a **channel delivery guard** in `Notifications::Deliver` so future channels plug into the same matrix (single place to decide what goes where).
5. **Refactor `deliver_email`**: extract the `case kind` dispatch into a kind → mailer registry (mapping object) so new kinds plug in via one mapping instead of a growing case statement. Keep routing logic in the notifications domain — do not leak channel decisions into `lib/adoptions/*`.
6. **Scope the digest**: decide build vs. defer for a low-urgency digest (e.g., weekly job + aggregate mailer for `message_received` / saved-pet activity). If deferred, record a follow-up ticket — AC-7.2-4 is not satisfiable without scheduling infrastructure.

### Acceptance Criteria (7.2)

- **AC-7.2-1** A final channel × event matrix exists in specs with founder sign-off, applying the urgency principle (no event on all channels) — covering all existing kinds **and proposed new kinds**.
- **AC-7.2-2** Interruptive channels (WhatsApp, push, SMS) are opt-in only and gated on verification (WhatsApp) or permission (push).
- **AC-7.2-3** WhatsApp delivery is implemented for at least the high-urgency kinds (accepted, declined, new request to shelter) behind `Messaging::*` isolation, when the provider is available.
- **AC-7.2-4** Low-urgency events use in-app + (optional) digest rather than per-event email (documented in matrix); the digest is either built (scheduled job + aggregate template) or explicitly deferred with a follow-up ticket.
- **AC-7.2-5** `Notifications::Deliver` routes channels via the strategy (single decision point), and the preferences UI reflects the per-channel/per-kind model.
- **AC-7.2-6** Web push feasibility is evaluated (PWA service worker) and a build/no-build decision is recorded.
- **AC-7.2-7** SMS is explicitly deferred with rationale recorded.
- **AC-7.2-8** `deliver_email` dispatch is table-driven (kind → mailer registry), no growing case statement; new kinds register via one mapping.

---

## Success Metrics

- **Email audit completeness**: 100% of kinds mapped in the matrix with a build/defer decision (7.1).
- **User control**: users can meaningfully control notification frequency/channels (qualitative + settings-page usage).
- **Notification value**: reduction in "I never got notified" support issues; increase in request-response time from shelter staff for high-urgency kinds (if measurable).
- **Channel efficiency**: WhatsApp/push reserved for high-urgency events (audit shows no low-urgency interruptive sends).

## Test Strategy

- **Service specs**: `Notifications::Deliver` routes per strategy; dedup guard; per-kind overrides respected and global OFF wins.
- **Mailer specs**: new/updated mailers (info_requested/received, welcome) with subject/copy per status and correct locale per recipient type (adopter / publisher / shelter staff).
- **Request specs**: preferences update with per-kind toggles; i18n coverage.
- **Manual QA**: walk the full request lifecycle as adopter/shelter; confirm emails, in-app, (WhatsApp when wired) arrive per matrix; confirm no duplicates.
- **PWA/push**: manual service-worker test if web push is scoped.

## Scope

**In scope (7.1):** notification matrix (incl. triggered-today audit + proposed new kinds); dead-kind decisions (wire / defer / remove); missing emails (welcome, info split, status copy review); `AdoptionMailer#set_locale` fix; dedup guard inside `Notifications::Deliver`; preference granularity + precedence fix + i18n; footer manage link; email delivery tracking (observability).
**In scope (7.2):** channel strategy matrix + founder sign-off; opt-in UX; WhatsApp wiring for high-urgency kinds (behind `Messaging::*` interface); delivery router refactor (kind → channel strategy + kind → mailer registry); web-push evaluation; digest build-or-defer decision.

**Out of scope:** actual SMS implementation; mobile-native push (iOS/Android apps); ActionCable real-time unless scoped as stretch; redesigning the in-app notification feed UI (separate); cleanup of the legacy `app/domains/adoptions/*` layer (track separately).

---

## Phasing & Handoff

Phase the acceptance criteria so the founder sign-off (7.2) is a clean gate:

- **Phase A — Audit & email gaps (7.1 core):** matrix (incl. triggered-today + new kinds), dead-kind decisions, missing emails, `set_locale` fix, dedup guard, delivery tracking. → AC-7.1-1, -2, -3, -4, -6, -7, -8.
- **Phase B — User control:** preference granularity + precedence fix + i18n of preferences UI. → AC-7.1-5.
- **Phase C — Channels (7.2):** channel matrix sign-off, opt-in UX, WhatsApp wiring (provider-gated), router/registry refactor, web-push evaluation, digest build-or-defer. → AC-7.2-1..8.

Per AGENTS.md, once the matrix is signed, convert this plan into `specs/notifications/specification.md` + `specs/notifications/acceptance-criteria.md`; implementation tickets derive from the matrix. Matrix doc owner: Product.

## Risks

- **Channel sprawl** — the matrix must be enforced by the router; every new kind goes through the same decision point.
- **WhatsApp cost/compliance** — opt-in + verified phone only; transactional templates require provider approval; keep vendor isolation so switching providers is cheap.
- **Email fatigue** — prefer digest for low-urgency; review email volume after launch.
- **Welcome email timing** — coordinate with verification email to avoid double-email at signup (send welcome after verification).
- **Dual adoption domains** — `app/domains/adoptions/*` (legacy, on `AdoptionApplication`) parallels `lib/adoptions/*` (live, on `AdoptionRequest`). Notification work must target the canonical flow; flag the legacy layer for cleanup so future notifications don't land in the wrong place.
- **Locale mixing** — until `set_locale` is fixed, shelter staff can receive content in one language and links in another; fix first, then audit copy.
