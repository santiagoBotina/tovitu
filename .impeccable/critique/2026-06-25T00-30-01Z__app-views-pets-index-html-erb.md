---
target: Pet browsing page (app/views/pets/index.html.erb)
total_score: 20
p0_count: 0
p1_count: 2
p2_count: 3
timestamp: 2026-06-25T00-30-01Z
slug: app-views-pets-index-html-erb
---
# Critique: Pet Browsing Page (`app/views/pets/index.html.erb`)

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | **2** | No loading indicators for filter application; showing_count is stale on slow connections |
| 2 | Match System / Real World | **3** | Natural language throughout; "Other" species label could confuse |
| 3 | User Control and Freedom | **3** | Good filter clearing; URL-based back navigation works. No comparison/favorites. |
| 4 | Consistency and Standards | **2** | `shadow-sm` at rest contradicts flat-surface principle; no purple brand color anywhere; inconsistencies in token semantics |
| 5 | Error Prevention | **2** | Unconstrained search text field; otherwise read-only, limited exposure |
| 6 | Recognition Rather Than Recall | **3** | Pet info visible at card level; personality traits truncated well |
| 7 | Flexibility and Efficiency | **1** | No keyboard shortcuts, no sorting, no alternative views, no saved searches |
| 8 | Aesthetic and Minimalist Design | **2** | Clean but generic — white-card SaaS default, no brand personality, no playground character |
| 9 | Error Recovery | **2** | Empty state handled well; no error-state for server failures |
| 10 | Help and Documentation | **0** | Zero contextual help; no guidance for first-time adopters; no tooltips |
| **Total** | | **20/40** | **Acceptable — significant improvements needed** |

## Anti-Patterns Verdict

**LLM assessment**: Passes first glance, fails scrutiny. The page has zero purple (#6C30FF), the brand anchor — it's beige-by-default with white cards, `shadow-sm`, `border-neutral-200`, and teal accents. Exactly the corporate/vendor-neutral vocabulary DESIGN.md rejects. Specific tells: no purple anywhere, shadows at rest on every surface, white-on-white card grid, teal carrying all the (one-note) weight.

**Deterministic scan**: Clean — the detector found **0 issues** across the markup.

**Visual overlays**: No browser visualization available (no dev server running).

## Overall Impression

Structurally competent but brand-blind. The filter form works, the grid lays out, the empty state is well handled — but the page doesn't feel like Tovitu. Purple is absent, shadows contradict the flat-surface design system, and the filter form overwhelms users before they see a single pet. The core tension: this is a rational product-catalog view for an emotional, high-stakes discovery process.

## What's Working

1. **Empty state** is genuinely good — search icon in a circle, clear message, prominent "Clear filters" CTA following error-recovery best practices.

2. **Personality trait truncation** (max 3 + "+N") prevents variable-length card sprawl — smart load management.

3. **Filter state in URL** enables shareable filtered views and back-button navigation — a robust architectural choice.

## Priority Issues

### [P1] Brand identity absent — zero purple, zero playground character
**What**: The page uses teal exclusively. Purple (#6C30FF) — the brand anchor — is completely absent. DESIGN.md: "Purple carries energy and trust; teal carries calm and growth." Only calm is present.
**Why**: Users don't develop brand recognition or emotional connection. The page looks like every other pet site.
**Fix**: The "Apply filters" button should be primary-500 (purple). The filter container should use a primary-50 tint. Age badges should use primary-50/primary-700. Inject purple into at least 2–3 surface-level elements.
**Suggested command**: `/impeccable colorize`

### [P1] Shadows at rest violate the flat-surface principle
**What**: `shadow-sm` on both the filter container and every pet card at rest. DESIGN.md: "At rest, every surface is flat. Elevation is a response to interaction, not a default state."
**Why**: The system's defining characteristic (flat, bold, neubrutalism-inspired) is undermined. The page reads Material Design, not Playground Standard.
**Fix**: Remove `shadow-sm` from resting containers. Keep it only on hover states for cards. The structure from borders + color blocks, not shadows.
**Suggested command**: `/impeccable polish`

### [P2] Filter section causes cognitive overload
**What**: 16+ decision points visible simultaneously — species pills (4), search text, age (5), size (5), sex (4), apply, clear. Filter form occupies the first 40% of the viewport above the fold.
**Why**: Users arrive excited about pets and hit a wall of controls. They either brute-force filter or ignore it entirely. Either way, a poor experience.
**Fix**: Collapse detailed filters behind a toggle. Keep search always visible. Or switch to a sidebar on desktop. At minimum, reduce to search + species + one dropdown.
**Suggested command**: `/impeccable distill`

### [P2] Pet cards carry too much information per chunk
**What**: 7–8 data points per card (photo, name, age badge, species, breed, size, location, 0–N personality tags, "View Profile"). Chunking failure.
**Why**: Scanning speed drops with each data point. Users browsing many pets experience fatigue and decision paralysis.
**Fix**: Reduce to photo, name, age, location, max 2 personality traits. Move breed and size to the detail page. Remove "View Profile" — the entire card is already a link.
**Suggested command**: `/impeccable distill`

### [P2] No save/comparison mechanism for a high-stakes decision
**What**: No favorites, no saved list, no comparison. PRODUCT.md: "Adoption is emotional and high-stakes." Users browse 5–10+ pets before deciding.
**Why**: Without a way to save/bookmark, users rely on memory or browser history. This is a conversion leak for the primary platform action.
**Fix**: Add a save/favorite button (heart icon) that persists to a session or account wishlist.
**Suggested command**: `/impeccable shape`

### [P3] No loading state for slow connections
**What**: No skeleton cards, no spinner. Page renders server-side in one request.
**Fix**: Add skeleton cards matching the pet card layout. Consider pagination or infinite scroll.
**Suggested command**: `/impeccable audit`

## Persona Red Flags

### Jordan (Confused First-Timer)
- **"What do I do first?"** — Filter form sits above the pet grid. Jordan sees 7+ controls before any pet. Primary action (browse) is below the fold.
- **"What's 'Other'?"** — Ambiguous species label. No explanation.
- **No contextual help** — Zero guidance for a high-stakes emotional decision.

### Sam (Accessibility-Dependent)
- **Hover-only states** — Species chips use hover for visual feedback. Keyboard users see no indicator.
- **`text-sm` everywhere** — 14px body text in metadata and tags. Below recommended readability baseline.
- **SVGs lack accessible labels** — Location icon, search icon are inlined SVGs with no `aria-label` or `role="img"`.
- **Color dependency** — Active vs inactive filter states rely on bg + text color shifts.

### Casey (Distracted Mobile User)
- **Tap targets below 44pt** — Species chips `py-2` ≈ 32px height; personality tags `py-1` ≈ 24px. Both below Apple HIG minimum.
- **Form submission on mobile** — GET submit causes full page reload, loses scroll position.
- **Filter form pushes content below fold** — On a 375px viewport, filters occupy ~70% of screen height before any pet is visible.
- **No state persistence** — Interrupted browsing loses scroll position and context.

## Minor Observations
- "✕ Clear" uses an emoji character instead of an SVG icon — DESIGN.md prefers SVGs
- `text-balance` on h1 is good; `text-wrap: pretty` recommended for the subtitle
- Filter chips use color-shift-only hover states with no structural pairing
- "+N" overflow tag uses neutral-100 bg which is low-contrast against white cards
- No `aria-current` on active filter chips
- No `alt` text context beyond pet name — "Photo of [name]" would be better

## Questions to Consider
1. **Is this a product catalog or an emotional discovery experience?** — The page presents pets as items in a grid with structured metadata. Adoption browsing is emotion-led. What if the first thing users see is a pet story or a personality-matching prompt instead of a filter form?

2. **Would you show this page to someone and ask "What's Tovitu's brand?"** — The answer is no, because purple and the Playground character are invisible. If this page can't carry the brand, what page will?

3. **What if there were zero filters and just a Browse button?** — Adopters don't know what size/age/breed they want until they see the pet that makes their heart say yes. What does the page look like when it assumes emotional decision-making?
