# Specification: Image Delivery & Background Processing Performance (40)

**Domain:** AWS Infrastructure, Active Storage, Queuing
**Priority:** 1 (High) — pets pages are image-heavy; every image round-trip currently costs app CPU/IO
**Status:** Implemented
**Source plan:** `specs/40_image_delivery_performance_plan.md`
**Owner:** Domain Agent (`Pets::PhotoVariants`, `Pets::GeneratePhotoVariantsJob`, `Pets::PhotoManager`), Data Agent (`track_variants` config), QA Agent (variant + queue specs).

---

## Overview

The pets section is image-heavy. This spec hardens image delivery so pet photos stop burning
web-process CPU/IO on every view, and image processing never head-of-line-blocks the rest of the
queueing infrastructure:

1. **Variant generation runs off the request path.** A pre-generation job builds the canonical
   thumb/medium/large WebP q80 variants at upload time; the on-demand path in `PetPresenter`
   remains as a fallback.
2. **Image processing gets its own queue.** A dedicated `variants` SQS queue (`tovitu-variants`)
   isolates vips work from AI/import jobs (`default`) and mailers, so long-running image transforms
   never delay email or AI work.
3. **Uploaded objects carry immutable cache headers.** `Cache-Control: public, max-age=31536000,
   immutable` on every stored object (originals and variants) enables any CDN in front and correct
   browser caching — safe because Active Storage keys are content-addressed.
4. **Variant dedupe moves to the DB.** `track_variants = true` records processed variants in
   `active_storage_variant_records`, removing the per-request S3 HEAD existence check.
5. **Asset host is CDN-ready.** Propshaft digests can be served from `ASSET_HOST` when traffic grows.

CloudFront, the S3 lifecycle rule, and the production SQS queue are specified for the AWS account
(out of repo — deployment is decoupled). See the source plan's R1/R3/R4.

---

## Canonical Variants (`Pets::PhotoVariants`)

The variant contract is the single source of truth for every pet-photo transform. Any new image
size in views must go through it (or be added there) or the pre-generation job won't cover it.

| Variant | Transform | Display size |
|---------|-----------|--------------|
| `thumb`  | `resize_to_limit: [150, 150]`, WebP q80 | 150×150 |
| `medium` | `resize_to_limit: [400, 400]`, WebP q80 | 400×300 |
| `large`  | `resize_to_limit: [1200, 1200]`, WebP q80 | 1200×750 |

- Re-encoded as WebP q80 (Active Storage's default PNG output bloats JPEG uploads).
- `DISPLAY_DIMENSIONS` feed `width`/`height` hints on `<img>` tags to prevent layout shift.
- `PetPresenter#primary_photo_url` / `#photo_gallery` / `#variant_dimensions` route through
  `Pets::PhotoVariants`; SVG uploads bypass variant processing (served as-is).

## Pre-generation (`Pets::GeneratePhotoVariantsJob`)

- `queue_as :variants`.
- Best-effort: processes every `Pets::PhotoVariants.keys` variant; a failure on any blob/variant is
  logged, not raised (the upload already succeeded; on-demand fallback remains).
- No-op when the blob no longer exists.
- Enqueued by `Pets::PhotoManager#attach_many` and `#attach_by_url` after a successful upload
  (`lib/pets/photo_manager.rb:48,91`).

## Queue isolation

| Queue name | SQS queue | Purpose |
|------------|-----------|---------|
| `default` | `<prefix>-jobs` | AI/import/general jobs |
| `mailers` | `<prefix>-mailers` | email delivery |
| `variants` | `<prefix>-variants` | image variant generation |

- `Queuing::QueueRegistry` maps `variants → variants`, exposes `SQS_QUEUES` to run a dedicated
  worker (e.g. `SQS_QUEUES=variants bin/rails queuing:work`), and defaults to polling all three.
- `config.active_storage.queues = { transform: :variants }` routes Active Storage's internal
  transform job to the same queue.
- `.localstack/02-queues.sh` provisions `tovitu-variants` + DLQ (visibility 900s,
  maxReceiveCount 5); `lib/tasks/aws/smoke.rake` verifies them.
- Ops scale-by-process guidance (Procfile layout, `RAILS_MAX_THREADS`, `VIPS_CONCURRENCY`) is in
  the source plan's R4.

## Cache headers & serving mode

- `config/storage.yml` (`amazon` + `localstack`) sets `upload.cache_control:
  "public, max-age=31536000, immutable"` so every uploaded object carries immutable cache headers.
- Serving stays in proxy mode (`resolve_model_to_route = :rails_storage_proxy`): bytes stream
  through Puma until CloudFront is adopted (Option A in the plan; no Rails change required).
- `config.active_storage.track_variants = true` — variant records dedupe in the DB instead of S3
  HEAD; requires `active_storage_variant_records` (present via the `active_storage:install` migration).

## Asset pipeline

- `config.asset_host = ENV["ASSET_HOST"]` in production; Propshaft digests are immutable-safe, so
  an asset CDN can be added at any time. Static assets already get 1-year `Cache-Control`.

---

## Out of Scope (AWS account / deployment decoupled)

- CloudFront distribution + cache policy (R1 Option A) — reference HCL in the plan; adopt with the
  deployment strategy.
- S3 lifecycle rule expiring orphaned `variants/` objects (R3).
- Production `tovitu-variants` + DLQ queues (R4).
- Option B (S3-origin CDN with OAC + `CdnS3Service`) — separate follow-up spec.

## Verification

- `spec/jobs/pets/generate_photo_variants_job_spec.rb` — pre-generates every variant, no-op on
  missing blob, swallows `InvariableError`.
- `spec/lib/pets/photo_variants_spec.rb` — canonical webp options, all keys, unknown key raises,
  display dimensions.
- `spec/lib/pets/photo_manager_spec.rb` — enqueues the job on attach/attach_by_url.
- `spec/presenters/pet_presenter_spec.rb` — URL generation via `Pets::PhotoVariants`, dimensions.
- `spec/lib/queuing/queue_registry_spec.rb` — variants mapping, `SQS_QUEUES` override, prefix.