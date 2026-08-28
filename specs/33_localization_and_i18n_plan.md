# Plan: Localization & Internationalization (REQ-01, REQ-02, REQ-03)

**Domain:** i18n, Frontend, AI
**Priority:** 1 (High) — foundation for all other work
**Status:** Draft
**Tracks:** Epic "Internacionalización" (REQ-01, REQ-02, REQ-03)

---

## Overview

Tovitu is a bilingual product (Spanish/English) but the user-visible experience is not yet consistently localized. Three gaps are confirmed:

1. The **pet age badge** renders a hardcoded English "years" even when the app is in Spanish.
2. The **authentication screens** (login/sign-up) still contain hardcoded English copy and unlocalized validation/error messages.
3. The **AI Life Preview** can return English content even when the user's locale is Spanish.

This plan is the i18n foundation. It is **first in the implementation order** because the authentication redesign (plan 34), AI content work (plan 36), and pet UI polish all build on top of a fully localized string layer.

---

## Current State (confirmed in code)

- **Age badge:** Pet cards and the saved-pets page render `pet.age_display`. When a pet has a birth date, the presenter composes `"#{category} (#{age} years)"` where the word "years" comes from an English pluralization helper (`'year'.pluralize(age)`), **not** from the locale files. Result: Spanish users see "Adulto (5 years)".
- **Auth screens:** The session/registration views mostly use `t()` keys already (`authentication.sessions.new_individual.title`, etc.), but the flow is incomplete: some auth-related screens and copy still hardcode English ("Welcome back", "Sign in to continue your adoption journey", input placeholders), and validation/error messages are not consistently localized. The audit must cover sessions (individual/shelter/adopter forms), registrations (new + check_email), verifications, password reset, the welcome overlay, and shared auth partials.
- **AI Life Preview:** The generator (`Ai::GenerateLifePreview`) builds a prompt from pet data plus a prompt template in `config/prompts/life_preview.yml`. No user locale is passed as context, so the model decides the output language on its own — typically English regardless of the user's preference.
- **Locale infrastructure:** `config/locales/en.yml` + `es.yml` (~1,096 lines each) plus domain subfolders (`adoptions/`, `pets/`, `notifications/`) already exist. The `language_select` Stimulus controller and `params[:locale]` plumbing are in place.

---

## User Stories

> As a Spanish-speaking adopter,
> I want every piece of Tovitu — badges, forms, and AI-generated previews — to appear in Spanish,
> so that I can make adoption decisions confidently without translating the app myself.

> As a shelter user,
> I want my language choice to be respected consistently across the platform,
> so that my team and I can work in the language we actually use.

---

## Requirements & Proposed Behavior

### REQ-01 — Internationalize the pet age badge

The age badge must render the age **unit** from the active locale:

- Spanish: `años` — e.g., "Adulto (5 años)"
- English: `years` — e.g., "Adult (5 years)"
- The numeric value must not change.
- No hardcoded age-unit strings anywhere in views, presenters, or helpers.
- Consistency across **every** surface where a pet's age appears: pet cards on the browse page, saved pets, dashboard matches, pet profile, life preview summaries, shelter pet lists.

**Edge cases:**
- Pets without a birth date (only an age category): unchanged behavior, category label already localized — verify.
- Age of 1: singular/plural handled by the locale (`1 year` vs `2 years`; `1 año` vs `2 años`).
- Locale switching mid-session must update the badge without requiring a cache flush or hard reload.

### REQ-02 — Internationalize Login and Sign Up

All authentication screens must be fully localized:

- Every visible string (headings, subtitles, labels, placeholders, buttons, prompts, links).
- Validation and error messages (including server-side and model-level messages shown in the auth forms).
- The locale chosen by the user (via locale selector / URL / stored preference) must drive the screen language.
- Copy must keep Tovitu's voice: clear, empathetic, accessible — **not** machine-y or corporate.

**Edge cases:**
- Devise/Rails default validation messages must not leak English into the forms.
- Errors from the authentication service objects (`Lib::Authentication::*`) must surface localized messages.
- Browser autofill text is out of scope (browser-controlled), but all placeholder text we render must be localized.
- Accessibility attributes (`aria-label`, `title`) count as user-visible strings and must be localized too.

### REQ-03 — Localize the AI Life Preview

The AI Life Preview must generate content in the user's language:

- Spanish user → Spanish output (titles, descriptions, recommendations, tips, plan weeks, itinerary).
- English user → English output.
- No mixed-language fragments in a single preview.
- The user's locale must be passed as context to the generation process.
- The output must be correct **regardless of the language of the shelter's original pet description** (e.g., a Spanish shelter writing English notes must still get a Spanish preview for a Spanish user).

**Edge cases:**
- Locale is not available or is an unsupported value → fall back to a sensible default and never fail the generation.
- Content that is hard to localize (proper names, breed names, medical terms) must remain faithful, not literally mistranslated.
- Cached previews: a preview generated for locale A should not be served to a user in locale B. The plan must define staleness/regeneration behavior when the user's locale differs from the cached preview's locale.
- AI generation failures keep the existing error state; locale must never be the cause of a generation failure.

---

## Acceptance Criteria

- **AC-33-1 (REQ-01)** — With locale `es`, the age badge shows `años` (e.g., "Adulto (5 años)"); with locale `en`, it shows `years` ("Adult (5 years)"). The numeric age is identical in both.
- **AC-33-2 (REQ-01)** — No hardcoded age-unit strings remain anywhere in the codebase (grep check on views/presenters/helpers).
- **AC-33-3 (REQ-01)** — The age badge renders correctly in at least: browse page pet cards, saved pets, dashboard matches, pet profile, and shelter pet management lists.
- **AC-33-4 (REQ-02)** — Every visible string on Login is localized; no English hardcoded text remains on the Login flow (all role variants).
- **AC-33-5 (REQ-02)** — Every visible string on Sign Up is localized; no English hardcoded text remains (individual + shelter variants, incl. the post-submit "check your email" screen).
- **AC-33-6 (REQ-02)** — Validation and error messages shown in the auth flow are localized in both `es` and `en`.
- **AC-33-7 (REQ-02)** — The screen language follows the user's selected locale; switching locale changes the auth screens without a hard reload.
- **AC-33-8 (REQ-02)** — Copy review passes: auth strings keep Tovitu's clear, empathetic, accessible tone in both languages.
- **AC-33-9 (REQ-03)** — With user locale `es`, the generated Life Preview (titles, descriptions, recommendations, tips) is entirely in Spanish.
- **AC-33-10 (REQ-03)** — With user locale `en`, the generated Life Preview is entirely in English.
- **AC-33-11 (REQ-03)** — The locale is passed as context to the Life Preview generation process (verifiable in code review).
- **AC-33-12 (REQ-03)** — No mixed-language fragments appear in generated previews (manual + automated spot checks).
- **AC-33-13 (REQ-03)** — A Spanish-locale user still receives a Spanish preview when the shelter's original pet content is in English (and vice versa).
- **AC-33-14 (REQ-03)** — Cached previews do not leak across locales: a preview generated for `es` is not shown to an `en` user without regeneration.
- **AC-33-15** — All new strings are in `config/locales/{en,es}.yml` (en/es parity, no key drift); accessibility attributes localized; WCAG AA contrast preserved.

---

## Success Metrics

- **Zero hardcoded strings** in the touched surfaces (enforced by grep/lint or review checklist).
- **en/es key parity**: no locale file drift (automated check).
- **Language match rate for AI Life Preview**: ≥ 95% of sampled previews match the user's locale (manual QA sampling of 20 previews per locale).
- **No regression** in login/sign-up completion (conversion holds vs. baseline).
- **Support load**: no new "why is this in English" reports.

---

## Test Strategy

- **i18n parity specs**: every key used in the touched views exists in both `en.yml` and `es.yml`.
- **View/request specs** for the age badge across all surfaces (both locales, pets with and without birth date).
- **Auth flow specs** in both locales covering validation errors and success paths.
- **Service-level specs** for AI Life Preview: locale context passed, output parsed, error paths preserved.
- **Manual QA checklist**: full auth journey in `es` and `en`; Life Preview generation in both locales incl. mixed-language shelter input.

---

## Scope

**In scope:** age badge localization; auth screen copy + validation/error localization; AI Life Preview locale context + output language; locale-key parity maintenance.

**Out of scope:** New UI for a locale switcher (existing selector is reused); translation of shelter-generated free-text content (description, medical notes) — that is handled at the AI output layer, not by rewriting shelter content; full redesign of auth screens (plan 34); pet species expansion (plan 36).

---

## Risks

- **Devise/third-party English leakage** — validation messages can come from outside our locale files; mitigation: audit and override all auth-related messages in `config/locales/es-rails.yml` / `es.yml`.
- **AI language drift** — models occasionally produce mixed output; mitigation: locale is explicit in the prompt system/user context and QA sampling enforces the 95% bar; consider a post-generation language check in the Spec phase.
- **Cached previews across locales** — serving stale-language content; mitigation: locale becomes part of the preview cache-key/staleness decision (Spec agent to define the mechanism).
- **Key churn** — renaming existing keys breaks views; mitigation: additive keys only, no reuse of ambiguous keys.

---

## Dependencies

- **Foundation plan.** Plan 34 (auth redesign) depends on REQ-02 being complete so it builds on localized strings.
- Plan 36 (discovery) depends on REQ-03 patterns for any AI-generated content it introduces.
- Does not depend on any other plan.