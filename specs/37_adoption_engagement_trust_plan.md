# Plan: Adoption Engagement & Trust (REQ-12, REQ-13, REQ-14)

**Domain:** Dashboard, Navigation, Pet Profile, Trust & Safety
**Priority:** 2 (Medium)
**Status:** Draft
**Tracks:** Epics "Adoption Journey" (REQ-12, REQ-13) + "Perfil de mascota" (REQ-14)

---

## Overview

Three medium-priority improvements strengthen the emotional core of Tovitu — **accompaniment and trust**:

1. The **"Viaje de Adopción" (Adoption Journey) card** on the dashboard is not yet as visible or actionable as it should be: it should explain what the journey is, show what the user has achieved, name the next steps, and motivate continuation — without tipping into excessive gamification.
2. The **"Solicitudes entrantes"** navigation item confuses individual users, who read it as "people will send me requests" instead of "requests **I** receive when I give a pet up for adoption."
3. The **pet profile** lacks a shelter-authored recommendation ("Esto nos dice el refugio sobre Luna"), a high-trust signal that must be safely validated before display.

These were grouped because they share a medium priority and a common thread: helping users feel guided and informed at every step.

---

## Current State (confirmed in code)

- **Adoption Journey card:** The dashboard already renders an "Adoption Journey" card (from plan 31: readiness percentage, segmented stage indicator, milestone list, next-step line, milestone toasts). It reads as a status widget; it does not yet explain the journey, celebrate progress warmly, or drive a concrete next action in a way that reads as "Tovitu accompanies me."
- **"Incoming Requests":** the sidebar/navigation uses the "Solicitudes entrantes / Incoming Requests" label for individual users who publish a pet — the same vocabulary used for shelter staff. Individual adopters see this item and can misunderstand it (locale keys confirmed: `incoming_requests` present in both languages).
- **Pet profile:** the profile shows pet data + AI Life Preview content. There is no section for shelter-authored, human recommendation text ("Esto nos dice el refugio sobre…").

---

## User Stories

> As an adopter,
> I want my dashboard to tell me where I am in my adoption journey, what I've accomplished, and exactly what to do next,
> so that I feel accompanied and motivated — not lost.

> As an individual who is giving a pet up for adoption,
> I want the navigation to clearly say this area is about requests I receive for my pet,
> so that I don't confuse my role with that of an adopter or a shelter.

> As an adopter considering a pet,
> I want to read what the shelter itself says about why this pet could be right for me,
> so that I trust the match beyond the AI's words.

---

## Requirements & Proposed Behavior

### REQ-12 — Improve the "Adoption Journey" card

Make the card more visible and actionable:

1. The card incorporates a **Tovitu-related background** (brand color field / pattern per DESIGN.md) that raises visibility without hurting legibility.
2. It **explains briefly** what the Adoption Journey is (one accessible sentence).
3. It shows **what the user has achieved** (milestones reached).
4. It names **what's next** (concrete next step).
5. It has **at least one clear CTA** (e.g., "Complete your profile", "Browse pets", "See your request").
6. Content **adapts to the user's current state** (fresh user vs. profile complete vs. active applications).
7. The design **avoids excessive gamification**: no points, levels, or leaderboard mechanics; progress is personal and warm.
8. The experience reinforces **Tovitu accompanies the user** through the process.

**Edge cases:**
- Fresh user with nothing done → explain journey + first step CTA.
- Mid-journey user (saved pets, no application) → celebrate progress, next step CTA.
- Active-applicant user → show application status context + next step ("awaiting shelter response").
- User who is also publishing a pet → journey content should not conflict with the giving-up-adoption role; primary CTA stays relevant.
- Reduced-motion → no animated background flourishes; static brand treatment.
- Mobile → card must not blow up the dashboard layout.

### REQ-13 — Clarify "Incoming Requests" for individual users

The section's name and navigation must communicate its true purpose:

1. The section name clearly communicates its purpose (requests received from people who want the pet the user is giving up).
2. It's clear the section is for users **giving a pet up for adoption**.
3. Navigation differentiates the **adopter role** from the **giver role**.
4. Simple, comprehensible language.
5. Tovitu must **not assume an individual user is automatically a shelter**.
6. Terminology stays consistent across the app (sidebar, empty states, notifications, dashboard).

**Proposed direction (to confirm with founder in the discovery call):** rename to something like "Requests for your pets" / "Adoption requests you receive" for individual publishers, or route the item so it only appears when the user has published a pet, with a clear helper when it's not applicable. The key AC is that an individual adopter can no longer read the item as "requests sent to me as an adopter."

**Edge cases:**
- Individual user who has never published a pet → item either hidden or shown with an explanatory empty state ("When you give a pet up for adoption, requests from adopters appear here").
- User with both roles (adopter + giver) → both areas clearly labeled by role.
- Shelter staff → keep shelter vocabulary (their role genuinely receives requests as an organization).
- Notifications/emails referencing "incoming requests" → update wording consistently.

### REQ-14 — Shelter recommendation on the pet profile

Add a profile section where the shelter explains why the pet may suit the adopter:

1. Shelters/publishers can provide a recommendation/description for a pet.
2. The content appears inside the pet profile ("Esto nos dice el refugio sobre Luna").
3. If the shelter provides nothing, the section **does not render**.
4. Content is associated only with the corresponding pet.
5. Content is **validated before display**:
   - Protection against malicious content.
   - Protection against inappropriate content.
   - No HTML/JavaScript or other executable content injection.
6. The UI clearly **differentiates shelter-authored content** from Tovitu's AI-generated content (labeling + visual treatment).
7. The content builds trust and knowledge, aligned with Tovitu's transparency principle.

**Edge cases:**
- Shelter submits HTML/script → stripped/sanitized, rendered as plain text; nothing executes.
- Shelter submits profanity/inappropriate content → blocked or flagged; shelter sees a friendly validation error.
- Empty/whitespace-only recommendation → treated as "not provided"; section hidden.
- Very long recommendations → bounded length with friendly limit; truncation where needed.
- Recommendation edited after publishing → updates immediately on the profile; stale cache avoided.
- Individual publisher (giving up a pet) → same capability as shelters (they are the "shelter" voice for that pet).

---

## Acceptance Criteria

- **AC-37-1 (REQ-12)** — The journey card includes a Tovitu-related background that improves visibility without hurting legibility (contrast-checked).
- **AC-37-2 (REQ-12)** — The card explains in one brief sentence what the Adoption Journey is.
- **AC-37-3 (REQ-12)** — The card shows achieved milestones.
- **AC-37-4 (REQ-12)** — The card names the next step.
- **AC-37-5 (REQ-12)** — The card has at least one clear CTA.
- **AC-37-6 (REQ-12)** — Card content adapts to user state (fresh / mid-journey / active applicant).
- **AC-37-7 (REQ-12)** — No points/levels/leaderboards introduced; progress remains personal (no excessive gamification).
- **AC-37-8 (REQ-12)** — The experience communicates accompaniment ("Tovitu está contigo en cada paso") without being cloying.
- **AC-37-9 (REQ-13)** — The "incoming requests" section name clearly communicates its purpose for individual users.
- **AC-37-10 (REQ-13)** — An individual adopter cannot mistake the section for something that applies to adopters; role differentiation is explicit.
- **AC-37-11 (REQ-13)** — Terminology is consistent across sidebar, empty states, notifications, and dashboard.
- **AC-37-12 (REQ-13)** — The app does not assume an individual user is automatically a shelter.
- **AC-37-13 (REQ-14)** — Shelters/publishers can provide a recommendation for a pet.
- **AC-37-14 (REQ-14)** — The recommendation renders on the pet profile with a clear "shelter says" framing.
- **AC-37-15 (REQ-14)** — When no recommendation is provided, the section does not render.
- **AC-37-16 (REQ-14)** — Content is pet-scoped (only on the pet it belongs to).
- **AC-37-17 (REQ-14)** — Malicious/inappropriate content is blocked; HTML/JS injection is impossible (sanitization verified by test).
- **AC-37-18 (REQ-14)** — Shelter-authored content is visually differentiated from Tovitu AI content.
- **AC-37-19** — All new strings localized (en/es); WCAG AA; keyboard accessible.

---

## Success Metrics

- **Journey card engagement**: click-through on the journey CTA (target: majority of dashboard sessions among users with an incomplete next step).
- **Role clarity**: reduction in "what are incoming requests?" support/feedback; sign-up-to-publish conversion for individual givers does not regress.
- **Profile trust**: engagement with the shelter-recommendation section (scroll/read time, save/apply rate among users who read it) and no increase in "is this AI?" confusion (founder/design review of labeling).
- **Safety**: zero reported incidents of injected/malicious shelter content.

---

## Test Strategy

- **View/request specs**: journey card variants per user state; navigation label variants per role; profile section render/no-render; sanitization of malicious payloads (script tags, event handlers, iframes).
- **Security specs**: XSS attempts in shelter recommendation are neutralized (plain-text output verified).
- **Manual QA**: full journey card states in both locales; individual giver flow (publish → see renamed section → receive request); shelter recommendation authoring + display.
- **i18n check**: en/es parity for all new strings.

---

## Scope

**In scope:** journey card upgrade (background, explanation, achievements, next steps, CTA, state-adaptive); renaming/clarifying the incoming-requests navigation + all related copy for individual users; shelter recommendation field + validated profile display (sanitization, appropriateness checks, clear labeling).

**Out of scope:** New gamification mechanics (points/badges/leaderboards — explicitly excluded per plan 31); a full dashboard redesign; moderation dashboard/workflow for content review (MVP uses automated validation); messaging between shelter and adopter.

---

## Risks

- **Gamification creep** — the journey card can drift into game mechanics; mitigation: explicit "no points/levels/leaderboards" gate (inherited from plan 31) and founder review.
- **Naming churn** — renaming a navigation item touches many views/locales/notifications; mitigation: consistent key reuse and a single terminology source (locale keys), reviewed by founder.
- **Content moderation** — automated validation can over-block legitimate content or miss edge cases; mitigation: layered validation (format + sanitization + appropriateness heuristics) and clear shelter-facing error messaging; manual review can be added later.
- **Labeling confusion** — users must distinguish shelter text from AI text; mitigation: explicit framing ("Esto nos dice el refugio…") + distinct visual treatment + founder review.

---

## Dependencies

- **Depends on plan 33** (localization) for all new copy.
- **Depends on plan 35** (favorites) — the journey card references saved pets; plan 35 completes the save interaction it builds on (REQ-07/08).
- **Depends on plan 36** (discovery) for species-aware content that may appear in profiles.
- **Precedes** plan 39 (polish) — any layout fixes triggered by these additions (e.g., card overflow) should be rolled into polish only if unrelated; otherwise fixed here.