# Notification Matrix — Audit & Channel Strategy

**Status:** Draft v1 — pending founder sign-off (see [Decisions](#decisions))
**Owner:** Product (authored by Domain per plan 32)
**Source:** `specs/32_notifications_review_plan.md`
**Generated:** 2026-08-09

This matrix is the executable output of plan 32 (Items 7.1–7.2). It records, for every declared
notification kind: who is notified, whether the event is triggered in production code today,
what email (if any) is delivered, the recommended timing, per-kind control, and a
**wire / defer / remove** decision. It also fixes the per-event channel strategy.

---

## 1. Per-kind audit (7.1)

Legend — **Triggered today:** has a real production call site that calls `Notifications::Deliver`.
**Email today:** a mailer is actually dispatched for this kind. **Decision:** wire (build now),
defer (follow-up ticket), or remove (dead kind, delete from the enum).

| # | Kind | Recipients | Triggered today? | Email today | Decision | Notes |
|---|------|-----------|------------------|-------------|----------|-------|
| 1 | `request_submitted` | adopter (confirmation); shelter staff / publisher (new request) | ✅ | ✅ adopter → `request_confirmation`; others → `new_request_notification` | **Wire (keep)** | Core flow; no change to semantics. |
| 2 | `request_in_validation` | adopter | ✅ (via `ProcessRequest`) | ✅ `status_changed` | **Wire (keep)** | Body copy reviewed; distinct subject per status. |
| 3 | `request_accepted` | adopter | ✅ (via `ProcessRequest`) | ✅ `status_changed` | **Wire (keep)** | High-urgency; WhatsApp candidate. |
| 4 | `request_declined` | adopter | ✅ (via `ProcessRequest` / `DeclineRequest`) | ✅ `status_changed` (renders decline reasons) | **Wire (keep)** | Sensitive; copy reviewed. |
| 5 | `request_withdrawn` | shelter staff / publisher | ✅ (via `WithdrawRequest`) | ✅ `request_withdrawn` | **Wire (keep)** | |
| 6 | `info_requested` | adopter | ❌ no call sites | ❌ (dead branch routed to `status_changed`) | **Defer** | The live `AdoptionRequest` flow has no "request info" action (concept only in legacy `app/domains/adoptions/*`). Follow-up: build the feature in the live flow and wire a dedicated mailer, or remove the kind. See [Follow-ups](#follow-ups). |
| 7 | `info_received` | shelter staff / publisher | ❌ no call sites | ❌ (dead branch routed to `status_changed`) | **Defer** | Same as `info_requested`. |
| 8 | `message_received` | conversation participant | ❌ no call sites | ❌ (log only) | **Defer** | Gated on messaging Phase 2 (`Messaging::*` trigger). When wired, prefer in-app + optional digest, not per-message email. |
| 9 | `pet_status_changed` | saved-pet owners / watchers | ❌ no call sites | ❌ (log only) | **Defer** | Needs saved-pet activity wiring from `Pets::ChangeStatus`. Follow-up ticket. |
| 10 | `welcome` | new user | ❌ no call sites (was dead) | ❌ (log only) | **Wire** ✅ | Trigger added after email verification (`Authentication::VerifyEmail`); email via `AuthenticationMailer#welcome` — avoids double-email at signup. |

**Deliverables locked by this audit:**
- Every kind now has a recorded decision (AC-7.1-2).
- `welcome` gained a real trigger + email (AC-7.1-3, close the obvious gap).
- `info_requested`/`info_received` are no longer routed to the generic `status_changed` mailer
  (dead branch removed); distinct mailers will be added when the kinds are triggered (AC-7.1-3).
- The `message_received` / `pet_status_changed` email stubs are removed; routing is now
  table-driven through `Notifications::EmailRouting` and deferred kinds simply have no route
  (AC-7.2-8).

---

## 2. Triggered-today verification (call-site audit)

| Kind | Production call site | File |
|------|---------------------|------|
| `request_submitted` (adopter) | `SubmitRequest#deliver_notifications` | `lib/adoptions/submit_request.rb` |
| `request_submitted` (staff/publisher) | `SubmitRequest#deliver_notifications` | `lib/adoptions/submit_request.rb` |
| `request_in_validation` / `request_accepted` / `request_declined` | `ProcessRequest#deliver_notifications` | `lib/adoptions/process_request.rb` |
| `request_withdrawn` | `WithdrawRequest#notify_responsible_party` | `lib/adoptions/withdraw_request.rb` |
| `welcome` | `VerifyEmail` (new) | `lib/authentication/verify_email.rb` |

---

## 3. Email behavior (current vs. recommended)

| Kind | Current subject/body | Recommendation |
|------|---------------------|----------------|
| `request_submitted` (adopter) | "Request to adopt X — Confirmation" | Keep. Confirm no duplicate email per (recipient, event) — enforced by dedup guard in `Notifications::Deliver`. |
| `request_submitted` (staff) | "New adoption request for X" | Keep. |
| `status_changed` | "Update on your request to adopt X" (per-status body) | Keep; per-status subjects already distinct. Locale bug fixed (`set_locale`). `AdoptionRequest#decline_reasons` now exposes decline reasons from timeline-event metadata (was undefined — declined emails crashed in the background job; plan 32 problem 11). |
| `request_withdrawn` | "X withdrew their request for Y" | Keep. |
| `welcome` | *(new)* | Send after verification. Coordinate with `verification` email to avoid double-email at signup. |
| `info_requested` / `info_received` | *(deferred)* | Distinct mailers with clear subjects when wired. |
| `message_received` | — | Digest (weekly) or none; never per-message email. |

**Timing:** all emails fire immediately via `deliver_later`. No batching/digest in MVP; digest is
deferred (see [Channel strategy](#5-channel-strategy-by-event)).

---

## 4. User control (AC-7.1-5)

- Model supports `per_kind_overrides` (JSON) already.
- UI now exposes **per-kind email toggles** for the 6 kinds that can be triggered today
  (`request_submitted`, `request_in_validation`, `request_accepted`, `request_declined`,
  `request_withdrawn`, `welcome`), under "Customize by notification type".
- **Precedence (fixed):** global OFF **wins** over any per-kind override. A stale override can no
  longer resurrect email after the user disables the global toggle.
- Deferred kinds (`message_received`, `pet_status_changed`, `info_*`) are intentionally not shown
  in the UI yet — they are not triggerable, so toggles would be dead controls.

---

## 5. Channel strategy by event (7.2)

Principles (from plan 32): urgency decides channel; interruptive channels are opt-in only; no
event on every channel; digest for low urgency; web push evaluated before mobile push; SMS
deferred.

| Event kind | Urgency | Recommended channels | Status |
|------------|---------|----------------------|--------|
| `request_submitted` (to shelter/publisher) | High | In-app + Email (+ WhatsApp when provider lands, shelter staff) | In-app + Email live |
| `request_submitted` (confirmation to adopter) | Routine | In-app + Email | Live |
| `request_accepted` | High | In-app + Email + WhatsApp (adopter) | In-app + Email live; WhatsApp gated |
| `request_declined` | High | In-app + Email (+ WhatsApp) — sensitive copy | In-app + Email live |
| `request_in_validation` | Routine | In-app + Email | Live |
| `request_withdrawn` | Routine | In-app + Email | Live |
| `info_requested` / `info_received` | Medium | In-app + Email | Deferred (feature not built) |
| `message_received` | Medium | In-app (+ weekly email digest optional) | Deferred (messaging Phase 2) |
| `pet_status_changed` | Medium | In-app + Email | Deferred (saved-pet wiring) |
| `welcome` / onboarding | Routine | Email (welcome), in-app nudge | Email live after verification |
| Re-engagement (saved pets, in-review reminders) | Low/Medium | In-app + optional weekly digest | Deferred (follow-up) |

### Channel status

| Channel | Status today | Decision |
|---------|--------------|----------|
| In-app | ✅ Live (record + bell + index) | Keep. The `in_app` preference is now honored: when in-app is disabled for a kind, no `Notification` record is created (no feed entry, no badge count); other enabled channels still deliver. Trade-off: email-only delivery for in-app-off users has no record anchor (no dedup/tracking) — upstream event guards prevent duplicate sends. |
| Email | ✅ Live (complete for wired kinds) | Keep; delivery tracking added (AC-7.1-8). Routed mailers carry an `X-Tovitu-Notification-Id` header; `Notifications::DeliveryTracker` subscribes to `deliver.action_mailer` and writes the real outcome (`email_delivered_at` / `email_failed_at` + error) back onto the record — job-time render/delivery failures are no longer silent. |
| WhatsApp | 🔧 Stub | **Deferred** — no provider yet. Wiring lands behind `Messaging::*` when the WhatsApp Business API provider is available (AC-7.2-3). Opt-in + verified phone UX already exists (AC-7.2-2). |
| Web push (PWA) | ❌ Not present | **Evaluated: defer build.** PWA service worker exists (`app/views/pwa`) so web push is feasible, but it is a stretch goal — no-build for MVP, revisit post-launch (AC-7.2-6). |
| SMS | ❌ Not present | **Deferred** — high cost, low differentiation at MVP (AC-7.2-7). |
| Browser notifications | ❌ Not present | Same as web push (PWA) — defer. |

### Digest (AC-7.2-4)

**Decision: defer.** A weekly aggregate digest for `message_received` / saved-pet activity needs
scheduling infrastructure (cron/recurring Sidekiq job) that does not exist yet. Recorded as a
follow-up ticket; low-urgency events use in-app only until then.

---

## 6. Proposed new kinds (beyond the 10)

| Proposed kind | Event | Priority | Recommended channel |
|---------------|-------|----------|---------------------|
| `hold_expiry` | Hold about to expire (`hold_expires_at` + `ExpireHold`) | High (adoption integrity) | In-app + Email (+ WhatsApp if opted in) |
| `pet_published` | A saved pet becomes available/published | Medium | In-app + Email |
| `saved_pet_activity` | Status change on a saved pet | Medium | In-app (+ weekly digest) |
| `profile_completion_nudge` | Onboarding incomplete for N days | Low | In-app + Email |
| `in_review_reminder` | Request stuck in review for N days | Low/Medium | In-app + Email |

None of these are implemented. They are candidates for the next planning round and must register
in `Notifications::EmailRouting` (single mapping) when built.

---

## 7. Decisions

| # | Decision | Who signs |
|---|----------|-----------|
| D1 | `welcome` wired: trigger after email verification, `AuthenticationMailer#welcome`. | Domain (done) |
| D2 | `message_received` deferred to messaging Phase 2. | Product |
| D3 | `pet_status_changed` deferred; follow-up ticket for saved-pet wiring. | Product |
| D4 | `info_requested`/`info_received` deferred; build "request info" in live flow or remove kinds. | Product |
| D5 | Digest deferred; needs scheduling infrastructure. | Product |
| D6 | Web push: no-build for MVP (PWA feasible later). | Product |
| D7 | SMS deferred. | Product |
| D8 | WhatsApp wiring gated on provider availability, behind `Messaging::*`. | Product/Eng |
| D9 | Preference precedence: global OFF wins over per-kind overrides (tested). | Domain (done) |
| D10 | Per-kind email toggles in preferences UI (6 triggerable kinds). | Product |
| D11 | `in_app` preference honored: no record created for kinds with in-app disabled. | Domain (done) |
| D12 | Delivery write-back: `Notifications::DeliveryTracker` records real send outcome on the `Notification`. | Domain (done) |
| D13 | Dead `lib/adoptions/notify_*` services removed (duplicated `Deliver`, zero call sites). | Domain (done) |

## 8. Follow-ups

- [ ] Build "request info / info received" into the live `AdoptionRequest` flow and wire dedicated
      mailers (or remove kinds `info_requested`/`info_received`).
- [ ] Wire `pet_status_changed` from `Pets::ChangeStatus` → saved-pet owners.
- [ ] Wire `message_received` when messaging Phase 2 lands.
- [ ] Weekly low-urgency digest (needs scheduling infra).
- [ ] WhatsApp delivery via `Messaging::WhatsAppProvider` for high-urgency kinds.
- [ ] Web push via PWA service worker (post-launch).
- [ ] Cleanup of legacy `app/domains/adoptions/*` layer (tracks separately; notifications must
      target the canonical `lib/adoptions/*` + `AdoptionRequest` flow).
