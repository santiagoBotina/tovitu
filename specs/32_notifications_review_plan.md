# Plan: Notifications Review & Channel Strategy (Items 7.1 – 7.2)

**Domain:** Notifications, Email, Messaging
**Priority:** 1 (High) — review first; implementation scoped after findings
**Status:** Draft
**Tracks:** Product Improvements §7 (Notifications)

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

| Kind | Email delivered? | Implementation |
|---|---|---|
| request_submitted | ✅ adopter → `request_confirmation`; others → `new_request_notification` | `AdoptionMailer` |
| request_accepted / declined / in_validation | ✅ `status_changed` | `AdoptionMailer` |
| request_withdrawn | ✅ `request_withdrawn` | `AdoptionMailer` |
| info_requested / info_received | ⚠️ routes to `status_changed` (generic) | `AdoptionMailer` |
| message_received | ❌ **Not implemented** (log only) | — |
| pet_status_changed | ❌ **Not implemented** (log only) | — |
| welcome | ❌ **Not implemented** (log only; claims AuthenticationMailer) | — |

### Preference model & UI
- `NotificationPreference` (`app/models/notification_preference.rb`): `in_app`, `email`, `whatsapp` booleans; `whatsapp_phone`; `whatsapp_verified_at`; supports `per_kind_overrides` JSON but **no UI exposes per-kind overrides**.
- UI (`app/views/notification_preferences/edit.html.erb`): three global toggles (In-App, Email, WhatsApp). WhatsApp has a phone field + verification flow (`notification-bell` Stimulus controller). Some UI copy is **hardcoded English** ("Receive notifications inside the app", "Receive email notifications") instead of i18n — must fix.
- Defaults: `in_app = true`, `email = true`, `whatsapp = false` (`defaults_for`).

### Where notifications are triggered (confirmed)
- `lib/adoptions/submit_request.rb` (3 call sites), `withdraw_request.rb` (2 sites), `process_request.rb` (1 site — status changes/decisions).
- No notifications for: account welcome at registration, saved-pet activity, pet published, profile-completion nudges, lifecycle reminders (e.g., "application still in review"), or shelter setup nudges.

### WhatsApp
- `deliver_whatsapp` is a **stub** (no provider integration yet; commented "implemented when WhatsApp provider is ready"). Messaging vendor isolation exists via `Messaging::*` service objects per AGENTS.md.

---

## Item 7.1 — Email notification review

### Problems

1. **Missing emails**: `message_received`, `pet_status_changed`, `welcome` are declared kinds with no email implementation (silently logged).
2. **Generic email for distinct events**: `info_requested` / `info_received` reuse `status_changed` — the email subject/body likely doesn't communicate "we asked for more info" vs. "your status changed."
3. **Timing**: emails are sent immediately at event time via `deliver_later`; no batching/digest, no delay for human-verifiable events.
4. **Clarity**: `status_changed` is one mailer method for accepted/declined/in_validation — subjects are per-status but body copy needs review for each status.
5. **Duplicates risk**: a single event can produce multiple notifications (e.g., submit_request notifies adopter + shelter staff + publisher) — need to confirm no double-send for the same recipient+event.
6. **No per-kind control in UI**: users can only toggle all email on/off, not choose "don't email me about X."
7. **i18n leak**: hardcoded English in the preferences UI; mailers use `t()` but locale handling in `AdoptionMailer#set_locale` assumes `@adopter`/`@recipient` — verify for all paths (esp. shelter recipients).

### Proposed Review Process

1. **Produce a notification matrix** (document in `/specs/` — Product owns specs; the matrix goes in this plan's final form or a sibling doc): event → kind → recipients → email today → recommended email → timing → per-kind control.
2. **Audit each of the 10 kinds** for: who should be notified (adopter, publisher, shelter staff), what email copy says, whether the email adds value or is noise.
3. **Close the obvious gaps** (recommended Phase 1 scope):
   - Implement `welcome` email (or deliberately skip with a decision: AuthenticationMailer has `verification` already — a welcome/onboarding email is high-value).
   - Implement `message_received` email when messaging lands (Phase 2 of messaging; gate on that) — note in matrix.
   - Split `info_requested`/`info_received` into distinct mailer methods with clear subjects/copy.
   - Review `status_changed` copy per status.
4. **Dedup check**: ensure one email per (recipient, event, kind); add a guard if needed.
5. **User control**: extend the preferences UI to per-kind toggles (at least for email) OR document a simpler model (e.g., "Email me: [request updates] [messages] [news]") — recommend the simpler category model over a 10-row matrix for MVP.
6. **i18n**: fix hardcoded strings; ensure mailer locale resolution works for all recipient types.
7. **Deliverability hygiene**: review `ApplicationMailer` defaults (from address, reply-to), batching needs, and unsubscribe expectations (transactional emails may be exempt from bulk-unsubscribe, but a clear "manage notifications" link in footers is good practice).

### Acceptance Criteria (7.1)

- **AC-7.1-1** A completed notification matrix (all 10 kinds) exists in specs, documenting event, recipients, current vs. recommended email behavior, and timing.
- **AC-7.1-2** Every declared kind either has a working email implementation or an explicit, recorded decision to defer (with a follow-up ticket).
- **AC-7.1-3** `info_requested`/`info_received` have distinct mailer methods with clear subjects/copy (no generic `status_changed` reuse).
- **AC-7.1-4** No duplicate email is sent for a single (recipient, event) occurrence (verified by test).
- **AC-7.1-5** Users can control email at a meaningful granularity (per-category or per-kind) via the preferences UI — no longer all-or-nothing.
- **AC-7.1-6** All preferences UI strings are i18n'd (en/es); mailers resolve locale for adopter, publisher, and shelter recipients.
- **AC-7.1-7** Emails include a "manage notification preferences" link (or equivalent control) in the footer.

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

1. Finalize the channel matrix with the founder (product decision) and record it in the notification matrix doc.
2. Implement per-channel opt-in UX (preferences UI): WhatsApp verified + push opt-in; keep in-app always-on with a mute option.
3. Phase the builds: (a) complete email gaps (7.1), (b) WhatsApp delivery for the high-urgency kinds once provider is ready (via `Messaging::*` — keep vendor isolation), (c) web push via PWA service worker as a stretch, (d) ActionCable real-time in-app as a stretch.
4. Add a **channel delivery guard** in `Notifications::Deliver` so future channels plug into the same matrix (single place to decide what goes where).

### Acceptance Criteria (7.2)

- **AC-7.2-1** A final channel × event matrix exists in specs with founder sign-off, applying the urgency principle (no event on all channels).
- **AC-7.2-2** Interruptive channels (WhatsApp, push, SMS) are opt-in only and gated on verification (WhatsApp) or permission (push).
- **AC-7.2-3** WhatsApp delivery is implemented for at least the high-urgency kinds (accepted, declined, new request to shelter) behind `Messaging::*` isolation, when the provider is available.
- **AC-7.2-4** Low-urgency events use in-app + (optional) digest rather than per-event email (documented in matrix).
- **AC-7.2-5** `Notifications::Deliver` routes channels via the strategy (single decision point), and the preferences UI reflects the per-channel/per-kind model.
- **AC-7.2-6** Web push feasibility is evaluated (PWA service worker) and a build/no-build decision is recorded.
- **AC-7.2-7** SMS is explicitly deferred with rationale recorded.

---

## Success Metrics

- **Email audit completeness**: 100% of kinds mapped in the matrix with a build/defer decision (7.1).
- **User control**: users can meaningfully control notification frequency/channels (qualitative + settings-page usage).
- **Notification value**: reduction in "I never got notified" support issues; increase in request-response time from shelter staff for high-urgency kinds (if measurable).
- **Channel efficiency**: WhatsApp/push reserved for high-urgency events (audit shows no low-urgency interruptive sends).

## Test Strategy

- **Service specs**: `Notifications::Deliver` routes per strategy; dedup guard; per-kind overrides respected.
- **Mailer specs**: new/updated mailers (info_requested/received, welcome) with subject/copy per status and correct locale.
- **Request specs**: preferences update with per-kind toggles; i18n coverage.
- **Manual QA**: walk the full request lifecycle as adopter/shelter; confirm emails, in-app, (WhatsApp when wired) arrive per matrix; confirm no duplicates.
- **PWA/push**: manual service-worker test if web push is scoped.

## Scope

**In scope (7.1):** notification matrix; missing emails (welcome, info split, status copy review); dedup guard; preference granularity + i18n; footer manage link.
**In scope (7.2):** channel strategy matrix + founder sign-off; opt-in UX; WhatsApp wiring for high-urgency kinds (behind Messaging::*); delivery router refactor; web-push evaluation.

**Out of scope:** actual SMS implementation; mobile-native push (iOS/Android apps); ActionCable real-time unless scoped as stretch; redesigning the in-app notification feed UI (separate).

## Risks

- **Channel sprawl** — the matrix must be enforced by the router; every new kind goes through the same decision point.
- **WhatsApp cost/compliance** — opt-in + verified phone only; transactional templates require provider approval; keep vendor isolation so switching providers is cheap.
- **Email fatigue** — prefer digest for low-urgency; review email volume after launch.
- **Welcome email timing** — coordinate with verification email to avoid double-email at signup (send welcome after verification).
