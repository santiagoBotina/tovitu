---
target: Pet detail page (app/views/pets/show.html.erb)
total_score: 18
p0_count: 0
p1_count: 3
p2_count: 3
timestamp: 2026-06-24T23-48-30Z
slug: app-views-pets-show-html-erb
---
# Critique: Pet Detail Page (`app/views/pets/show.html.erb`)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | **2** | Life preview loading is good; CTA gives no feedback; application flow has zero status |
| 2 | Match System / Real World | **3** | Natural adoption language; "Good with children/dogs/cats" is immediately clear |
| 3 | User Control and Freedom | **1** | Only escape is a small "Back to pets"; no save/favorite; CTA is a dead `#` link |
| 4 | Consistency and Standards | **2** | Cards are internally consistent but gradient CTA violates flat-color design system; purple brand color is missing |
| 5 | Error Prevention | **2** | Status banner for unavailable pets is good; `#` CTA is an error trap; thumbnails falsely promise interaction |
| 6 | Recognition Rather Than Recall | **3** | All info visible on the page; personality tags are scannable |
| 7 | Flexibility and Efficiency | **1** | No keyboard shortcuts, no save/favorite, no compare, no return-to-browse preserving scroll |
| 8 | Aesthetic and Minimalist Design | **2** | Too many identical white-card sections create monotony; brand identity is invisible; gradient violations |
| 9 | Error Recovery | **1** | Life preview error has a retry button; no other recovery paths visible |
| 10 | Help and Documentation | **1** | No contextual help, no application process explanation, no FAQ |
| **Total** | | **18/40** | **Poor — major improvements needed** |

## Anti-Patterns Verdict

**LLM assessment**: Borderline. This page avoids the loudest tells (no glassmorphism, no side-stripe borders, no gradient text, no numbered sections), but a trained eye spots several:
- Tiny uppercase tracked labels on stat cards ("AGE", "SIZE", "SEX", "SPECIES") — the 2023-era eyebrow anti-pattern at micro scale
- Four identical stat mini-cards in a row — the "identical card grids" anti-pattern
- Gradient surfaces (`bg-gradient-to-br`) on the CTA card and throughout life preview violate DESIGN.md's "Solid, flat color only" rule
- Purple brand color (#6C30FF) appears on exactly one element (shelter name link). On a page that should be the most identity-critical in the product
- Photo thumbnails with `cursor-pointer` + selection ring but no click handler — a functional lie

**Deterministic scan**: The detector found **2 issues** — both `bounce-easing` warnings in `app/views/pets/_life_preview_loading.html.erb`:
- Line 34: `animate-bounce` on a heart icon
- Line 47: `animate-bounce` on loading dots

These use bounce easing (`animate-bounce`) which the impeccable skill flags as dated. Real objects decelerate smoothly. The bounce is applied to loading dots (intentional playfulness) but the detector is right that exponential easing would feel more refined.

**Visual overlays**: No browser visualization was available — no dev server was running for injection. Assessment is based on source code analysis.

## Overall Impression

This page is structurally sound but visually flat. The information architecture is logical — photo → stats → description → details → CTA — but the execution lacks the bold, playful energy the brand promises. Too many identical white cards, almost no purple, and the core differentiator (AI life preview) is buried at the bottom. The primary CTA linking to `#` is the most damaging single issue; it makes the whole page feel incomplete.

## What's Working

1. **Life preview loading animation** (`_life_preview_loading.html.erb`). Species-specific icon, heartbeat ping, dynamic "Imagining a life with [name]..." copy. Genuine craft that makes the wait feel branded rather than dead time.

2. **Status banner for unavailable pets** (yellow alert). Positioned prominently above the fold. This is the design system's "Error prevention" principle in action — stops users from applying to an already-adopted pet.

3. **Compatibility section uses dual encoding** (icon + color). Checkmark/X icon alongside tinted backgrounds means both screen reader users and colorblind users understand status without relying on color alone.

## Priority Issues

### [P1] Primary CTA ("Apply to Adopt") links to `#`

**What**: `link_to "#"` on the application button. Clicking does nothing.
**Why it matters**: This is the page's core task. Users come to learn about a pet and apply. A dead link here blocks the primary flow entirely.
**Fix**: Wire to the actual adoption application path, or show a stateful message if the flow isn't built yet ("Coming soon — be the first to apply" with a notify option).
**Suggested command**: `/impeccable harden`

### [P1] Brand primary color (purple) is virtually absent

**What**: The #6C30FF purple appears on exactly one element (shelter name link). The page is essentially neutral-gray + teal.
**Why it matters**: Users won't connect this page to Tovitu's brand. The design system says purple "appears on every screen." This page violates that principle, making the platform feel generic.
**Fix**: Use purple on the "Apply" button background, add a primary-50 wash to the pet name header area, or use purple accent elements in the photo gallery.
**Suggested command**: `/impeccable colorize`

### [P1] Photo gallery thumbnails promise interaction that doesn't exist

**What**: Five thumbnail `<img>` tags with `cursor-pointer`, `hover:opacity-90`, and `ring-2 ring-secondary-500` on the first — but no click handler.
**Why it matters**: Users expect to click a thumbnail and see that photo. The "selected" ring on the first implies a carousel state that can't change. This is a UI lie that erodes trust.
**Fix**: Either wire thumbnails to update the hero photo via Stimulus, or remove `cursor-pointer` and the selection ring.
**Suggested command**: `/impeccable audit`

### [P2] Stat card labels use the tiny-uppercase-tracked anti-pattern

**What**: Labels like "AGE", "SIZE" render as `text-xs text-neutral-500 uppercase tracking-wide` — the exact eyebrow anti-pattern.
**Why it matters**: This is explicitly banned in both the absolute bans and DESIGN.md. It's the single most recognizable AI slop tell, and it signals "generic template" rather than a crafted product.
**Fix**: Use sentence-case labels at body size with normal tracking, or use icons + direct value statements.
**Suggested command**: `/impeccable distill`

### [P2] AI life preview (the differentiator) is buried at the bottom

**What**: The AI life preview — Tovitu's core differentiator — loads lazily at the bottom of the main column, after requirements, compatibility, and health.
**Why it matters**: Most users won't scroll that far. The feature that makes Tovitu different from any other pet listing is invisible to most visitors.
**Fix**: Move life preview above requirements, or add an early teaser link ("See what life with Luna would look like →").
**Suggested command**: `/impeccable layout`

### [P2] The detector found 2 bounce-easing animations

**What**: `animate-bounce` on the loading heart icon (line 34) and loading dots (line 47) in `_life_preview_loading.html.erb`. The impeccable skill flags bounce easing as dated.
**Why it matters**: While the intent is playful and matches the brand, bounce easing specifically dates the interface and feels tacky. Exponential ease-out would feel more refined.
**Fix**: Replace `animate-bounce` with a custom fade-pulse or scale-pulse animation using ease-out-quart.
**Suggested command**: `/impeccable polish`

## Persona Red Flags

### Jordan (Confused First-Timer)

- **CTA is dead**: Clicks "Apply to Adopt" → nothing. Thinks the site is broken.
- **No process explanation**: No indication of what applying involves (how many steps, what's needed, how long). Jordan hesitates, doesn't click.
- **Life Preview undefined**: "Imagining a life with [name]" is poetic but not informative. Jordan doesn't know if it's a video, a simulation, or text.
- **Photo thumbnails**: Clicks expecting a new photo. Nothing happens. Thinks touch is broken.

### Sam (Accessibility-Dependent)

- **CTA `#` link**: Keyboard-focusable but does nothing on activation. Disorienting — no feedback, no error.
- **Photo thumbnails**: `<img>` tags with no `role="button"`, no `tabindex`, no keyboard handler. Screen reader sees decorative images.
- **Status badge via `html_safe`**: Raw HTML in badge may parse inconsistently across screen readers.
- **SVG icons lack `aria-label`**: Most icons lack text equivalents.

### Casey (Distracted Mobile User)

- **CTA is last**: Reflows below main content on mobile. Casey must scroll past 18+ information blocks before reaching the Apply button.
- **Tiny photo grid**: `grid-cols-5 gap-1` on mobile means ~60×60px thumbnails — below the 44×44pt minimum tap target.
- **No sticky/floating CTA**: The only action button is at the very bottom of page.
- **Life preview lazy-loads**: On a slow connection, Casey may leave before it finishes.

## Minor Observations

- Species appears twice: once in tag chips and once in stats grid. Redundant.
- "Good with children" reads formal — "Good with kids" matches Tovitu's playful tone better.
- Back link is `text-sm text-neutral-500` — easy to miss, especially on mobile.
- Health section's "special needs" in warning color doesn't explain what those needs are.
- No adoption fee, location radius, or timeline shown — basic decision factors absent.
- Gradient CTA card is the only bold visual, making it look disconnected from the flat white cards above.
- Life preview uses emoji icons (☀️, 🍽️, 🎒) which render inconsistently across platforms.
- No way to save/bookmark a pet — users browsing multiple pets must rely on browser history.

## Questions to Consider

1. **What if the CTA were sticky at the bottom of the viewport on mobile?** A floating "Apply to Adopt" bar would drastically reduce scroll-to-action distance and keep the primary action always in reach.

2. **What if the life preview was the hero image, not a separate section at the bottom?** Instead of a standard photo carousel, the primary visual could be the AI-generated "life with you" concept — the differentiator becomes the first thing users see.

3. **What if this page had one bold color block (purple or teal) as a structural element instead of 10 identical white cards?** A colored hero area or sidebar would make the page feel designed rather than assembled from templates.

4. **What if the photo gallery were a proper carousel (hero image + clickable thumbs) instead of a static grid with fake pointer cursors?** This alone would eliminate the most damaging false affordance and improve the browsing experience.
