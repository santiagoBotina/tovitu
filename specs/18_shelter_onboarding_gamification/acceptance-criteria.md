# Acceptance Criteria: Shelter Onboarding Gamification

---

## AC-1: Onboarding Wizard Animations

**Given** I am a shelter user on the onboarding wizard
**When** I click "Next" to advance a question
**Then** the question card animates with scale(0.95)→scale(1) + fade-in over 400ms

**Given** I am on the onboarding wizard
**When** I select a single-select or multi-select option
**Then** the selected option pulses briefly (scale 1.05) with a background color flash

**Given** I am on the onboarding wizard
**When** a question is completed
**Then** the progress bar fills with a shimmer animation + width transition

**Given** I reach a milestone (25%, 50%, 75%, 100%)
**Then** a sparkle burst animation appears on the progress bar milestone dot

---

## AC-2: Personality Result Card

**Given** I have answered all 7 questions
**When** the wizard completes
**Then** I see a "Shelter Personality" card with a personality name, icon, and description

**Given** I see the personality card
**When** I click "Let's Register Your Shelter"
**Then** I am redirected to the shelter registration form

**Given** I skipped the wizard
**When** the wizard completes
**Then** no personality card is shown; I go straight to registration

---

## AC-3: Confetti Celebration

**Given** I complete the wizard
**When** the personality card appears
**Then** confetti pieces (25 pieces, Tovitu palette colors) fall from the top of the screen for 2.5s

**Given** confetti is playing
**When** I have `prefers-reduced-motion` enabled
**Then** no confetti is shown

**Given** confetti is playing
**When** 3 seconds have passed
**Then** all confetti DOM elements are removed

---

## AC-4: Mascot Companion

**Given** I am on the onboarding wizard
**When** the page loads
**Then** a small SVG mascot (geometric cat-dog hybrid, Tovitu purple/teal) appears in the corner

**Given** I select an answer
**When** the selection is made
**Then** the mascot bounces or reacts

**Given** I complete the wizard
**When** the personality card shows
**Then** the mascot does a victory dance (repeated bounce + sparkle)

**Given** I have `prefers-reduced-motion` enabled
**When** the mascot would animate
**Then** it remains static (no bounce/dance)

---

## AC-5: Progress Bar Enhancement

**Given** I am on the wizard
**When** I look at the progress bar
**Then** it is h-3 with rounded-full, gradient fill (primary→secondary)

**Given** I am on the wizard
**When** I advance through questions
**Then** the progress label shows "🐾 Question X of 7 — You're doing great!"

**Given** I am on the wizard
**When** I look below the progress bar
**Then** rotating tips cycle through encouraging messages

---

## AC-6: Level System

**Given** I am on the shelter dashboard
**When** I view the checklist
**Then** a level badge is displayed showing my current shelter level (1-5)

**Given** I have completed 0 checklist items
**When** I view my level
**Then** it shows "New Recruit" with a bronze badge

**Given** I have completed all 6 items
**When** I view my level
**Then** it shows "Live & Active" with an animated teal trophy badge

**Given** I complete an item that crosses a level threshold
**When** the progress updates
**Then** a confetti celebration fires (first time only per level)

---

## AC-7: Checklist Card Redesign

**Given** I am on the dashboard
**When** I view the checklist
**Then** each item is a card with SVG icon, title, description, and status badge

**Given** I complete a checklist item
**When** the Turbo Stream updates the partial
**Then** a checkmark burst animation plays on the completed item

**Given** I click a completed item
**When** I navigate to it
**Then** it shows a "You completed this!" toast (does not undo)

**Given** I have an incomplete item
**When** the dashboard loads
**Then** the next incomplete item has a subtle pulsing indicator

---

## AC-8: Journey Context Bar

**Given** I am on the shelter registration form
**When** the form loads
**Then** a 3-step journey indicator is shown: ✅ Profile → ⏳ Register Shelter → ⏳ Setup Dashboard

**Given** I am on the registration form
**When** I focus a field
**Then** the field gets a gentle scale(1.01) + border glow

**Given** I submit the form
**When** the submission succeeds
**Then** I am redirected to the dashboard with a congratulatory flash message

---

## AC-9: Welcome Overlay

**Given** I am a new shelter user
**When** I first land on the dashboard
**Then** a welcome overlay appears with "Welcome to Your Shelter Dashboard!" and checklist preview

**Given** I dismiss the welcome overlay
**When** I revisit the dashboard
**Then** the overlay does not appear again

---

## AC-10: Encouragement Area

**Given** I am on the dashboard
**When** I view the checklist
**Then** an encouragement area below shows next-step context and rotating tips

**Given** I complete checklist items
**When** progress updates
**Then** the encouragement shows "You completed X of 6 steps! Keep going!"

---

## AC-11: Turbo Stream Responses

**Given** I complete a checklist action (e.g., add a pet)
**When** the action succeeds
**Then** the response replaces the checklist partial and progress bar via Turbo Stream

**Given** a Turbo Stream response is received
**When** a new item is marked done
**Then** a `checklist:item-done` event is dispatched

---

## AC-12: Accessibility & Reduced Motion

**Given** a user has `prefers-reduced-motion` set
**When** any gamification animation would play
**Then** it does not play

**Given** a user has `prefers-reduced-motion` set
**When** confetti would be shown
**Then** the confetti container is hidden

---

## AC-13: Locale Support

**Given** the locale is English
**When** I view gamification elements
**Then** all text is in English (personality names, tips, level titles, encouragement)

**Given** the locale is Spanish
**When** I view gamification elements
**Then** all text is translated to Spanish

---

## AC-14: Personality Recalculation

**Given** I edit my shelter profile from settings
**When** the profile loads
**Then** my personality is recalculated based on current answers

**Given** my personality changes
**When** I view the personality card
**Then** it reflects the updated determination
