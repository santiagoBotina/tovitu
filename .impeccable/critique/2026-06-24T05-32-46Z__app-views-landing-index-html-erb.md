---
target: landing page
total_score: 22
p0_count: 0
p1_count: 1
p2_count: 3
timestamp: 2026-06-24T05-32-46Z
slug: app-views-landing-index-html-erb
---
## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 2 | Cards look like content choices but navigate to login — no feedback that navigation is happening |
| 2 | Match System / Real World | 3 | Plain language throughout; "I represent a shelter" is natural |
| 3 | User Control and Freedom | 3 | Skip link present, keyboard nav works |
| 4 | Consistency and Standards | 2 | Landing uses gradients/blur/glass while DESIGN.md bans them; feels like a different system |
| 5 | Error Prevention | 3 | Limited error opportunity on a static landing |
| 6 | Recognition Rather Than Recall | 2 | No imagery to anchor the product purpose; copy is category-generic |
| 7 | Flexibility and Efficiency | 1 | No shortcuts or alternative paths; appropriate for landing scope |
| 8 | Aesthetic and Minimalist Design | 2 | Decorative gradients, blurred circles, glass cards create visual noise against the intended direction |
| 9 | Help and Documentation | 1 | No onboarding, no tooltips, no contextual guidance |
| 10 | Error Recovery | 3 | Low-risk surface; links route properly where wired |
| **Total** | | **22/40** | **Acceptable** |

## Anti-Patterns Verdict

**LLM assessment**: The landing page does not look AI-generated in the conventional sense (it doesn't have the typical hero-metric template or editorial-typographic lane). However, it looks like a **2023 Bootstrap-era app landing** — the soft gradients, blurred decorative circles, glass-effect cards, and gradient icon containers are the opposite of the Playground Standard direction established in DESIGN.md. The design contradicts the system it belongs to.

**Deterministic scan**: Clean. The detector found no flagged patterns (no gradient text, no side-stripe borders, no numbered section markers). This means the anti-patterns are stylistic and structural, not the specific detectable patterns.

## Overall Impression

The landing page does its job as a minimum-viable gateway: two clear paths, a recognizable logo, low friction. But it's the **product-in-the-sky problem** — a landing for a pet adoption platform with zero pets, zero imagery, and generic copy. The visual direction (soft, gradient-heavy, glass-muted) is the exact opposite of the Playground Standard the DESIGN.md just defined. This page needs to be rebuilt from the ground up to match where the product is going, not polished within its current constraints.

## What's Working

- **Multi-color logo.** The per-letter coloring is the one decorative flourish the system allows, and it's used well here. It's memorable and distinctive.
- **Clear dual-path funnel.** The adopter/shelter split is the right decision for a two-sided platform, and the two-card layout makes the choice immediate.
- **Typography pairing.** Baloo 2 + Poppins is exactly right per the design system. The display scale is appropriate.

## Priority Issues

- **[P1] Design system contradiction.** The landing uses gradients (bg-gradient-to-b), blur effects (blur-3xl, backdrop-blur-sm), glass cards (bg-white/90 backdrop-blur-sm), and gradient icon containers. All are explicitly banned by DESIGN.md's rules: "The No-Blur-By-Default Rule," "Solid, flat color only," and "No glass cards, no frosted panels." The landing needs a full rebuild aligned with the Playground Standard.
  - **Why it matters**: Every visitor sees this page first. If the landing doesn't match the brand, the brand doesn't exist yet.
  - **Fix**: Strip all gradients, blur, and glass. Replace with flat color surfaces, bold borders, and the saturated purple/teal palette at scale.
  - **Suggested command**: `/impeccable craft landing`

- **[P2] Zero pet imagery.** A pet adoption platform with no animal photos is the most obvious missed opportunity. The hero section has blobs and gradients where a featured pet or adoption moment should be.
  - **Why it matters**: Adoption is emotional. Imagery creates the connection that copy alone can't. Without it, the page feels like a generic app sign-in, not a pet platform.
  - **Fix**: Add a featured pet hero, shelter photo grid, or life-preview teaser as the visual anchor.
  - **Suggested command**: `/impeccable craft landing`

- **[P2] Generic copy.** "Find Your Perfect Companion" and "Tovitu helps pets find loving homes through thoughtful matching" could be any pet platform. The AI matching and life preview features are the differentiator but aren't communicated.
  - **Why it matters**: Users scanning the page in 3 seconds should know what makes this different. Currently they can't.
  - **Fix**: Lead with the AI matching angle. Something like "AI that finds the pet meant for you" or the specific value prop.
  - **Suggested command**: `/impeccable clarify landing`

- **[P2] Identical card grid.** Two same-sized, same-structured cards with icon + heading + body is the exact "identical card grids" anti-pattern from DESIGN.md. The adopter and shelter paths are different audiences with different priorities; they should look distinct.
  - **Why it matters**: Reduces information scent — both options look equally weighted, which doesn't help the user decide.
  - **Fix**: Visually differentiate the two paths. The shelter path could be more compact, the adopter path more prominent. Or use different layouts entirely.
  - **Suggested command**: `/impeccable layout landing`

- **[P3] "Create account" links to root_path.** A broken flow on the primary CTA button. Unauthenticated users see "Create account" but clicking it just reloads the landing. This is a stub.
  - **Why it matters**: Destroys trust immediately for new users.
  - **Fix**: Wire to `new_registration_path`.
  - **Suggested command**: `/impeccable harden landing`

## Persona Red Flags

**Jordan (First-Timer)**:
- No pet imagery to create emotional buy-in. Jordan scans for "is this for me?" and sees a logo and two cards. No photos, no warmth.
- Generic headline doesn't explain what the product actually does differently. Jordan needs a hook.
- "Create account" leading to a broken link (root_path) would immediately lose trust.

**Casey (Distracted Mobile User)**:
- Hero takes the full viewport on mobile. Casey has to scroll to see the actual call-to-action. The CTA should appear above the fold.
- Language switcher is at bottom-right in a floating pill — hard to reach one-handed. Not a critical issue but a quality-of-life miss.

**Riley (Stress Tester)**:
- Privacy Policy and Terms links go to "#" — dead links.
- "Create account" goes to root_path — broken CTA.
- No empty states or error boundaries to test (it's a static page, which is defensible, but the broken links are genuine failures).

**Pat (Adopter — project-specific)**:
- Pat is excited about adopting a pet but cautious. They land on a page with no pets, no photos, no sense of the animals waiting for them. The abstract copy gives them no reason to stay.
- The AI life preview feature is the most exciting differentiator for an adopter, but it's never mentioned. Pat doesn't know this platform can show them what adopting a specific pet would look like.

**Morgan (Shelter Manager — project-specific)**:
- Morgan is evaluating whether Tovitu is better than their current process. They scan for: pet management, application workflow, communication tools. The landing doesn't mention any of these.
- The shelter path "Manage adoptions and connect with adopters" is the only hint. Morgan needs more substance to justify a sign-up.

## Minor Observations

- "Privacy Policy" and "Terms of Service" link to "#" in the footer. Needs real routes.
- The noise texture overlay (`background-image` with feTurbulence) in the layout is a subtle decorative element but adds to the overall visual busyness — consider removing for clarity.
- Language switcher positioned in a floating pill bottom-right is a nice touch but would benefit from being integrated into the navigation for discoverability.
- Body text on the landing uses `text-neutral-500` (#6B7280) which passes 4.5:1 against neutral-50 but is close to the floor. For the Playground Standard, bolder body color would be more confident.

## Questions to Consider

- What if the landing hero showed a featured adoptable pet instead of decorative blurs? The emotional delta is massive.
- What if the two audience paths didn't look identical but reflected the different experiences (adopter = browsing warmth, shelter = utility/management)?
- What if the landing communicated the AI differentiator in the first 3 seconds instead of burying it?
