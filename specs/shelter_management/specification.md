# Specification: Shelter Management — Batch Import & Media Management (38)

**Domain:** Shelter Tools, Import, Media (Active Storage)
**Priority:** 1 (High)
**Status:** Implemented (see acceptance-criteria.md for the verification record)
**Source plan:** `specs/38_shelter_management_plan.md`
**Owner:** Domain Agent (`lib/pets/*`), Data Agent (`pet_imports` migration + model), Frontend Agent (views/Stimulus), QA Agent (specs)

---

## Overview

Two halves of one shelter workflow: (1) batch-import flat pet data from CSV/`.xlsx`, and (2) a dedicated per-pet media-management section. Import never touches images (v1 scope); imported pets are enriched with media through the media section, which behaves identically for manual and imported pets.

---

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Import record | New `pet_imports` table (`PetImport`) — shelter, initiating user, status, counts, JSONB `summary`, optional Active Storage file | Persisted source of truth for async progress and result review (AC-38-9); mirrors the plan-35 `FavoritesImport` pattern |
| File persistence | `PetImport` `has_one_attached :file`; `file_name` keeps the original upload filename | The SQS worker is a separate process; the uploaded tempfile cannot survive to the job, so the file must be persisted in object storage and re-downloaded by the job |
| Async | `PetImportJob` (Active Job, `:default` queue, SQS adapter) | Large files must not block the request; progress via turbo-stream polling (`pet-import` Stimulus controller), summary persisted on the record |
| `.xlsx` parsing | `roo` gem (`~> 2.10`) | Standard, dependency-light xlsx reader; CSV parsed with the stdlib `csv` gem (BOM + delimiter detection) |
| Column validation | Canonical columns + en/es header aliases in `Pets::Import::COLUMN_ALIASES`; required columns `name, species, age_category, sex` | Friendly non-technical errors naming the missing column; locale-neutral spreadsheets |
| Value normalization | `Pets::Import.normalize_value` per type (`:string/:text/:list/:boolean/:date/:enum`); enums accept enum keys **or** en/es localized labels | Shelters may type "Perro" or "dog"; invalid present values produce per-field errors, blanks are skipped |
| Duplicate strategy | Natural key `name + species + birth_date` within the shelter (name+species when birth_date blank), checked both within the file and against existing undiscarded shelter pets | Plan leaves the choice to the founder; this key is stable, reportable, and avoids re-upload duplication (AC-38-7) |
| Per-row atomicity | Each row validated against a fresh `Pet` (all model validations) then saved in its own save | Invalid rows never create partial/corrupt pets; valid rows still import (AC-38-4/38-6) |
| Media management | Dedicated `shelter/pets/:id/media` page + extended `Shelter::PhotosController` (`create` multi/URL, `set_primary`, `move`, `destroy`) built on `Pets::PhotoManager` | Keeps per-pet scoping (no cross-association UI, AC-38-16); primary derived from `photo_order` (existing model), deleting the primary falls back to the next photo / placeholder |
| URL media | `PhotoManager.attach_by_url` fetches via `httparty`, validates content-type/size before attaching | AC-38-12: validated before association, clear error when the URL is not an image |
| Media feedback | turbo_stream replaces `#pet-media-grid` + appends a toast to `#flash-container` | Instant, accessible updates consistent with the plan-35 toast pattern |

---

## Data Model — `pet_imports`

| Column | Type | Notes |
|--------|------|-------|
| `shelter_id` | ref, null: false | FK |
| `user_id` | ref, null: false | FK — initiating staff member |
| `status` | string, default `pending` | `pending` / `processing` / `completed` / `failed` |
| `file_name` | string, null: false | original upload filename (extension detection + display) |
| `imported_count` | int, default 0 | |
| `duplicate_count` | int, default 0 | |
| `error_count` | int, default 0 | |
| `total_count` | int, default 0 | data rows in the file |
| `error` | text | fatal (non-row) error, human-readable |
| `summary` | jsonb, default `{}` | `{ imported: [{row, name, id}], duplicates: [{row, name}], errors: [{row, name, fields: {field => message}}] }` |
| `completed_at` | datetime | |
| timestamps | | |
| index | `[shelter_id, created_at]` | |

Active Storage: `has_one_attached :file` (S3-backed in dev/prod, Disk in test).

---

## Import pipeline

```
Shelter::PetImportsController#create
  → validates presence + extension (.csv/.xlsx)
  → creates PetImport (status: pending, file attached, file_name)
  → enqueues PetImportJob
PetImportJob#perform
  → marks processing
  → Pets::ImportParser (BOM/delimiter-aware CSV or Roo xlsx)  → headers + rows
  → missing required column?  → mark failed with friendly message (no import)
  → Pets::ImportProcessor
      per row: normalize values → field errors → required present →
                duplicate? (file + shelter) → new Pet + validate → save!
      → summary + counts
  → mark completed (or failed with fatal error message)
```

### `Pets::ImportParser`
- `Pets::ImportParser.call(path:, filename:)` → `Result`.
- Extension not `.csv`/`.xlsx` → `Result.failure(format_error)`.
- CSV: read `r:bom|utf-8`, auto-detect `;` vs `,` delimiter, `CSV.parse(headers: true, skip_blanks: true)`.
- XLSX: `Roo::Excelx.new(path).sheet(0)`, headers from row 1, data rows 2..last (blank rows skipped).
- Returns `Result.success(headers:, rows:)` where each row is `{ row_number:, values: { canonical_column => raw } }` (headers normalized via `COLUMN_ALIASES`; unknown headers dropped).
- Missing required columns → `Result.failure` listing them by friendly label.

### `Pets::ImportProcessor`
`call(shelter:, user:, rows:)` → `Result.success(summary)`.
- Builds existing natural keys for the shelter's undiscarded pets once.
- Per row: normalize each present value (INVALID → field error with friendly message), check required presence, compute natural key (duplicate within file or shelter → duplicate entry), else build `shelter.pets.new(attrs)`, run `valid?`, save on success.
- Field error messages are localized under `shelter.pet_imports.errors.*`.

### `Pets::ImportTemplate`
`call` → returns CSV string with header row + one example row (used by the `template` action).

---

## Controllers & Routes

```ruby
namespace :shelter do
  resources :pet_imports, only: [ :index, :new, :create, :show ] do
    get  :status, on: :collection
    get  :template, on: :collection
  end
  resources :pets do
    get :media, on: :member                     # media management page
    resources :photos, only: [ :create, :destroy, :update ] do
      post :set_primary, on: :member            # id = blob_id
      post :move, on: :member                   # id = blob_id, direction param
    end
  end
end
```

### `Shelter::PetImportsController`
- `index` — imports for `current_shelter`, latest first (with the most recent rendered for quick access).
- `new` — upload form + template link.
- `create` — file presence + extension check (synchronous, immediate feedback); else create `PetImport` + enqueue; redirect to `index`/`show` with a progress notice.
- `show` — progress (pending/processing) or persisted summary (completed/failed) with per-row error table + "import more" CTA + link to the pets list.
- `status` — turbo_stream (and JSON) for the polling controller.
- `template` — CSV download (`.csv`, `attachment`).

Authorization: Pundit `Shelter::PetImportPolicy` — shelter staff only; scoped to `current_user.shelter_id`. `media`/photo actions reuse `PetPolicy#manage_photos?` (update?).

### `Shelter::PetsController#media`
Sets `@pet` (authorized `manage_photos?`), presents via `PetPresenter`, renders `shelter/pets/media.html.erb`.

### `Shelter::PhotosController`
- `create` — accepts `params[:file]` (single, legacy), `params[:files]` (multiple), or `params[:url]`. Uses `PhotoManager.attach_many` / `attach_by_url`. HTML → redirect to `shelter_pet_path`; turbo_stream → replace `#pet-media-grid` + append toast.
- `set_primary` — `PhotoManager.set_primary`.
- `move` — `PhotoManager.move(direction: params[:direction])`.
- `destroy` — existing `PhotoManager.detach` (primary falls back via read-time `photo_order`/`photos.first`).

---

## Media management page (`shelter/pets/media`)

- Header: pet name + species + status badge; "Back to pet" link.
- **Add photos**: multi-file upload (accept `image/jpeg,image/png,image/webp`, multiple) → posts `files[]`; file count shown before submit; and a URL input → posts `url`.
- **Grid** (`shelter/pets/_media_grid.html.erb`): each photo card shows the image, a "Primary" badge on the primary, and controls:
  - "Set as primary" (when not primary) → `set_primary`
  - Move up / move down (arrow buttons) → `move`
  - Delete → `destroy`
- Controls are per-pet only (no cross-association UI); destructive delete uses a confirm.
- Empty state: friendly placeholder prompting upload (imported pets land here).
- `pet-media` Stimulus controller: auto-submits multi-file uploads, disables submit + shows a spinner while in flight, exposes a URL-add form.

---

## i18n

All new strings under `shelter.pet_imports.*` and `shelter.pets.media.*` (+ errors/notices) in `config/locales/pets/{en,es}.yml`. No hardcoded user-facing strings. `t()` in views/controllers.

---

## Not covered here

- Importing images/media in v1 (explicitly deferred; AC-38-8).
- Import from third-party systems; bulk edit/delete of pets; video beyond existing support.
- Rich edit of a parsed row before commit (future: an import-review screen).