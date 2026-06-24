---
name: Tovitu
description: AI-powered pet adoption platform — playful, bold, and structured
colors:
  primary-50: "#F3EEFF"
  primary-100: "#E5D8FF"
  primary-200: "#CDB5FF"
  primary-300: "#B18CFF"
  primary-400: "#9163FF"
  primary-500: "#6C30FF"
  primary-600: "#5A25E8"
  primary-700: "#4A1CC3"
  primary-800: "#39159A"
  primary-900: "#29106D"
  secondary-50: "#ECFDF5"
  secondary-100: "#D1FAE5"
  secondary-200: "#A7F3D0"
  secondary-300: "#6EE7B7"
  secondary-400: "#34D399"
  secondary-500: "#00C9A7"
  secondary-600: "#059669"
  secondary-700: "#047857"
  secondary-800: "#065F46"
  secondary-900: "#064E3B"
  neutral-50: "#FAFAFC"
  neutral-100: "#F3F4F8"
  neutral-200: "#E7E8EF"
  neutral-300: "#D1D4DD"
  neutral-400: "#A0A6B4"
  neutral-500: "#6B7280"
  neutral-600: "#4B5563"
  neutral-700: "#374151"
  neutral-800: "#1F2937"
  neutral-900: "#111827"
  success: "#00C9A7"
  warning: "#F59E0B"
  danger: "#EF4444"
  info: "#3B82F6"
  logo-pink: "#FF5DA8"
  logo-yellow: "#FFC83D"
  logo-orange: "#FF7A30"
typography:
  display:
    fontFamily: "Baloo 2, system-ui, sans-serif"
    fontSize: "clamp(2rem, 5vw, 3.5rem)"
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: "-0.02em"
  headline:
    fontFamily: "Baloo 2, system-ui, sans-serif"
    fontSize: "clamp(1.5rem, 4vw, 2.5rem)"
    fontWeight: 600
    lineHeight: 1.15
  title:
    fontFamily: "Poppins, sans-serif"
    fontSize: "clamp(1.125rem, 2.5vw, 1.5rem)"
    fontWeight: 600
    lineHeight: 1.3
  body:
    fontFamily: "Poppins, sans-serif"
    fontSize: "1rem"
    fontWeight: 400
    lineHeight: 1.6
    letterSpacing: "normal"
  label:
    fontFamily: "Poppins, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 500
    lineHeight: 1.4
    letterSpacing: "0.02em"
rounded:
  sm: "8px"
  md: "12px"
  lg: "16px"
  xl: "24px"
  full: "9999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "32px"
  2xl: "48px"
components:
  button-primary:
    backgroundColor: "{colors.primary-500}"
    textColor: "#ffffff"
    rounded: "{rounded.xl}"
    padding: "12px 24px"
    typography: "{typography.label}"
  button-primary-hover:
    backgroundColor: "{colors.primary-600}"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.primary-600}"
    rounded: "{rounded.xl}"
    padding: "8px 16px"
  input:
    backgroundColor: "#ffffff"
    textColor: "{colors.neutral-800}"
    rounded: "{rounded.xl}"
    padding: "12px 16px"
    typography: "{typography.body}"
  card:
    backgroundColor: "#ffffff"
    textColor: "{colors.neutral-800}"
    rounded: "{rounded.xl}"
    padding: "24px"
  chip:
    backgroundColor: "{colors.neutral-100}"
    textColor: "{colors.neutral-600}"
    rounded: "{rounded.full}"
    padding: "4px 12px"
  nav-link:
    textColor: "{colors.neutral-500}"
    typography: "{typography.label}"
  nav-link-active:
    backgroundColor: "{colors.primary-50}"
    textColor: "{colors.primary-700}"
    rounded: "{rounded.xl}"
---

# Design System: Tovitu

## 1. Overview

**Creative North Star: "The Playground Standard"**

Tovitu's visual system is a refined take on the neubrutalism aesthetic — bold without being raw, playful without being childish. Every interface feels like a well-designed playground: clear boundaries, generous proportions, and a confident sense of joy. The purple primary (oklch(0.53 0.31 280)) anchors the system with warmth and energy; the teal secondary (oklch(0.72 0.21 175)) brings balance and calm. Together they create a palette that is unmistakably pet-adoption — lively, trustworthy, and approachable.

The system explicitly rejects the corporate SaaS vocabulary: muted creams, glass cards, gradient text, and uniform card grids. Instead, surfaces are flat at rest with bold borders, oversized interactive targets, and color that carries the emotional weight. Rounded corners are generous but intentional — they soften the neubrutalist edges without blunting them. Shadows are present but restrained, adding depth without diffuse glow.

**Key Characteristics:**
- Bold, saturated primary and secondary colors as the dominant visual drivers
- Generous white space and oversized interactive targets for confidence and accessibility
- Flat surfaces at rest; structure comes from borders and color blocks, not shadows
- Rounded corners as the softening agent against the bold color and thick borders
- Playful typography hierarchy: a round display face (Baloo 2) paired with a clean geometric body (Poppins)
- Maximum one decorative element per screen; everything else earns its place through function

## 2. Colors

The palette is warm, bold, and purposeful. Purple carries energy and trust; teal carries calm and growth. Neutrals are slightly cool to balance the warmth of the accents.

### Primary
- **Playful Purple** (#6C30FF / oklch(0.53 0.31 280)): The anchor. Used for primary actions, navigation accents, selected states, and the logo. This is the Tovitu color — it appears on every screen but rarely covers more than 15% of the surface.
- **Purple scale** (50–900): Full tonal range from whisper-lavender (oklch(0.92 0.08 280)) to deep aubergine (oklch(0.28 0.14 280)). The mid tones (400–600) carry interaction; the lights (50–200) carry background containers; the darks (700–900) carry emphasis and depth.

### Secondary
- **Tide Teal** (#00C9A7 / oklch(0.72 0.21 175)): The complement. Used for secondary actions, active filters, personality tags, and status indicators. Teal appears where purple would be too heavy — it's the calm counterpart.
- **Teal scale** (50–900): Full tonal range from whisper-mint (oklch(0.95 0.04 170)) to deep forest (oklch(0.30 0.08 170)). The 500 is intentionally bright; it needs to hold its own against purple.

### Neutral
- **Cool Slate** (#FAFAFC → #111827 / oklch(0.98 0.003 260 → oklch(0.20 0.01 260))): The structural skeleton. Cool-leaning to balance the warm purple. 50 and 100 are background surfaces; 200 and 300 are borders and dividers; 500–600 are body text; 800–900 are headings and high-emphasis content.
- **The Contrast Rule.** Body text always sits at neutral-700 (#374151, oklch(0.38 0.02 260)) or darker. No light gray body text on tinted backgrounds — the 4.5:1 WCAG AA floor is non-negotiable.

### Semantic
- **Success:** Tide Teal (#00C9A7)
- **Warning:** Amber (#F59E0B)
- **Danger:** Alert Red (#EF4444)
- **Info:** Blue (#3B82F6)

### Named Rules
**The Playground Scale Rule.** Color covers large, deliberate areas — never decorative strips or accent borders. If a card needs emphasis, use a full background tint (primary-50), not a 3px left border. If a button needs attention, make it full-bleed primary-500, not an outlined ghost with a purple stroke. Color is for surfaces, not for stripes.

**The Bold-But-Not-Raw Rule.** Neubrutalism in this system means saturated, confident color — not jarring, clashing, or deliberately ugly. Purple and teal coexist because they're complementary, not because they fight. Push saturation until the color has presence, then stop one step before it shouts.

## 3. Typography

**Display Font:** Baloo 2 (with system-ui fallback)
**Body Font:** Poppins (with sans-serif fallback)

**Character:** A round, exuberant display face paired with a clean, approachable geometric sans. Baloo 2 brings the playground energy — its bubbly letterforms make headlines feel joyfully oversized. Poppins provides the calm, readable counterpoint for body text, labels, and navigation. The pairing works because they share a friendly, open character while contrasting in shape language (round vs. geometric).

### Hierarchy
- **Display** (700 Bold, clamp(2rem, 5vw, 3.5rem), 1.1): Hero headlines, page titles, the logo. `text-wrap: balance` required. Maximum clamp ceiling of 4rem (64px).
- **Headline** (600 Semibold, clamp(1.5rem, 4vw, 2.5rem), 1.15): Section headings, modal titles, dashboard welcome. `text-wrap: balance` preferred.
- **Title** (600 Semibold, clamp(1.125rem, 2.5vw, 1.5rem), 1.3): Card titles, feature names, list item headings.
- **Body** (400 Regular, 1rem, 1.6): Primary reading text. Line length capped at 70ch. `text-wrap: pretty` to reduce orphans.
- **Label** (500 Medium, 0.875rem, 1.4, 0.02em letter-spacing): Form labels, nav items, button text, metadata.

### Named Rules
**The Single-Family Display Rule.** Headlines use Baloo 2 exclusively, not Poppins bolded up. Poppins at large sizes loses its character; Baloo 2 at large sizes becomes energetic. Never use Poppins at display scale.

**The Generous Leading Rule.** Body text line-height is 1.6 minimum. In the playground, nothing is cramped. Every line of text has room to breathe.

## 4. Elevation

The system is predominantly flat. Depth comes from structural color and borders, not from simulated height. Shadows are used sparingly — only where an element genuinely sits above the page (modals, toasts, dropdowns, hover states on interactive cards). At rest, every surface is flat.

### Shadow Vocabulary
- **Card Hover** (`box-shadow: 0 4px 16px rgba(108, 48, 255, 0.08)`): Subtle purple-tinted elevation for interactive cards on hover. Low blur, low opacity — present but not diffuse.
- **Modal / Dropdown** (`box-shadow: 0 8px 32px rgba(108, 48, 255, 0.10)`): Deeper elevation for elements that break out of the page stack. Noticeable but still sharp — the purple tint maintains brand connection.
- **Toast / Flash** (`box-shadow: 0 8px 32px rgba(0, 0, 0, 0.15)`): Neutral shadow for notifications. Higher contrast for visibility against any background.

### Named Rules
**The No-Blur-By-Default Rule.** Backdrop blur is reserved for the navbar only. No glass cards, no frosted panels, no translucent overlays beyond the navigation. Clarity beats atmosphere.

## 5. Components

### Buttons
- **Shape:** Generously rounded (rounded-xl, 12px)
- **Primary:** Full-bleed primary-500 background, white text, 12px 24px padding, font-semibold, shadow-sm. Hover shifts to primary-600. Active scales to 0.97 (`active:scale-[0.98]` pattern used throughout). The large pill-like shape makes taps unambiguous.
- **Ghost / Text:** Transparent background, primary-600 text, hover reveals primary-50 background. Used for secondary actions that shouldn't compete with the primary CTA.
- **Filter Chips:** Rounded-full (9999px), 8px 16px padding, border with neutral-300. Active state fills with secondary-500 background and white text. The full pill shape signals toggleable state.

### Inputs / Fields
- **Shape:** rounded-xl (12px) with 1px neutral-300 border.
- **Resting:** White background, neutral-300 border, shadow-sm for subtle depth. Placeholder at neutral-400 (passes 4.5:1 contrast).
- **Focus:** 2px primary-500 ring replaces the border. The ring is the focus indicator — no outline, no border shift. Clear and unmistakable.
- **Error / Disabled:** Error state uses danger border and ring. Disabled uses neutral-100 background with neutral-300 text at 50% opacity.

### Cards / Containers
- **Corner Style:** rounded-xl (12px) or rounded-lg (16px) for larger cards.
- **Background:** White with 1px neutral-200 border and shadow-sm.
- **Hover:** border shifts to the relevant accent (primary-100 for shelter cards, secondary-200 for pet cards), shadow increases to shadow-md, optional translateY(-1px) for physicality.
- **Internal Padding:** 24px standard, 20px for compact variants.

### Navigation
- **Navbar:** Fixed top, white with 80% opacity and backdrop-blur-md. Border-b neutral-200. 64px height. Logo sits left with the multi-color Tovitu wordmark. Auth links right — ghost button (Sign in) and primary button (Create account).
- **Sidebar:** Fixed left, full height, white background, border-r neutral-200. Desktop collapses to 64px icon-only mode; expands to 256px with labels. Mobile is a full-width overlay. Selected state uses primary-50 background with primary-700 text. Hover uses neutral-50 background.
- **Footer:** Minimal, centered, neutral-400 text, border-t neutral-100. Links to Privacy and Terms.

### Chips / Tags
- **Style:** Rounded-full, tight padding (4px 10px), text-xs font-medium.
- **Personality tags:** secondary-50 background, secondary-600 text for pet personality traits.
- **Species tags:** primary-50 background, primary-600 text for shelter species badges.
- **Status indicators:** Filled variant with a colored dot (secondary-500 for Active, etc.).

### Flash / Toast
- **Position:** Fixed top-right. Stack vertically with gap-3.
- **Background:** Solid semantic color (success, danger, warning, or primary-500).
- **Text:** White, text-sm font-medium. Close button top-right.

## 6. Do's and Don'ts

### Do:
- **Do** use full-surface color blocks for emphasis — tinted backgrounds (primary-50, secondary-50), not side-stripe borders.
- **Do** make interactive targets generous — minimum 44px tap target, preferably larger. The playground is for everyone.
- **Do** use the multi-color logo as a signature element. The per-letter coloring (purple, teal, pink, yellow, orange, purple) is the one decorative flourish the system allows.
- **Do** keep body text at neutral-700 or darker for legibility. Test every background/text pair for 4.5:1 WCAG AA contrast.
- **Do** use flat surfaces at rest. Elevation is a response to interaction, not a default state.
- **Do** balance playful with structured. Bold color needs generous white space around it to breathe.
- **Do** pair Baloo 2 (display) with Poppins (body). Never swap or substitute one for the other's role.

### Don't:
- **Don't** use glassmorphism, backdrop blur (outside the navbar), or translucent card backgrounds. Clarity beats atmosphere.
- **Don't** use side-stripe borders (border-left/right > 1px as a colored accent). Use full background tints instead.
- **Don't** use gradient text or gradient backgrounds. Solid, flat color only.
- **Don't** create identical card grids with icon + heading + body. Vary card content and layout to avoid the template reflex.
- **Don't** use the SaaS hero-metric template (big number, small label, supporting stats). Tovitu is not a dashboard for metrics.
- **Don't** use numbered section markers (01 / 02 / 03) as default scaffolding above every section.
- **Don't** use tiny uppercase tracked eyebrows ("ABOUT" / "PROCESS" / "PRICING") as section kickers. Choose a different cadence.
- **Don't** make the interface feel corporate, serious, or B2B. No navy suits, no muted professionalism.
- **Don't** overflow headings on narrow viewports. Test heading copy at every breakpoint; reduce clamp max or rewrite copy if it wraps awkwardly.
- **Don't** override the spacing scale with arbitrary values. Use the defined spacing tokens (xs through 2xl).
