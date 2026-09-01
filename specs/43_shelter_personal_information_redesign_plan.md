# Plan: Shelter Personal Information Section — Redesign & Information Grouping (Story 1.3)

**Domain:** Frontend, Shelter Tools, Design System
**Priority:** 2 (Medium-High)
**Status:** Draft
**Tracks:** Epic "Shelter Experience UI Modernization" (Story 1.3)

---

## Overview

The shelter's personal information/profile page is one long, single-column form (`max-w-lg`) mixing media uploads, contact details, location, public profile copy, and configuration toggles. There is no logical grouping, spacing between field groups is uniform (and cramped for a page this long), and the editing experience does not clearly communicate save/cancel/validation states.

This plan redesigns the section to:

- Group shelter information into **logical, titled sections**.
- Improve **spacing between sections and fields** using the design-system scale.
- Make the **editing action** obvious and the save/cancel/validation states clear.
- Follow the same layout patterns as the updated dashboard (cards, typography, buttons, focus rings).
- Clearly distinguish **editable information** from **informational content**.
- **Preserve all existing functionality** — presentation-layer only.

---

## Current State (confirmed in code)

- **Single edit page:** `app/views/shelters/edit.html.erb` renders one `max-w-lg` form with all fields in one `space-y-5` block: `logo`, `cover_image`, `profile_picture`, `name`, `street`, `city`, `state`, `zip`, `phone`, `website`, `description`, `species_served`, `hours`, `status`.
- **Controller:** `SheltersController#edit` / `#update` (Pundit `edit?`/`update?` = shelter admin only). `update` delegates to `Shelters::UpdateProfile` service, then redirects to `shelter_path(id: @shelter)` with a flash; on failure renders `:edit` with an error summary.
- **Service:** `lib/shelters/update_profile.rb` handles text params + image attachments (`logo`, `cover_image`, `profile_picture`) with storage keys; admin/wrong-shelter guards.
- **No grouped layout exists today.** The public profile (`shelter#show`) renders separately; the edit page only shows the raw form.

---

## User Stories

> As a shelter owner,
> I want my shelter's information organized into clear groups (basic info, contact, location, public profile),
> so that I can find and update a specific detail without scrolling one long list.

> As a shelter owner,
> I want obvious save/cancel behavior and clear validation feedback,
> so that I never lose my changes or wonder whether an update went through.

---

## Requirements & Proposed Behavior

### REQ-43-1 — Logical information groups

Group the shelter fields into titled sections (indicative grouping; validated against the domain model during implementation):

- **Basic information** — `name`, `description`.
- **Media / branding** — `logo`, `cover_image`, `profile_picture` (with current-image previews and remove/replace affordances where supported).
- **Contact & location** — `phone`, `website`, `street`, `city`, `state`, `zip`, `hours`.
- **Public profile / services** — `species_served`.
- **Configuration** — `status` (active/inactive).

Each group has a `font-display` section heading and a short optional helper line. Groups render as design-system cards (`rounded-xl`, `border-neutral-200`, `shadow-sm`) with consistent internal padding.

### REQ-43-2 — Spacing & alignment

- Consistent spacing between groups, between fields within a group, and between labels/inputs — using the design-system spacing scale (same values as the rest of the dashboard).
- Fields within a group align on a consistent grid (e.g., two-column `city`/`state`, `zip`/`phone` pairs on larger screens; stacked on mobile).
- Labels, inputs, and helper text follow existing dashboard form recipes (the form styles already used across the app).

### REQ-43-3 — Editing, save, cancel, and validation states

- The page uses the standardized header (plan 41): navbar → spacing → back nav → title → description → content.
- A clear, persistent **save** action (primary button) and a visible **cancel** action (ghost/secondary) that returns to the previous screen without saving.
- **Validation states:** on failure, the existing error summary renders, fields with errors are visually marked (error styling on inputs + messages), and user input is retained — no data loss.
- **Success state:** on success, the user is returned to the public profile (current behavior) with the existing success flash. (Optionally consider a "Saved" confirmation; not required.)
- Editing affordance is obvious: the page itself is the edit screen, reached from an explicit "Edit profile" action on the dashboard/public profile.

### REQ-43-4 — Editable vs. informational content

- Clearly separate fields the owner can edit from read-only informational content (e.g., shelter ID, member since/created date, verification badge) — informational content styled as metadata, not form fields.

### REQ-43-5 — Preserve existing functionality

- Same permitted params, same `Shelters::UpdateProfile` service behavior (text + image attachments, storage keys), same validation rules, same authorization (shelter admin), same redirect/flash behavior on success.
- **No new fields, no changes to the domain model.**

**Edge cases:**

- Attached images: show current logo/cover/profile previews; replacing/removing must not break the attachment flow (existing service untouched).
- No images attached → neutral placeholder state in the media group.
- Invalid/oversized image uploads → existing model validation errors surface in the error summary and inline (no crash, input retained).
- Very long `description` / `hours` → readable wrapping inside the group card.
- `species_served` empty → rendered with a clear "not set" hint in the group.
- Cancel with unsaved changes → no save happens (plain navigation); optional confirmation is out of scope unless trivially available.
- Locale: all strings localized (en/es).
- Responsive: groups stack cleanly on mobile; two-column pairs collapse to one column.

---

## Acceptance Criteria

- **AC-43-1** — The Personal Information section follows the current Tovitu design system.
- **AC-43-2** — Information is grouped logically with clear section titles.
- **AC-43-3** — The title and primary content have sufficient spacing from the navbar (plan 41 header).
- **AC-43-4** — Forms and editable fields have consistent spacing and alignment.
- **AC-43-5** — Save, cancel, and validation states are clearly communicated (error summary + inline field errors; input retained on failure).
- **AC-43-6** — Existing functionality remains unchanged unless explicitly redesigned (same service, params, auth, redirects, validations).
- **AC-43-7** — The interface is responsive across mobile, tablet, and desktop.
- **AC-43-8** — Editable information is visually distinct from informational content.
- **AC-43-9** — All new/changed strings are localized (en/es); no hardcoded user-facing strings.

---

## Success Metrics

- **Edit efficiency:** owners can locate and update a given field faster (qualitative; founder-reported).
- **Error recovery:** no "lost changes" reports after validation failures (QA + user feedback).
- **Consistency:** page matches the dashboard design system with zero divergence found in the design-review pass.
- **Zero regression:** shelters request specs continue to pass unchanged (except presentation).

---

## Test Strategy

- **Request specs:** `spec/requests/shelters/shelters_spec.rb` continues to pass (edit/update auth, service behavior, redirects) — unchanged business behavior.
- **View specs:** page renders all groups with correct headings, media previews/placeholders, field alignment classes, save/cancel actions, error summary + inline errors.
- **Manual QA matrix:** filled / partial / empty shelter data × mobile/tablet/desktop; image replace/remove; validation failure with input retention; both locales.

---

## Scope

**In scope:** restructuring `shelters/edit` into grouped, card-based sections; standardized header (plan 41); improved spacing/alignment; clear save/cancel/validation presentation; informational vs. editable distinction; media previews/placeholders; all presentation-layer only.

**Out of scope:** any change to the shelter domain model, new fields, changes to `Shelters::UpdateProfile`, public profile (`show`) redesign, roles & permissions changes (plan 46), and anything requiring migration.

---

## Risks

- **Unintended param/service changes** — mitigated by AC-43-6 and re-running the existing request specs.
- **Form breakage from restructuring** — large form refactors risk losing a field; mitigated by a field-by-field parity checklist (every permitted param appears exactly once) and view specs.
- **Image attachment regressions** — the media group interacts with Active Storage; mitigated by keeping `UpdateProfile` untouched and manual QA of replace/remove flows.
- **Design drift** — mitigated by reusing shared card/button/form recipes and the design-review pass.

---

## Dependencies

- **Depends on plan 41** (standardized page header + back navigation).
- **Related to plan 44** (dashboard) — the "Manage shelter profile" quick action must keep working after the redesign.
- **Related to plan 46** (roles & permissions) — profile editing permission becomes role-based later; this plan does not change authorization.
- **Depends on plan 33 conventions** (i18n) already in place.