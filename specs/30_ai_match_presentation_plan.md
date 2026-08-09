# Plan: AI Adoption-Match Presentation Redesign (Item 4.1)

**Domain:** Frontend, AI, Adoption Requests
**Priority:** 1 (High)
**Status:** Draft
**Tracks:** Product Improvements §4 (AI & Adoption Matching)

---

## Overview

When an adoption request is received, Tovitu displays an AI-generated matching result (the **Adopter Insight card**, `app/views/adoption_requests/_adopter_insight_card.html.erb`, shared between shelter and individual-publisher request review pages). The information is valuable, but the current presentation is **text-dense and hard to scan**: multiple labeled blocks (archetype, fit indicators, commitment signals, summary, verification questions, provenance footer) each with paragraph-length copy.

This plan redesigns the AI match presentation to be **more visual, scannable, and aligned with the Tovitu visual identity** — fewer words, icon-driven attributes, clear sections/cards, and subtle motion when the match is generated/displayed. **No AI logic changes**; the underlying data (presenter fields) stays the same. This is a presentation-layer refactor.

---

## Current State (confirmed in code)

`app/views/adoption_requests/_adopter_insight_card.html.erb` (rendered on `adoption_requests/show` and shelter/individual-publisher review pages) currently renders, top to bottom:

1. **Header**: sparkle icon + "Adopter Insight" title + "AI" badge.
2. **Archetype block** (`bg-primary-50`): archetype label + big archetype name; optional stale badge; optional "self-report vs. behavior" divergence block.
3. **Fit indicators** (`fit_title` → 2-col grid of boxes, each with label + status chip + **evidence sentence**).
4. **Commitment signals** (`commitment_title` → bullet list of observations with colored dots).
5. **Pet-fit summary** (`bg-secondary-50`): heading + **summary paragraph**.
6. **Verification questions** (`verify_title` → list of question items with info icons).
7. **Provenance footer**: confidence chip, "activity up to" date, "based on" line, disclaimer.

Supporting types: `AdopterInsightPresenter` (fields: `archetype_label`, `fit_indicators` (label/status/status_label/evidence), `commitment_signals` (kind/observation), `summary`, `verification_questions`, `confidence_label`, `based_on`, `disclaimer`, `self_report_label`, `pet_fit_stale?`, `diverges?`).

**Identified density problems:**
- Long evidence sentences under each fit indicator (line 57).
- Commitment signals as long observations (line 75).
- Summary paragraph can run 3–4 lines (line 86).
- Verification questions as full sentences (line 100).
- No icons or visual anchors for attributes — everything is text.

---

## User Stories

> As a shelter staff member reviewing a request,
> I want the AI match result to be visual and scannable — icons, status, and highlights instead of walls of text,
> so that I can quickly see the important factors and make a faster, better-informed decision.

> As an individual publisher reviewing a request for my pet,
> I want the same clear, friendly AI match presentation,
> so that the recommendation feels trustworthy and easy to understand.

---

## Proposed Redesign

### 1. Information architecture (visual sections/cards)

Restructure the card into **4 visual zones** (instead of 7 stacked text blocks):

1. **Archetype hero strip** — keep, but make it a full-width tinted card with: archetype name (display font), a **large icon/emoji-free glyph** representing the archetype (map archetype → icon from a small icon set, or a pet/compass glyph), and the confidence chip moved here (prominent, not buried in footer). Stale badge stays. Self-report divergence becomes a compact "worth confirming" pill rather than a paragraph.
2. **Compatibility radar / factor chips** — the fit indicators become **visual factor rows**: each factor = icon + short label + status pill (Strong fit / Possible mismatch / Neutral) with the evidence **truncated to a single short line** (or shown on hover/expand — see below). Two-column grid retained but each cell is icon-led and compact.
3. **What to watch / commitment signals** — convert the bullet list into **icon-coded signal rows** (thumbs-up/attention glyph per `kind`), each observation trimmed to ≤ ~12 words with a title-case short phrase. If a signal has no short form available from the presenter, apply a "labelize" transform (first sentence, truncated) — presentation only.
4. **Suggested check-ins** — verification questions become a **numbered "Ask them" checklist** with checkboxes (non-interactive display or lightweight toggle for the reviewer to track as they verify — decide at implementation; default: static checkmarks with subtle stagger animation).

### 2. Text reduction rules (product rule)

- **Evidence**: show at most one short line (~90–120 chars) per fit indicator; full evidence available via `title` attribute or an expand affordance ("Why?" toggle) — default collapsed.
- **Summary**: keep but cap at 2–3 lines with `line-clamp-3` + "Read more" expander (respects existing `truncate` patterns).
- **Verification questions**: keep full text (they're actionable) but render as compact checklist rows, not paragraphs.
- **Provenance footer**: keep the disclaimer and "based on" but **collapse to one subtle line** with an info tooltip (`title`) instead of three stacked lines; confidence moved to hero.

### 3. Icons & visual anchors

- Add an **icon per fit factor** — derive from a fixed icon map keyed by factor label (e.g., "Lifestyle" → home icon, "Family" → users icon, "Experience" → paw icon, "Timing" → clock icon; fallback to a generic circle-check). Icons follow existing Lucide-style stroke SVGs used throughout the app (`w-4 h-4`, stroke-width 2, `currentColor`).
- Archetype icon: map archetype labels to a small set (heart/star/compass/shield) with graceful fallback.
- Status chips: reuse existing chip styles (`bg-secondary-50 text-secondary-700` strong fit; `bg-warning/10 text-warning` mismatch; `bg-neutral-100` neutral) — already in the codebase.

### 4. Motion (subtle, respects reduced-motion)

- **Reveal on generation**: when the card transitions from `loading?` → `ready?`, animate sections in with the existing `bento-enter`/stagger utility pattern already used across the app (`bento-enter-d1..d5`), plus a light `fade-in-up` on the archetype hero.
- **Hover micro-interactions**: factor cells lift (`card-lift` pattern exists) with a 150–200ms transition.
- **"Why?" expand** animates height/content (CSS `transition` + max-height or `<details>`-based) — keep dependency-free, no new animation library.
- All motion gated behind `@media (prefers-reduced-motion: reduce)` (existing convention).
- **No new permanent animations** — no confetti, no pulsing beyond what exists.

### 5. Shared component

Keep the card **shared** between shelter and individual-publisher review pages (as today) — the redesign lives in `_adopter_insight_card.html.erb` + its partials. If the card grows, extract sub-partials (`_archetype_hero.html.erb`, `_fit_factors.html.erb`, `_signals.html.erb`, `_checkins.html.erb`) under `app/views/adoption_requests/`.

### 6. i18n

All new UI copy (section titles, expand labels, tooltips, aria labels) in `config/locales/{en,es}.yml` under `ai.adopter_insight.card.*`. Reuse existing keys where possible.

---

## Acceptance Criteria (4.1)

- **AC-4.1-1** The adopter insight card renders the four visual zones (archetype hero, fit factors, signals, check-ins) instead of the current stacked text blocks.
- **AC-4.1-2** Each fit factor shows an icon, short label, status pill, and at most one line of evidence (default); full evidence available via an explicit "Why?" affordance.
- **AC-4.1-3** Confidence is displayed prominently in the archetype hero; the provenance footer is reduced to a single subtle line with an info tooltip.
- **AC-4.1-4** Verification questions render as a compact checklist (static or reviewer-trackable) rather than paragraphs.
- **AC-4.1-5** The card still renders all three states (ready / loading / unavailable) with no functional regression; loading → ready transition uses staggered, subtle motion that is disabled under `prefers-reduced-motion`.
- **AC-4.1-6** No AI logic or presenter data model changes — the redesign uses the existing presenter fields (verified by tests/PR review).
- **AC-4.1-7** The card remains shared between shelter and individual-publisher review pages with identical visual treatment.
- **AC-4.1-8** All new strings are i18n'd (en/es); no hardcoded user-facing text.
- **AC-4.1-9** WCAG AA: contrast on all new chips/icons; keyboard accessible expand/tooltip; focus rings visible.
- **AC-4.1-10** No regression to surrounding request page layout (timeline, next steps, additional info) at mobile/desktop widths.

---

## Success Metrics

- **Scanability**: shelter staff can identify the top match factors in a quick glance (manual QA + founder/design review of a screenshot pass).
- **Qualitative feedback**: design review approval that the card matches the Playground Standard (bold, playful, scannable).
- **No regression**: existing request-review specs still pass; card renders for both roles.
- **Engagement proxy**: time-on-card or interaction with "Why?" expanders (if measurable) shows the info is accessible, not hidden.

## Test Strategy

- **View/system specs**: card renders all four zones with real presenter data; loading and unavailable states unchanged; reduced-motion disables reveal animations (CSS check or no-JS fallback).
- **Manual QA**: shelter + individual publisher review a request with a full insight; check icon mapping, truncated evidence + expand, checklist rendering, mobile layout.
- **A11y pass**: keyboard navigation through expanders/checkboxes, tooltips announced, contrast checks.

## Scope

**In scope:** presentation-layer redesign of the adopter insight card (zones, icons, truncation/expand, motion, i18n, shared sub-partials).

**Out of scope:** changing the AI generation pipeline or prompt output; changing presenter data model/fields; adding new AI features (e.g., alternative matches, comparison views); the underlying insight generation jobs (plan 25 scope).

## Risks

- **Truncating evidence** could hide important nuance — the "Why?" affordance must be obvious and keyboard-accessible; default collapsed keeps the card clean.
- **Icon mapping** for arbitrary factor labels may miss — implement a fallback icon + a documented map that the AI/Domain agent can extend as labels evolve.
- **Motion scope creep** — restrict to existing utility patterns; no new libraries; reduced-motion respected.
- **Shared partial growth** — keep sub-partials small and presenter-driven to avoid duplication between shelter and individual views.
