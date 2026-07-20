# Plan: Shelter Onboarding Gamification

**Domain:** Shelters, Onboarding
**Priority:** 2 (enhancement to existing shelter flow)
**Status:** Draft

---

## Overview

The current shelter onboarding works but feels procedural — a linear Q&A flow followed by a static dashboard checklist. This plan transforms the entire experience into a **playful, game-like journey** that aligns with the "Playground Standard" design direction.

**Goals:**
- Reduce abandonment during the 7-question wizard (currently purely functional)
- Make the 6-step dashboard checklist feel rewarding, not like chores
- Create emotional momentum from sign-up → onboarding → shelter creation → first pet → live
- Reinforce the Tovitu brand as playful, bold, and friendly
- Leverage existing animation infrastructure (CSS keyframes, Stimulus, Hotwire)

---

## Current State

### Phase 1: Onboarding Wizard (7 Questions)
- Linear question-by-question flow with next/back buttons
- Progress bar fills incrementally
- Questions transition with `opacity-0 translate-x-4` (simple fade-slide)
- A pet-paw emoji (`🐾`) "pop" animation appears on option select
- Completion redirects to `/shelters/new` with a plain flash notice

### Phase 2: Shelter Registration (Post-Wizard)
- Standard form (name, address, phone, etc.)
- No connection back to the onboarding wizard — feels like a separate app

### Phase 3: Dashboard Checklist (6 Steps)
- Static list: add pet, policies, staff, hours, profile, publish
- Checkmarks for completed items with `line-through` text
- Progress bar showing percentage
- No animations, no rewards, no celebration when items complete

---

## Proposed Experience

The journey should feel like **leveling up a shelter in a game**:

```
🏠 Welcome!           → Complete your shelter profile  (Level 1: New Recruit)
📋 Tell us about you  → Answer 7 playful questions     (Level up animation)
✨ Profile Complete!  → Confetti + personality badge   
🏢 Register Shelter   → Form with progress indicator   (Level 2: Shelter in Training)
✅ Dashboard          → Gamified checklist with tiers   (Level 3: Ready to Rescue → Level 4: Live & Active)
```

---

## Part 1: Onboarding Wizard Gamification

### 1.1 Shelter Mascot Companion

Introduce a **simple SVG mascot** (a friendly stylized animal — think a geometric cat-dog hybrid in Tovitu purple/teal) that:
- Appears in the corner during the wizard
- Reacts to answers: nods, bounces, or changes expression
- Celebrates with sparkles when a question is completed
- Does a victory dance on final completion

The mascot is purely decorative (no functional delay) and respects `prefers-reduced-motion`.

### 1.2 Question Transition Overhaul

Replace the basic opacity + translateX with tiered animations:

| Transition | When | Animation |
|------------|------|-----------|
| **Question enters** | Next/back click | Scale(0.95) → Scale(1) + FadeIn, 400ms cubic-bezier(0.16,1,0.3,1) |
| **Selected option** | User taps a choice | Brief scale(1.05) pulse + background flash |
| **Progress bar fill** | Question completes | Shimmer + width transition, 600ms ease-out |
| **Milestone reached** | 25%, 50%, 75%, 100% | Small sparkle burst + dot highlight on progress bar |
| **Wizard complete** | All questions done | Full-screen confetti overlay + mascot celebration |

### 1.3 Onboarding Personality Result

After the last question, instead of a plain completion, show a **"Shelter Personality" card**:

```
╔══════════════════════════════════════╗
║  🎉 Your Shelter Profile is Ready!  ║
║                                      ║
║  ┌──────────────────────────────┐   ║
║  │   🏆 The Compassionate      │   ║
║  │      Guardian               │   ║
║  │                              │   ║
║  │  You prioritize long-term    │   ║
║  │  commitment and thorough     │   ║
║  │  screening. Amazing!         │   ║
║  └──────────────────────────────┘   ║
║                                      ║
║  [🐾 Let's Register Your Shelter]  ║
╚══════════════════════════════════════╝
```

**Personality types** (based on onboarding answers):

| Personality | Keywords | Criteria |
|-------------|----------|----------|
| **The Compassionate Guardian** | thorough, committed, long-term | extensive_matching + long_term_commitment priority |
| **The Heart-Led Rescuer** | passionate, emotional, urgent | small_rescue + basic_screening |
| **The Process Pro** | organized, efficient, scalable | large_shelter + interviews + managing_apps challenge |
| **The Community Builder** | connected, communicative, supportive | foster_based + whatsapp/social media channels |
| **The Growth Partner** | developmental, educational, big-picture | ngo_foundation + long_term_support |

This is purely cosmetic — no database changes. A simple hash-based determination in the presenter or helper.

### 1.4 Progress Bar Enhancement

Current: Thin `h-2` bar, primary-500 color, smooth width transition.

**New design:**
- **Thicker**: `h-3` with rounded-full
- **Gradient fill**: Primary → Secondary gradient (matching `progress-shimmer`)
- **Milestone dots**: Diamond markers at 25%, 50%, 75%, 100% with glow effect
- **Label**: "Question 3 of 7" becomes "🐾 Question 3 of 7 — You're doing great!"
- **Rotating tips**: Below the bar, cycle through encouraging tips (loaded from locale)

### 1.5 Sound / Haptic

No sounds. Respect the quiet web. Animations and visual feedback are sufficient.

---

## Part 2: Dashboard Checklist Gamification (Post-Shelter-Creation)

### 2.1 Tiered Progress System ("Shelter Levels")

Replace the flat percentage with a level system:

| Level | Title | Requirement | Visual |
|-------|-------|-------------|--------|
| 1 | **New Recruit** | Just completed onboarding | Bronze badge, empty bar |
| 2 | **Getting Ready** | 1-2 checklist items done | Silver badge, quarter bar |
| 3 | **Almost There** | 3-4 items done | Gold badge, three-quarter bar |
| 4 | **Ready to Rescue** | 5 items done (all but publish) | Purple diamond badge, full bar |
| 5 | **Live & Active** | All 6 done + shelter is active | Animated teal trophy badge |

### 2.2 Checklist Item Redesign

**Current:** A flat list with checkmarks and line-through text.

**New:**
- Each item is a **card** with:
  - Icon (SVG, not emoji) on the left
  - Title and brief description
  - "Action needed" badge or "Done!" badge
  - Right chevron indicating it's clickable
- **Completed items** animate with a success burst (scale-up checkmark + green glow)
- **Clicking a completed item** doesn't undo — it shows a "You completed this!" toast
- **In-progress item** has a subtle pulsing indicator to draw attention

### 2.3 Task Completion Celebration

When a checklist item is completed:
1. **Turbo Stream** updates the checklist partial
2. **Stimulus controller** detects the new "done" state and triggers:
   - A **checkmark burst** animation (SVG checkmark scales from 0 to 1, then a ring expands outward)
   - A **+1 progress** animation on the progress bar (bar pulses and fills)
   - If a **level threshold** is crossed: larger celebration (confetti overlay)
3. A **flash toast** appears: "🎉 Great job! You're X% complete!" (with different messages per milestone)

### 2.4 Encouragement & Tips

Beneath the checklist, show a dynamic encouragement area:

- **Next-step context**: "Adding your first pet helps adopters discover your shelter!"
- **Random fun fact**: Rotating tips about how other shelters succeed
- **Streak-like encouragement**: "You completed 3 tasks today — keep going!"

### 2.5 Empty State / Welcome Splash

When the user first lands on the dashboard (after shelter creation):
- A **welcome overlay** (dismissible) that says:
  ```
  🎉 Welcome to Your Shelter Dashboard!
  
  You're now the proud captain of [Shelter Name].
  Let's get your shelter ready for adopters.
  
  Complete these 6 steps to go live:
  [Show checklist preview]
  
  [Let's Go! →]
  ```
- This overlay plays once, stored in localStorage or a user flag

---

## Part 3: Shelter Registration Flow Improvements

### 3.1 Journey Context Bar

At the top of the registration form (`/shelters/new`), show a mini "journey so far" indicator:

```
📍 Your Journey: [Profile ✓] → [You are here: Register] → [Setup Dashboard]
```

Three dots/steps showing:
1. ✅ Profile Complete (from wizard)
2. ⏳ Register Shelter (current)
3. ⏳ Dashboard Setup (next)

### 3.2 Form Micro-Interactions

- Field focus: gentle scale(1.01) + border glow
- Valid field: checkmark icon appears on the right
- Submission: button shows a loading spinner, then redirects with a "Shelter created!" celebration

### 3.3 Post-Creation Handoff

After successful shelter creation via `Shelters::Register`:
- Redirect to dashboard with a **reduced welcome** (no full overlay since they saw it in wizard)
- Flash congratulatory message: "🏠 [Name] is now live! Let's set up your shelter."
- Progress bar already shows 1/6 complete if wizard profile was filled

---

## Part 4: Animation & CSS Library Additions

### 4.1 New Keyframes Needed

```css
/* ─── Confetti Burst ─── */
@keyframes confetti-fall {
  0% { transform: translateY(-10px) rotate(0deg); opacity: 1; }
  100% { transform: translateY(100vh) rotate(720deg); opacity: 0; }
}

/* ─── Checkmark Burst ─── */
@keyframes check-burst {
  0% { transform: scale(0) rotate(-45deg); opacity: 0; }
  50% { transform: scale(1.2) rotate(0deg); opacity: 1; }
  100% { transform: scale(1) rotate(0deg); opacity: 1; }
}

/* ─── Mascot Bounce ─── */
@keyframes mascot-bounce {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-8px); }
}

/* ─── Level Up Glow ─── */
@keyframes level-up-glow {
  0% { box-shadow: 0 0 0 0 rgba(108, 48, 255, 0.4); }
  70% { box-shadow: 0 0 0 15px rgba(108, 48, 255, 0); }
  100% { box-shadow: 0 0 0 0 rgba(108, 48, 255, 0); }
}

/* ─── Progress Diamond Pulse ─── */
@keyframes diamond-pulse {
  0%, 100% { transform: scale(1) rotate(45deg); }
  50% { transform: scale(1.3) rotate(45deg); }
}

/* ─── Card Complete Slide ─── */
@keyframes card-complete-slide {
  0% { transform: translateX(0); opacity: 1; }
  50% { transform: translateX(8px); opacity: 0.5; }
  51% { transform: translateX(-8px); opacity: 0.5; }
  100% { transform: translateX(0); opacity: 1; }
}
```

### 4.2 Utility Classes

```css
.confetti-container {
  position: fixed;
  inset: 0;
  pointer-events: none;
  z-index: var(--z-toast);
  overflow: hidden;
}

.confetti-piece { animation: confetti-fall linear forwards; }

.check-burst { animation: check-burst 500ms cubic-bezier(0.16, 1, 0.3, 1) both; }

.mascot-bounce { animation: mascot-bounce 600ms ease-in-out; }

.level-up-glow { animation: level-up-glow 800ms ease-out; }

.diamond-pulse { animation: diamond-pulse 800ms ease-in-out; }

.card-complete { animation: card-complete-slide 400ms ease-out; }
```

### 4.3 Respect `prefers-reduced-motion`

All new animations must be gated:

```css
@media (prefers-reduced-motion: reduce) {
  .confetti-piece,
  .check-burst,
  .mascot-bounce,
  .level-up-glow,
  .diamond-pulse,
  .card-complete {
    animation: none !important;
  }
  .confetti-container {
    display: none;
  }
}
```

---

## Part 5: Stimulus Controller Changes

### 5.1 New Controller: `shelter_onboarding`

Extend the existing `onboarding` controller with:

```
shelter_onboarding_controller.js
  - Connects to the wizard
  - Adds mascot reaction triggers
  - Manages milestone celebrations
  - Builds personality result card
  - Fires confetti on completion
```

### 5.2 New Controller: `checklist`

```
checklist_controller.js
  - Connects to the dashboard checklist container
  - Watches for Turbo Stream updates to check for newly-completed items
  - Triggers checkmark burst animation on detected completion
  - Calculates level and triggers level-up celebration when threshold crossed
  - Manages encouragement tip rotation
```

### 5.3 New Controller: `confetti`

```
confetti_controller.js
  - Creates confetti pieces (colored divs or SVG circles in Tovitu palette)
  - Pieces fall with randomized x-offset, rotation, and delay
  - Auto-cleans up after animation completes (2-3 seconds)
  - One-shot: fire and forget, no persistent state
```

### 5.4 Enhanced: `single_select` & `multi_select`

Add stronger feedback on selection:
- Brief scale pulse on the selected chip/card
- Update a "selected summary" area below the options
- Trigger mascot reaction via event dispatch

### 5.5 Event Bus Architecture

Use Stimulus `dispatch()` for cross-controller communication:

| Event | Origin | Listener(s) |
|-------|--------|-------------|
| `question:completed` | `single_select` / `multi_select` | `shelter_onboarding` |
| `milestone:reached` | `shelter_onboarding` | (self-managed) |
| `wizard:complete` | `shelter_onboarding` | `confetti` |
| `checklist:item-done` | Turbo Stream response | `checklist` |
| `checklist:level-up` | `checklist` | `confetti` |

---

## Part 6: Service Object & Domain Changes

### 6.1 New Service: `Onboarding::Shelter::Personality`

```ruby
module Onboarding
  module Shelter
    class Personality < ApplicationService
      PERSONALITIES = {
        guardian: { name: "Compassionate Guardian", icon: "🛡️", ... },
        heart_led: { name: "Heart-Led Rescuer", icon: "❤️", ... },
        process_pro: { name: "Process Pro", icon: "📋", ... },
        community_builder: { name: "Community Builder", icon: "🤝", ... },
        growth_partner: { name: "Growth Partner", icon: "🌱", ... }
      }.freeze

      def initialize(profile)
        @profile = profile
      end

      def call
        # Deterministic personality based on answers
        # Returns { key:, name:, icon:, description: }
      end
    end
  end
end
```

### 6.2 Enhanced Presenter: `ShelterPresenter`

Add to `onboarding_steps`:
- Each step gets a `description` field for richer display
- Each step gets an `icon` field (SVG path data)
- Each step gets a `category` field (profile / pets / team / operations / visibility)

Add `checklist_level` method:
```ruby
def checklist_level
  done_count = onboarding_steps.count { |s| s[:done] }
  case done_count
  when 0 then { level: 1, title: "New Recruit", badge: :bronze }
  when 1..2 then { level: 2, title: "Getting Ready", badge: :silver }
  when 3..4 then { level: 3, title: "Almost There", badge: :gold }
  when 5 then { level: 4, title: "Ready to Rescue", badge: :purple }
  when 6 then { level: 5, title: "Live & Active", badge: :teal }
  end
end
```

### 6.3 Turbo Stream Responses for Checklist

Each checklist action (add pet, update policies, invite staff, etc.) must return a Turbo Stream that:
1. Replaces the checklist partial
2. Dispatches a `checklist:item-done` event if a new item was completed
3. Replaces the progress bar

Example turbo_stream:
```ruby
# In the controller after a successful action:
respond_to do |format|
  format.turbo_stream do
    render turbo_stream: [
      turbo_stream.replace("onboarding-checklist", partial: "shelters/dashboard/checklist"),
      turbo_stream.replace("progress-bar", partial: "shelters/dashboard/progress_bar"),
      turbo_stream.append("flash-container", partial: "shared/flash")
    ]
  end
end
```

---

## Part 7: Locale Additions

### 7.1 New Keys for Gamification

```yaml
en:
  onboarding:
    shelter:
      title: "Tell us about your organization"
      personality:
        guardian:
          name: "Compassionate Guardian"
          description: "You prioritize long-term commitment and thorough screening. Amazing!"
        heart_led:
          name: "Heart-Led Rescuer"
          description: "You lead with passion and heart. Every pet is personal."
        process_pro:
          name: "Process Pro"
          description: "You're organized and efficient. Your shelter runs like clockwork."
        community_builder:
          name: "Community Builder"
          description: "You believe in connection. Community is your superpower."
        growth_partner:
          name: "Growth Partner"
          description: "You think big picture. Every adoption is a step forward."
      celebration:
        complete: "Your shelter profile is ready! Let's set up your organization."
        confetti: true  # key exists for i18n-based feature detection
      progress:
        label: "Question %{current} of %{total}"
        tips:
          - "Almost there! Your answers help us match you with the right tools."
          - "Every great shelter started with a plan. You're building yours!"
          - "Fun fact: Shelters with complete profiles get 3x more adoption requests!"
          - "You're doing great! Just a few more questions."
      mascot:
        thinking: "mascot-thinking"
        happy: "mascot-happy"
        celebrate: "mascot-celebrate"
    checklist:
      level:
        new_recruit: "New Recruit"
        getting_ready: "Getting Ready"
        almost_there: "Almost There"
        ready_to_rescue: "Ready to Rescue"
        live_and_active: "Live & Active"
      step:
        add_pet:
          title: "Add Your First Pet"
          description: "List a pet for adoption and start finding their forever home"
          done_message: "First pet listed! 🎉"
          tips: "Pets with photos get 94% more views. Upload clear, well-lit pictures!"
        policies:
          title: "Set Adoption Policies"
          description: "Define your requirements so adopters know what to expect"
          done_message: "Policies configured! ✅"
          tips: "Clear policies reduce unqualified applications by up to 40%."
        staff:
          title: "Invite Your Team"
          description: "Add staff members to help manage the shelter"
          done_message: "Team growing! 🎉"
          tips: "Collaborate with your team to review applications faster."
        hours:
          title: "Set Your Hours"
          description: "Let adopters know when you're open"
          done_message: "Hours set! ✅"
          tips: "Including hours helps adopters plan their visit."
        profile:
          title: "Complete Your Profile"
          description: "Tell adopters about your mission and what makes you special"
          done_message: "Profile looks great! ✅"
          tips: "Shelters with a complete profile build trust with adopters."
        publish:
          title: "Go Live"
          description: "Activate your shelter to appear in the public directory"
          done_message: "You're live! 🎉🐾"
          tips: "Congratulations! Your shelter is now visible to adopters."
      encouragement:
        completed: "You completed %{count} of %{total} steps! Keep going!"
        all_done: "🎉 Amazing! Your shelter is fully set up and ready for adopters!"
        level_up: "Level Up! You've reached: %{level}!"
    register:
      journey:
        step1: "Profile Complete"
        step2: "Register Shelter"
        step3: "Setup Dashboard"
      celebration: "%{name} is now registered! Let's get you set up."
```

### 7.2 Spanish Additions

All the above keys need Spanish translations in `es.yml`. Follow the existing pattern from the current locale files.

---

## Part 8: Implementation Order

### Phase 1 (Foundation)
| Step | What | Files |
|------|------|-------|
| 1 | Add CSS keyframes for all new animations | `app/assets/tailwind/application.css` |
| 2 | Create `confetti_controller.js` | `app/javascript/controllers/` |
| 3 | Create `checklist_controller.js` | `app/javascript/controllers/` |
| 4 | Add `Personality` service object | `lib/onboarding/shelter/personality.rb` |
| 5 | Update `ShelterPresenter` with level system | `app/presenters/shelter_presenter.rb` |

### Phase 2 (Onboarding Wizard)
| Step | What | Files |
|------|------|-------|
| 6 | Enhance `onboarding_controller.js` with mascot events, milestone triggers | `app/javascript/controllers/onboarding_controller.js` |
| 7 | Update wizard view with personality result card | `app/views/onboarding/shelter/questions/show.html.erb` |
| 8 | Add confetti trigger on completion | `app/views/onboarding/shelter/questions/show.html.erb` |
| 9 | Add progress tips rotation | wizard view |
| 10 | Update locale keys for personality, tips, mascot | `config/locales/en.yml`, `es.yml` |

### Phase 3 (Registration Flow)
| Step | What | Files |
|------|------|-------|
| 11 | Add journey context bar to shelter form | `app/views/shelters/new.html.erb` |
| 12 | Add field micro-interactions (focus, valid states) | Stimulus or CSS |
| 13 | Update flash message on creation | `app/controllers/shelters_controller.rb` |

### Phase 4 (Dashboard Checklist)
| Step | What | Files |
|------|------|-------|
| 14 | Redesign checklist partial as cards | `app/views/shelters/dashboard/_checklist.html.erb` (new partial) |
| 15 | Add level badge and progress tier system | partial + presenter |
| 16 | Add Turbo Stream responses to all checklist actions | various controllers |
| 17 | Wire `checklist_controller.js` to DOM events | Stimulus |
| 18 | Add welcome overlay (dismissible) | new partial + Stimulus |
| 19 | Add encouragement area below checklist | partial |

### Phase 5 (Polish)
| Step | What | Files |
|------|------|-------|
| 20 | Test all animations with `prefers-reduced-motion` | E2E / manual |
| 21 | Add Spanish locale translations | `config/locales/es.yml` |
| 22 | Write request specs for new behavior | `spec/requests/` |
| 23 | QA pass on all states (empty, partial, complete) | Manual |

---

## Part 9: Success Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Onboarding wizard abandonment rate | (unknown) | < 10% |
| Wizard completion → shelter registration rate | (unknown) | > 85% |
| Dashboard checklist completion within 7 days | (unknown) | > 70% |
| Shelter going "active" within 14 days | (unknown) | > 60% |
| User satisfaction (qualitative) | (unknown) | Positive sentiment |

---

## Part 10: Edge Cases & Notes

| Edge Case | Handling |
|-----------|----------|
| User has `prefers-reduced-motion` | All animations disabled, confetti hidden, mascot static |
| Wizard skipped (user clicks "Skip") | No personality card shown, redirect straight to registration |
| User returns to edit profile from settings | Personality re-evaluated on profile load |
| Checklist item completed via another route (e.g., editing shelter profile) | Turbo Stream replaces checklist on any related update |
| Turbo disabled / JS not available | Fallback to static checklist no animations — functionality preserved |
| Slow network / Turbo Stream delayed | Checklist loads from server, animation fires on DOM mutation detected by Stimulus |
| Multiple tabs open | Each tab independently handles celebrations (acceptable) |
| Level 5 achieved, then item becomes incomplete | Level drops back. Celebration only plays on *first* achievement of each level. |
| Confetti on slow devices | Confetti creates at most 30 pieces, auto-removes after 3s, no layout thrash |

---

## Architectural Decisions

1. **No new database columns** — All gamification is cosmetic (level derived from step count, personality derived from profile answers, celebration state tracked in Stimulus session). No new migrations.

2. **No new gems** — Confetti is DOM-generated, not a canvas/WebGL library. Keeps the bundle tiny.

3. **Turbo Stream for checklist** — Each checklist action controller already returns a redirect or render. Convert relevant actions to respond with Turbo Streams for seamless partial replacement.

4. **Stimulus dispatch events** — Cross-controller communication uses `dispatch()` to avoid coupled controller hierarchies.

5. **SVG mascot inline** — The mascot is an inline SVG (not an external image) for zero-latency rendering and easy color theming. Placed in a partial for reuse.

6. **Level state in DOM not JS** — The level is computed server-side in the presenter and rendered as a data attribute. Stimulus reads it on connect. This ensures SSR and Turbo work correctly.

---

## Files to Create

| File | Type |
|------|------|
| `app/javascript/controllers/confetti_controller.js` | New Stimulus controller |
| `app/javascript/controllers/checklist_controller.js` | New Stimulus controller |
| `lib/onboarding/shelter/personality.rb` | New service object |
| `app/views/shelters/dashboard/_checklist.html.erb` | New partial (extracted from dashboard) |
| `app/views/shelters/dashboard/_progress_bar.html.erb` | New partial |
| `app/views/shelters/dashboard/_welcome_overlay.html.erb` | New partial |
| `app/views/shelters/dashboard/_encouragement.html.erb` | New partial |
| `app/views/shelters/dashboard/_journey.html.erb` | New partial for registration context bar |

## Files to Modify

| File | Changes |
|------|---------|
| `app/assets/tailwind/application.css` | Add 7 new keyframes + utility classes + prefers-reduced-motion guards |
| `app/javascript/controllers/onboarding_controller.js` | Add milestone detection, mascot triggers, confetti fire |
| `app/javascript/controllers/single_select_controller.js` | Add selection pulse animation |
| `app/javascript/controllers/multi_select_controller.js` | Add selection pulse animation |
| `app/presenters/shelter_presenter.rb` | Add `checklist_level`, enhanced `onboarding_steps` with descriptions/icons |
| `app/views/onboarding/shelter/questions/show.html.erb` | Add personality card, mascot, tips, confetti trigger |
| `app/views/shelters/dashboard/show.html.erb` | Extract checklist into partial, add levels + encouragement |
| `app/views/shelters/new.html.erb` | Add journey context bar |
| `app/helpers/application_helper.rb` | Add personality helper |
| `app/controllers/shelters_controller.rb` | Turbo Stream response for checklist updates |
| `app/controllers/shelters/dashboard_controller.rb` | Load level data |
| `config/locales/en.yml` | Add all gamification keys |
| `config/locales/es.yml` | Add Spanish translations |

---

## Open Questions

1. **SVG mascot design** — Should we create a custom SVG or use an existing design from the brand kit? **Decision: Custom simplified geometric shape** (a rounded triangle-ear cat form in purple) — matches the Playground Standard's bold, flat aesthetic. Created inline as a minimal SVG (~1KB).

2. **Confetti intensity** — How many pieces, what duration, should it loop? **Decision: 25 pieces, 2.5s duration, single burst.** Enough to feel celebratory, not enough to be distracting or perf-heavy.

3. **Level recalculation** — If a shelter removes a pet (going from 1 to 0), does the level drop? **Decision: Yes,** the level is derived from current state. But the level-up celebration only plays once per level (stored as a flag on the DOM via a `data-celebrated` attribute).

4. **Personality on profile edit** — If a shelter admin edits their onboarding profile later, does their personality change? **Decision: Yes,** it's recalculated on profile load. This encourages updating answers honestly.

5. **Mobile considerations** — Confetti should be 15 pieces on mobile (reduced for performance). Mascot should be smaller or hidden on very small screens (< 360px).
