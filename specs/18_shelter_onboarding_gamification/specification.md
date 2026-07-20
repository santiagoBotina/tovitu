# Specification: Shelter Onboarding Gamification

**Domain:** Shelters, Onboarding
**Priority:** 2 (Enhancement)
**Status:** Approved

---

## Overview

Transform the procedural shelter onboarding into a playful, game-like journey aligned with the "Playground Standard" brand direction. The experience spans three phases: Onboarding Wizard → Shelter Registration → Dashboard Checklist.

---

## Goals

1. Reduce abandonment during the 7-question wizard
2. Make the 6-step dashboard checklist feel rewarding
3. Create emotional momentum: sign-up → onboarding → shelter creation → first pet → live
4. Reinforce Tovitu brand as playful, bold, and friendly
5. Leverage existing animation infrastructure (CSS, Stimulus, Hotwire)

---

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| No new DB columns | All gamification cosmetic | Level from step count, personality from profile, celebration state in Stimulus session |
| No new gems | DOM-generated confetti | Keeps bundle tiny, no canvas/WebGL dependency |
| Turbo Stream for checklist | Convert relevant actions to respond with Turbo Streams | Seamless partial replacement without full page loads |
| Stimulus dispatch events | Cross-controller communication via `dispatch()` | Avoids coupled controller hierarchies |
| SVG mascot inline | Inline SVG in partial | Zero-latency, color-themeable, ~1KB |
| Level state in DOM | Server-computed in presenter, rendered as data attribute | SSR and Turbo compatible |

---

## Key Behaviors

### Personality Determination

Based on onboarding answers, a personality badge is computed client-side or server-side:

| Personality | Derived From |
|-------------|-------------|
| Compassionate Guardian | Q3: extensive_matching AND Q4: long_term_commitment |
| Heart-Led Rescuer | Q1: small_rescue AND Q3: basic_screening |
| Process Pro | Q1: large_shelter AND Q6: managing_applications |
| Community Builder | Q5: foster_based AND Q5: whatsapp |
| Growth Partner | Q1: ngo_foundation AND Q3: long_term_support |

Fallback: The Compassionate Guardian (default when no strong match).

### Level System

| Level | Title | Steps Done | Badge Color |
|-------|-------|------------|-------------|
| 1 | New Recruit | 0 | Bronze |
| 2 | Getting Ready | 1-2 | Silver |
| 3 | Almost There | 3-4 | Gold |
| 4 | Ready to Rescue | 5 | Purple |
| 5 | Live & Active | 6 | Teal (animated) |

### Event Bus

| Event | Source | Target |
|-------|--------|--------|
| `question:completed` | `single_select` / `multi_select` | `shelter_onboarding` |
| `milestone:reached` | `shelter_onboarding` | self |
| `wizard:complete` | `shelter_onboarding` | `confetti` |
| `checklist:item-done` | Turbo Stream response | `checklist` |
| `checklist:level-up` | `checklist` | `confetti` |

---

## CSS Animation Library

New keyframes: `confetti-fall`, `check-burst`, `mascot-bounce`, `level-up-glow`, `diamond-pulse`, `card-complete-slide`.

New utility classes: `.confetti-container`, `.confetti-piece`, `.check-burst`, `.mascot-bounce`, `.level-up-glow`, `.diamond-pulse`, `.card-complete`.

All animations gated behind `@media (prefers-reduced-motion: reduce)`.

---

## Stimulus Controllers

### `confetti_controller.js`
- Creates 25 confetti pieces in Tovitu palette colors
- Pieces fall with randomized x-offset, rotation, delay
- Auto-cleanup after 2.5s
- One-shot, fire-and-forget

### `checklist_controller.js`
- Connects to dashboard checklist container
- Watches Turbo Stream updates for newly-completed items
- Triggers checkmark burst + progress bar pulse
- Calculates level and fires level-up celebration
- Manages encouragement tip rotation

### `shelter_onboarding_controller.js` (extends `onboarding_controller`)
- Adds mascot reaction triggers
- Manages milestone celebrations at 25/50/75/100%
- Builds personality result card
- Fires confetti on completion

### Enhanced `single_select` / `multi_select`
- Brief scale pulse on selected chip/card
- Dispatch `question:completed` event
- Trigger mascot reaction

---

## Turbo Stream Protocol

Each checklist action (add pet, update policies, invite staff, etc.) must return a Turbo Stream that:
1. Replaces the checklist partial (`#onboarding-checklist`)
2. Replaces the progress bar (`#progress-bar`)
3. Appends a flash message (`#flash-container`)
4. Dispatches `checklist:item-done` event

---

## Edge Cases

| Scenario | Handling |
|----------|----------|
| prefers-reduced-motion | All animations disabled, confetti hidden, mascot static |
| Wizard skipped | No personality card, redirect straight to registration |
| Turbo disabled | Fallback to static checklist, no animations |
| Level drops (item undone) | Level recalculates; celebration only plays once per level |
| Confetti on slow devices | Max 30 pieces, auto-removes after 3s |
| Mobile | 15 confetti pieces; mascot hidden on < 360px |
