# Plan: Shelter Management — Batch Import & Media Management (REQ-15, REQ-16)

**Domain:** Shelter Tools, Import, Media (Active Storage)
**Priority:** 1 (High)
**Status:** Draft
**Tracks:** Epic "Shelter Management" (REQ-15, REQ-16)

---

## Overview

Shelters manage many pets, and the current per-pet manual flow is the bottleneck. Two capabilities remove that friction:

1. **Batch import of pets from CSV/Excel** — a shelter uploads a spreadsheet and Tovitu creates the valid pets, reports clearly on the invalid ones, and never creates partial/corrupt records. **First version scope: flat pet data only** — no images/attachments in the import; media is completed later via the media section (REQ-16).
2. **Pet media management** — a dedicated section where shelters attach, organize, and remove images (from computer or by URL), identify the profile/primary image, and finish pet profiles regardless of whether the pet was created manually or via import.

These two features are one plan because they are two halves of the same workflow: import the data, then enrich with media.

---

## Current State (confirmed in code)

- **Shelter pet management** exists (`shelter/pets` controller + views) with manual create/edit per pet; a photos controller already supports attach/detach/reorder of attached photos at a basic level.
- **No batch import** exists today — shelters must create each pet one by one.
- **Media:** photos are attached per pet with a primary-photo concept (derived from ordering), but there is no dedicated media-management screen supporting multiple sources (computer upload + URL), bulk association, validation feedback, or a clear "complete profile after import" flow.

---

## User Stories

> As a shelter coordinator with 30 new intakes,
> I want to upload one spreadsheet and have all the pets created at once,
> so that I don't spend an afternoon on data entry.

> As a shelter staff member,
> I want a single place to add, arrange, and remove photos for my pets — from my computer or from a URL — and mark the main photo,
> so that pet profiles look complete and inviting quickly.

---

## Requirements & Proposed Behavior

### REQ-15 — Batch pet import via Excel/CSV

1. An authenticated shelter can upload a **CSV** file.
2. An authenticated shelter can upload an **Excel** file (`.xlsx`).
3. The system **validates the file format**.
4. The system **validates the required columns**.
5. The system **validates data types** (e.g., age/date/boolean fields).
6. Invalid records are **identified clearly** (which row, which field, why).
7. The shelter receives a **result summary** after the import (imported count, errors).
8. Valid pets are **created correctly**.
9. Invalid records **never create incomplete or corrupt pets** (all-or-nothing per row; no half-created pet).
10. A clear **duplicate strategy** exists (define: skip duplicates by a natural key — e.g., name+species+birth date within the shelter — and report them; confirm with founder).
11. **No images** are imported in this first version (explicitly out of scope; media handled by REQ-16).
12. If import is async, the shelter sees **progress feedback**.
13. Errors are presented in **non-technical language** (a shelter volunteer must understand them).

**User flow:**
`Shelter pet section → "Import pets" → download/see template → upload CSV/Excel → validation → summary (X imported, Y errors with per-row detail) → fix file and retry invalid rows → (optional) jump to media management for imported pets`

**Edge cases:**
- Empty file / wrong extension / malformed cells → friendly format error with guidance.
- Missing required columns → error naming the missing column before any import.
- Partially valid file → valid rows import; invalid rows reported with row numbers and reasons; no partial rows created.
- Duplicates within the file and against existing pets → handled by the defined strategy, reported in the summary.
- Very large files → async processing with progress; user can leave the page and return (summary persisted).
- Locale-specific CSV nuances (delimiters, decimal commas) → handled per locale or documented in the template.
- File uses the expanded species list (plan 36) → species column accepts the new categories.

### REQ-16 — Pet media management for shelters

1. The shelter can access a **media management section** (per pet or within the pet management area).
2. Upload **multiple images** from the computer at once.
3. Add images by **URL**.
4. **Associate** each media item with a pet.
5. **View** the media associated with a pet.
6. **Delete** media.
7. Manage **multiple images per pet**.
8. Identify which image is the **profile/primary** image.
9. **Validate** uploaded files (type, size, count limits per existing photo rules).
10. Media cannot be **accidentally associated with the wrong pet**.
11. The interface supports **completing a pet profile after a batch import** (imported pets without media can be enriched here).
12. The flow works identically for pets created **manually or via import**.

**User flow:**
`Shelter pet section → select pet → "Media" → add images (upload multi / paste URL) → reorder / mark primary → save → view updated profile (both shelter-side and public profile)`

**Edge cases:**
- Uploading invalid files (wrong type, oversized, too many) → friendly per-file validation; valid files still attach.
- URL fails to load / points to non-image → validated before association; clear error.
- Marking a new primary → exactly one primary always exists; ordering is preserved.
- Deleting the current primary → another image becomes primary (or none if empty, with a clear profile placeholder state).
- Permissions: only authorized shelter staff manage media for their pets; media can't be moved to another pet by mistake (no cross-association UI).
- Media added to a pet that was just batch-imported → normal flow (import created the pet record, media attaches the same way).

---

## Acceptance Criteria

- **AC-38-1 (REQ-15)** — An authenticated shelter can upload a CSV file.
- **AC-38-2 (REQ-15)** — An authenticated shelter can upload an Excel (`.xlsx`) file.
- **AC-38-3 (REQ-15)** — File format, required columns, and data types are validated with clear, non-technical errors.
- **AC-38-4 (REQ-15)** — Invalid records are identified per row with the reason; they never create incomplete/corrupt pets.
- **AC-38-5 (REQ-15)** — Valid pets are created correctly and appear in the shelter's pet list.
- **AC-38-6 (REQ-15)** — The shelter receives a result summary (imported / errors / duplicates).
- **AC-38-7 (REQ-15)** — A defined duplicate strategy is implemented and reported.
- **AC-38-8 (REQ-15)** — No images/attachments are imported in v1 (verified in code review).
- **AC-38-9 (REQ-15)** — Async import (if used) shows progress feedback and persists the summary for later review.
- **AC-38-10 (REQ-16)** — The shelter can access a media management section.
- **AC-38-11 (REQ-16)** — Multiple images can be uploaded from the computer at once.
- **AC-38-12 (REQ-16)** — Images can be added by URL (validated).
- **AC-38-13 (REQ-16)** — Media is associated with the correct pet, viewable, reorderable, and deletable.
- **AC-38-14 (REQ-16)** — Exactly one image is identifiable as the profile/primary image; deleting the primary falls back gracefully.
- **AC-38-15 (REQ-16)** — Uploads are validated (type/size/count) with friendly errors; invalid files don't break valid ones.
- **AC-38-16 (REQ-16)** — Media cannot be accidentally associated with the wrong pet (no cross-association paths).
- **AC-38-17 (REQ-16)** — Imported pets can be completed with media through this section; manual and imported pets behave identically.
- **AC-38-18** — All new strings localized (en/es); WCAG AA; keyboard accessible; permissions enforced (Pundit).

---

## Success Metrics

- **Pets-per-shelter**: median number of live pet listings per shelter increases after import availability.
- **Time-to-live**: reduction in average time from intake to published profile (founder-reported / sampled).
- **Profile completeness**: % of published pets with a primary image increases (media management + import workflow).
- **Error/retry rate**: shelter error rate during import (invalid rows) decreases over the first months as the template and validation improve.
- **Support load**: no new "how do I import pets" / "how do I add photos" questions.

---

## Test Strategy

- **Import service specs**: CSV/Excel parsing, column/type validation, per-row all-or-nothing, duplicate strategy, summary output, large-file async behavior.
- **Request specs**: upload endpoints, authz (shelter staff only), permission boundaries.
- **Media specs**: multi-upload, URL add, primary fallback, validation limits, no cross-association, delete/reorder.
- **Manual QA**: real `.xlsx`/CSV uploads with mixed valid/invalid rows in both locales; full import → media → publish journey; imported-pet and manual-pet media parity.

---

## Scope

**In scope:** CSV/Excel batch import of flat pet data with validation, per-row error reporting, duplicate strategy, summary/progress feedback; dedicated media management section (multi-upload, URL add, reorder, primary, delete, validation, per-pet scoping); template download/guidance for the import file.

**Out of scope:** Import of images/media in v1 (explicitly deferred); mapping of free-form shelter columns to AI fields; bulk edit/delete of pets; video upload beyond existing platform support; import from third-party systems (Petfinder etc.).

---

## Risks

- **Data quality from spreadsheets** — messy real-world files (merged cells, blank rows, inconsistent headers); mitigation: strict but friendly validation, a downloadable template, per-row errors, and a clear retry loop.
- **Partial imports** — creating corrupt pets is worse than failing; mitigation: per-row atomicity (all-or-nothing per row) and post-import summary.
- **Duplicate creation** — shelters may re-upload the same file; mitigation: explicit duplicate strategy + summary reporting.
- **Async complexity** — large files need background processing; mitigation: progress feedback and persisted summaries (aligned with REQ-09's import-status pattern from plan 35).
- **Media mistakes** — attaching media to the wrong pet harms trust; mitigation: per-pet scoping, no cross-association UI, confirmation on destructive actions.

---

## Dependencies

- **Depends on plan 36** (pet types) so the import template and media flow support the expanded species list.
- **Depends on plan 33** (localization) for all new shelter-facing strings.
- **Related to plan 37** (REQ-14): media/shelter content authored here feeds the pet profile sections.
- Authz patterns already exist (Pundit); no dependency on plan 34.