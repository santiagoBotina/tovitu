# Plan: Section Explanations — "What is this and why does it matter?" (Item 3.1)

**Domain:** Frontend, Navigation, UX Writing
**Priority:** 2 (Medium)
**Status:** Draft
**Tracks:** Product Improvements §3 (Navigation & User Guidance)

---

## Overview

Users currently have to infer what each major section of the application is for. My Pets, Pets (Explorer), Profile, Adoption Requests, and the shelter sections all render headings with little to no explanation of *what the section is, what you can do there, and why it's useful*.

This plan adds a **brief, visually integrated explanation** to each major section — concise helper copy (not documentation blocks) that tells users what the page is for and what action to take. The goal is reduced confusion, faster orientation, and a gentle nudge toward the primary action on each page.

---

## Current State (confirmed in code)

Per-page headings today:

| Section | View | Current heading treatment |
|---|---|---|
| Explorer (Pets) | `app/views/pets/index.html.erb:6–10` | `title` + generic `subtitle` ("Browse pets" style) |
| My Pets (individual publisher) | `app/views/my/pets/index.html.erb:6–10` | `title` + `subtitle` (short) |
| My Adoption Requests (as adopter) | `app/views/adoption_requests/index.html.erb` | `title` + `subtitle` |
| Incoming Requests (individual publisher) | `app/views/my/adoption_requests/index.html.erb:12–20` | `title` + `subtitle` (counts shown) |
| Profile / Settings | `app/views/authentication/profiles/edit.html.erb` | title + subtitle (settings-oriented) |
| Notifications | `app/views/notifications/index.html.erb:6–9` | `title` + `subtitle` |
| Shelter Dashboard | `app/views/dashboard/index.html.erb:20–37` | welcome title + subtitle (dynamic) |
| Shelter Pets | `app/views/shelter/pets/index.html.erb` | (to confirm) |

Observation: several index pages **already have a short subtitle**. The gap is that these subtitles are generic ("subtitle" keys) rather than explaining *what the section is for, what you can do, and why it's useful*. A few pages (notably `my/pets/index` — "Manage your published pets") already do this well and can serve as the pattern to generalize.

The **sidebar** (`app/views/shared/_sidebar.html.erb`) also has no descriptions at all — only icon + label — which is correct for a nav, but the *landing pages* for each section should carry the explanation.

---

## User Stories

> As a signed-in user,
> I want each major section to briefly explain what it is and what I can do there,
> so that I can orient myself quickly without guessing or clicking around.

> As a new user,
> I want to understand why a section matters (e.g., why my profile completeness affects my matches),
> so that I feel guided rather than lost.

---

## Proposed Changes

### 1. Shared "section header" component

Create `app/views/shared/_section_header.html.erb` (or a presenter/helper + partial) that renders:

- **Title** (existing `h1` treatment: `font-display text-2xl md:text-3xl font-bold text-neutral-900`).
- **One-sentence explanation** (`text-neutral-500/600`, `max-w-2xl`, `text-sm md:text-base`).
- Optional **primary action** slot (the page's main CTA, e.g., "Publish new pet") — many pages already have a right-aligned CTA in a header row; the component can unify this pattern.

Copy guidance (product rule): **one sentence, ≤ 2 lines, action-oriented** — "What this is / what you can do here / why it matters to you." No more than ~20 words. Avoid onboarding-style paragraphs.

### 2. Apply per section (recommended copy drafts — final copy in i18n)

| Section | Explanation (draft, en) |
|---|---|
| Explorer (Pets) | "Browse adoptable pets near you. Use filters to narrow your search and save the ones you love." |
| My Pets | "Pets you've published. Add a new pet, update their story, and manage their adoption status." |
| My Adoption Requests | "Every pet you've applied for, in one place. Track status and follow up when needed." |
| Incoming Requests | "Adoption requests for your pets. Review applicants and decide who meets your pet best." |
| Profile / Settings | "Your account and matching profile. The more complete this is, the better your pet matches." |
| Notifications | "Updates about your requests, messages, and pets — all in one feed." |
| Shelter Dashboard | "Your shelter at a glance: readiness, recent activity, and next steps to get pets adopted." |
| Shelter Pets | "Every pet your shelter manages. Publish new pets and keep profiles up to date." |

Each maps to existing `subtitle` keys where present; if a `subtitle` already exists but is generic, it is **replaced** by the new explanation (not stacked).

### 3. Placement & visual integration

- The explanation sits **directly under the page title**, aligned left (or under the header row), using existing neutral typography — **not** a documentation card, not an info banner.
- Where pages already have a title + subtitle row (e.g., `my/pets/index.html.erb:6–10`), swap the generic subtitle for the new copy in the same position — minimal layout change.
- Respect i18n (en/es): add/update keys under each section's existing namespace (e.g., `my.pets.index.subtitle` replaced or new `my.pets.index.explanation`).

### 4. Out of scope for this item

- Sidebar tooltips/descriptions (nav labels stay compact).
- Empty-state improvements (separate concern; may reference in the same section but not required here).

---

## Acceptance Criteria (3.1)

- **AC-3.1-1** Every primary section listed above renders a one-sentence explanation under its title: Explorer, My Pets, My Adoption Requests, Incoming Requests, Profile/Settings, Notifications, Shelter Dashboard, Shelter Pets.
- **AC-3.1-2** Each explanation states (a) what the section is for and (b) what the user can do there; where relevant (c) why it's useful.
- **AC-3.1-3** Explanations are concise (≤ ~20 words), visually integrated under the title using existing typography — no cards, banners, or documentation blocks.
- **AC-3.1-4** Existing CTAs and layouts are preserved; no regression to header rows on mobile.
- **AC-3.1-5** All copy is i18n'd in en and es.
- **AC-3.1-6** The shared header component (if used) renders title + explanation + optional CTA correctly and is covered by a view spec.

---

## Success Metrics

- 100% of primary sections have a section explanation (audit checklist).
- User confusion signals reduce: proxy = decreased "where do I..." support messages (qualitative); decreased time-to-first-action on section pages (quantitative, if analytics exist — otherwise manual QA review).
- Copy approved by founder/design (tone fits Playground Standard: friendly, bold, never corporate).

## Test Strategy

- **View specs**: `_section_header` partial renders title + explanation; locale fallback works.
- **Manual QA**: walk all primary sections as individual user and shelter user; confirm explanations appear, don't wrap awkwardly, and no layout regressions at mobile widths.
- **i18n check**: all new strings present in en and es.

## Scope

**In scope:** shared section-header component (or standardized inline pattern); one-sentence explanations across the listed sections; i18n keys; replacing generic subtitles where they exist.

**Out of scope:** sidebar/tooltip text; empty-state redesigns; full page header redesign; changing section names in navigation.

## Risks

- Too many strings to maintain — keep copy centralized in i18n and reuse the component everywhere.
- Over-explaining can feel like documentation — enforce the one-sentence rule in review.
- Some pages (e.g., Shelter Dashboard) already have dynamic subtitles; preserve dynamic behavior where useful and only add the explanation when it adds clarity.
