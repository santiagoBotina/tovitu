# Plan: Pet Discovery — Natural Language Search & Expanded Pet Types (REQ-10, REQ-11)

**Domain:** Discovery, Search, AI, Pet Model
**Priority:** 1 (High)
**Status:** Draft
**Tracks:** Epic "Descubrimiento" (REQ-10, REQ-11)

---

## Overview

Discovery is where Tovitu's promise ("the right pet for the right person") lives. Two gaps limit it today:

1. Search is **structured-filter only** (species chips, age/size/sex dropdowns, keyword query). Users cannot express what they actually want in a sentence ("Quiero un perro tranquilo que pueda vivir en apartamento").
2. Pet types are limited to `dog`, `cat`, `other`. Birds, rabbits, hamsters, and other common pets can't be represented, searched, filtered, or given species-appropriate AI care content.

This plan delivers natural language search as a first-class, visually prominent capability and expands the pet type model with proper emoji, filters, shelter selection, profile display, and species-aware AI Life Preview.

> This is the largest-scope plan in this batch. The Spec agent should split implementation into two tracks: **REQ-10 (search)** and **REQ-11 (pet types)**, deliverable independently.

---

## Current State (confirmed in code)

- **Browse page (`pets/index.html.erb`):** a filters card with species chips (`dog`, `cat`, `other` hardcoded iteration), a `query` text field, and age/size/sex selects; results via the existing search service. There is no natural-language input and no loading/empty state specific to intent-based search.
- **Species model:** `Pet::SPECIES = %w[dog cat other]` enum; species labels localized under `pets.species.*`; filter chips hardcoded to that list.
- **AI Life Preview:** currently species-aware only at the `dog`/`cat`/`other` level (generic content for "other"), which risks generic dog/cat advice for non-dog/cat pets — exactly what REQ-11 forbids.
- **Shelter registration:** the pet form includes a species field with the three current options.

---

## User Stories

> As a would-be adopter,
> I want to describe the pet I'm looking for in my own words,
> so that Tovitu shows me pets that actually fit my life — not just pets that match a keyword.

> As someone looking for a rabbit, bird, or hamster,
> I want to search and filter for my pet type and see advice that's specific to that species,
> so that I can make an informed decision instead of guessing from dog-and-cat content.

---

## Requirements & Proposed Behavior

### REQ-10 — Natural language pet search

A new, visually prominent search field accepts a full sentence:

1. A dedicated natural-language search field exists on the browse experience.
2. The placeholder includes a short example that teaches the pattern (e.g., "Describe tu compañero ideal… Ej.: un perro tranquilo para departamento").
3. The feature is visually distinct so users discover it (not hidden inside the filter card).
4. Users can express multiple characteristics in one phrase (species + temperament + living situation + energy level…).
5. The **full phrase** is used as context — not isolated keywords — so intent is preserved.
6. Results prioritize pets compatible with the expressed intent (relevance ordering, not just hard filtering).
7. A clear loading state exists while the search is processed.
8. A clear empty state exists when no results match.
9. The feature stays true to Tovitu's principle: helping users make an **informed decision**, not just running a marketplace query.

**User flow:**
`Browse pets → natural-language field ("Quiero un perro tranquilo que pueda vivir en apartamento") → submit → loading state → ranked results (with visible reason/context) → (no matches) helpful empty state with suggestions`

**Edge cases:**
- Ambiguous or contradictory phrases ("un perro grande pero chiquito") → no crash; results are best-effort, and the UI can show what Tovitu understood.
- Empty / gibberish input → falls back to regular browse or a friendly prompt; no technical error.
- Mixed-language phrases → handled gracefully in the user's active locale where possible.
- Very long phrases → truncated/validated with a friendly message, never an error page.
- Result reasons: users should understand **why** a pet ranked (e.g., "matches: apartment-friendly, calm") to keep the decision informed and trust high.
- Combining natural-language search with the existing structured filters → both can coexist; defined precedence (filters constrain, NL search ranks within the constraint set).

### REQ-11 — Support more pet types

Expand the species model beyond `dog` / `cat` / `other`:

- Initial new categories: **birds (aves)**, **rabbits (conejos)**, **hamsters (hámsters)**, plus a well-defined "other common pets" bucket.
- Each category has its own **emoji**.
- Categories are usable in **search and filters** (chips/dropdowns iterate the full list, not a hardcoded trio).
- Shelters/individual publishers can **select** the category when registering a pet.
- The category renders correctly on the **pet profile** and cards.
- The **AI Life Preview recognizes** the pet type and adapts recommendations accordingly.
- Each type has **species-specific care information**; no generic dog/cat content is used for other species.

**Edge cases:**
- Legacy data: pets already stored as `other` must not break; the expansion must define migration/remapping behavior for existing `other` pets (do we leave them as `other`? let users re-classify? — product decision to confirm with founder).
- Unknown/misclassified species: a clear "other" fallback that still avoids dog/cat-generic AI content (e.g., asks the shelter for more detail or uses neutral care guidance).
- Filter chips row overflow with more species → responsive treatment (wrap or horizontal scroll) without breaking layout (coordinate with plan 39 polish conventions).
- The `other` category's emoji must be generic enough to not mislead.
- Care-content gaps: if species-specific content doesn't exist yet, the Life Preview must degrade honestly (ask the shelter for specifics) rather than fabricate.

---

## Acceptance Criteria

- **AC-36-1 (REQ-10)** — A natural-language search field exists and is visually prominent on the browse experience.
- **AC-36-2 (REQ-10)** — The placeholder includes a short example of how to use it.
- **AC-36-3 (REQ-10)** — The user can express multiple characteristics in one phrase; the full phrase is used as context (verifiable: two phrases sharing a keyword return different rankings when intent differs).
- **AC-36-4 (REQ-10)** — Results prioritize pets compatible with the expressed intent (relevance ordering).
- **AC-36-5 (REQ-10)** — A loading state is shown while the search is processed.
- **AC-36-6 (REQ-10)** — An appropriate empty state appears when there are no results.
- **AC-36-7 (REQ-10)** — Users see why pets were recommended (result reason/context) to keep decisions informed.
- **AC-36-8 (REQ-10)** — Invalid/empty/ambiguous input degrades gracefully (no technical errors).
- **AC-36-9 (REQ-11)** — The system supports multiple pet categories: dogs, cats, birds, rabbits, hamsters, and other common pets.
- **AC-36-10 (REQ-11)** — Every category has its own emoji, shown consistently (cards, profile, filters).
- **AC-36-11 (REQ-11)** — Categories are usable in search and filters (no hardcoded species trio remains in the browse UI).
- **AC-36-12 (REQ-11)** — Shelters/publishers can select any category when registering a pet.
- **AC-36-13 (REQ-11)** — The category displays correctly on the pet profile and cards.
- **AC-36-14 (REQ-11)** — The AI Life Preview recognizes the pet type and adapts its care recommendations per species.
- **AC-36-15 (REQ-11)** — No generic dog/cat content is served for other species (spot-check bird/rabbit/hamster previews).
- **AC-36-16 (REQ-11)** — Existing `other` pets remain intact and displayable after the expansion (no broken records).
- **AC-36-17** — All new strings localized (en/es); WCAG AA; new filter controls are keyboard accessible.

---

## Success Metrics

- **Search satisfaction**: share of natural-language searches that produce a save or application within the session (target: >= keyword-search baseline).
- **NL search adoption**: % of browse sessions that use the natural-language field within the first weeks (target: meaningful usage; used to validate the founder's hypothesis).
- **Pet-type coverage**: % of published pets that are non-dog/cat and correctly categorized.
- **AI quality**: sampled Life Previews for birds/rabbits/hamsters contain no dog/cat-generic advice (manual QA, 100% pass gate).
- **Friction**: no increase in browse bounce or filter-card abandonment.

---

## Test Strategy

- **Search service specs**: phrase-to-intent extraction, relevance ordering, phrase + filter interaction, empty/ambiguous inputs.
- **Model/request specs**: new species values valid in forms, filters, and profiles; legacy `other` pets render; migration behavior.
- **AI specs**: Life Preview prompt includes species context; species-specific care guidance; degradation path when content missing.
- **Manual QA**: NL search in both locales with real phrases; bird/rabbit/hamster registration → profile → Life Preview journey; filter chips responsive behavior.

---

## Scope

**In scope:** natural-language search field + processing + ranked results + loading/empty/reason states; species model expansion (birds, rabbits, hamsters, other-common); emoji; filters; shelter/publisher registration options; pet profile display; AI Life Preview species awareness + species-specific care guidance.

**Out of scope:** Full semantic-search infrastructure beyond the MVP approach (Spec agent to define the pragmatic mechanism — likely AI-assisted intent extraction over the existing search service); breed auto-detection; species-specific onboarding questions; new content authoring tools for shelters; mobile app work.

---

## Risks

- **NL search cost/latency** — AI-assisted intent extraction adds cost and latency per query; mitigation: lightweight processing, caching, and clear loading states; consider batching or async for expensive paths.
- **Relevance quality** — bad relevance erodes trust; mitigation: transparent "why this pet" reasons, empty-state suggestions, and a founder review gate on sample queries.
- **Species model churn** — expanding an enum touches forms, filters, AI prompts, and locale keys; mitigation: ship REQ-11 as its own track with explicit migration/legacy handling.
- **AI generic-content leakage** — the biggest trust risk of REQ-11; mitigation: species context in the prompt + degradation path (ask shelter) + QA gate.
- **Scope creep** — this plan is intentionally large; tracks must be implemented and reviewed independently.

---

## Dependencies

- **Depends on plan 33** (localization) for new strings and the AI locale context pattern (REQ-03) that REQ-11's species-aware previews extend.
- **Depends on plan 35** (favorites) so discovery results can be saved immediately.
- **Precedes** plan 37 (engagement): the journey card and shelter recommendation sections will reference categories/discovery.
- Plan 38 (shelter management) reuses the expanded species list in batch import (REQ-15).