# Plan: Image Delivery & Background Processing Performance (Pets Section)

**Domain:** AWS Infrastructure, Active Storage, Queuing
**Priority:** 1 (High) — pets pages are image-heavy; every image round-trip currently costs app CPU/IO
**Status:** Implemented
**Tracks:** Pet discovery, Public homepage, Shelter management (all render pet photos)

---

## Overview

The pets section is slow because every pet image has three compounding costs:

1. **Variants are generated on demand** on the first view of each variant (download original from S3 → vips transform → re-upload), burning web-process CPU/IO inside the request path. *Mitigation already in the working tree (pre-generation job); this plan hardens it (dedicated queue) and completes it (`track_variants`).*
2. **Image bytes flow through the Rails app** (`config.active_storage.resolve_model_to_route = :rails_storage_proxy`), so every uncached image is downloaded from S3 and streamed by a Puma thread.
3. **No CDN** — repeat views hit the app tier (and, for a cold cache, S3) every time; browsers cache for 1 year but only *after* the first visit per device.

This plan ranks the fixes, implements the in-repo pieces, and specifies the AWS-side IaC (CloudFront) that must be created in the account (no IaC pattern exists in this repo today — `.localstack/` scripts provision LocalStack only).

---

## Current State (confirmed in code)

| Area | Finding |
|------|---------|
| Storage service | `config/storage.yml:23` — `amazon` service (real S3, IAM role). `config/storage.yml:12` — `localstack` (dev). `config/environments/production.rb:25` — `:amazon`. |
| Serving mode | `config/application.rb:66` — `resolve_model_to_route = :rails_storage_proxy`. Bytes stream through Puma; proxy controller sends `Cache-Control: public, max-age=31536000, immutable` (`http_cache_forever`). |
| Variant generation | `app/presenters/pet_presenter.rb:25` — on-demand `photo.variant(resize_to_limit: ...)` via `rails_representation_path`. Working tree adds `lib/pets/photo_variants.rb` (canonical WebP q80 variants) + `app/jobs/pets/generate_photo_variants_job.rb` (pre-generates after upload, `queue_as :default`) + `lib/pets/photo_manager.rb:48,91` (enqueues). |
| Variant tracking | `config.active_storage.track_variants` is **not** enabled (default false). `active_storage_variant_records` table absent from `db/structure.sql`. With tracking off, dedupe relies on `ActiveStorage::Variant#processed?` → `service.exist?(key)` (S3 HEAD). |
| Queues | Custom SQS adapter (`lib/active_job/queue_adapters/sqs_adapter.rb`), `config/application.rb:51` `queue_adapter = :sqs`. `Queuing::QueueRegistry` maps `default → tovitu-jobs`, `mailers → tovitu-mailers`. Worker (`lib/queuing/worker.rb`) is **single-threaded**, long-polls all queues sequentially. `config/queue.yml` is **dead config** (Solid Queue format; no `solid_queue` gem — do not tune it). |
| Variant key path | `ActiveStorage::Variant#key` → `variants/<blob.key>/<sha256(variation)>`. Blob keys are prefixed (`lib/storage_key_generator.rb`, `config/initializers/active_storage_blob_key.rb`). |
| Object caching | No `Cache-Control` metadata set on S3 objects at upload (`config/storage.yml` had no `upload:` block). |
| N+1 on pets index | Already handled: `app/controllers/pets_controller.rb:9,68,79` `includes(:shelter, photos_attachments: :blob)`. `photo_order` sorting is in-memory (`app/models/pet.rb:119`). **No change needed.** |
| Static assets | Propshaft + Importmap. `config/environments/production.rb:19` 1-year `Cache-Control` on public files. Docker runs Thruster (`Dockerfile:77`) which gzip/brotli-compresses static assets. |

---

## Ranked Recommendations

| # | Change | Impact | Effort | Where |
|---|--------|--------|--------|-------|
| 1 | **CDN in front of image delivery** (CloudFront) | High — removes app tier from almost all image requests | Medium | AWS account + follow-up Rails service |
| 2 | **Dedicated `variants` queue** for image processing | High — stops vips work from head-of-line-blocking AI jobs/mailers | Small | **DONE in this repo** |
| 3 | **Upload-time `Cache-Control: immutable` metadata** on S3 objects | Medium — enables any CDN + correct browser semantics | Small | **DONE in this repo** |
| 4 | **`config.active_storage.track_variants = true`** + migration | Medium — DB-level dedupe of processed variants, avoids per-request S3 HEAD | Small | This repo (follow-up) |
| 5 | **S3 lifecycle rules** (`variants/` prefix cleanup) | Low/Medium — reclaims orphaned variant objects after purge | Small | AWS console/IaC |
| 6 | **Worker process layout** (dedicated variant workers) | Medium — parallelizes image processing | Ops | Deployment config (decoupled) |
| 7 | **`ASSET_HOST` for Propshaft** | Low — CDN for CSS/JS when traffic grows | Small | **DONE in this repo** |

---

## R1 — CDN in front of image delivery

### Option A (recommended now): CloudFront in front of the app, caching `/rails/active_storage/*`

Works with the repo's current **proxy mode** with zero Rails changes. CloudFront terminates `/rails/active_storage/*` and serves cached bytes from the edge; cache misses go to the app, which streams from S3 and sets immutable headers that CloudFront honors.

- **Origin:** the app origin (ALB / app domain).
- **Cache behavior path pattern:** `/rails/active_storage/*`.
- **Cache policy:** custom — TTL `min=86400`, `default=31536000`, `max=31536000`; **query strings: ignore**; cookies: none; headers: none. (Image URLs are content-addressed or verifier-signed without expiry; `?disposition=inline` only affects a header, not bytes — safe to ignore.)
- **Origin request policy:** none (do not forward cookies/auth headers to image endpoints).
- **Compression:** not beneficial for jpeg/webp; leave off for this behavior.
- **Price class:** `PriceClass_100`/`200` acceptable at MVP.

### Option B (follow-up): CloudFront in front of S3 with OAC (pure object CDN)

The task asks for S3-origin with OAC. **Important:** a CloudFront S3 origin cannot serve `/rails/active_storage/representations/*` directly, because the Active Storage *URL path* (signed blob id + variation key) is **not** the S3 object key (`variants/<blob.key>/<digest>`). Making S3 a direct origin requires:

1. A custom Active Storage service that generates **public CDN URLs keyed on the real S3 object path** — e.g. `lib/active_storage/service/cdn_s3_service.rb` overriding `url` to return `https://cdn.<domain>/<key>` (object keys are unguessable; OAC + bucket policy makes objects readable via CloudFront only).
2. Switching `config.active_storage.resolve_model_to_route = :rails_storage_redirect` so the representation/blob controller 302s to that CDN URL.
3. CloudFront origin = S3 bucket with **Origin Access Control (OAC)**, cache behavior path pattern `/*` (or `/variants/*` + `/*`), same cache policy as Option A.
4. `config.active_storage.service_urls_expire_in` becomes irrelevant once `url` no longer presigns (objects are public through the CDN). If the team keeps presigned URLs instead, the CDN must **forward query strings** and TTLs must be shorter than presign expiry — messier; the custom `url` approach is cleaner.

Option B offloads even cache misses from the app tier, but adds a service subclass + serving-mode change + coordinated rollout. **Do it after Option A** and treat it as a separate spec. Skeleton for the custom service:

```ruby
# lib/active_storage/service/cdn_s3_service.rb (follow-up — not yet added)
class ActiveStorage::Service::CdnS3Service < ActiveStorage::Service::S3Service
  def url(key, expires_in: nil, disposition: :inline, filename: nil, content_type: nil, **)
    # Objects are public-through-CDN via OAC; keys are unguessable.
    "#{ENV.fetch("CDN_BASE_URL")}/#{key}"
  end
end
```

### CloudFront IaC (HCL) — Option A

No IaC pattern exists in this repo; this is the reference config. Terraform:

```hcl
# infrastructure/aws/cloudfront.tf (reference — to be adopted with the deployment strategy)
resource "aws_cloudfront_distribution" "app" {
  enabled             = true
  default_root_object = ""

  origin {
    domain_name = var.app_origin_domain   # ALB / app domain
    origin_id   = "app-origin"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Images: cache aggressively, ignore query strings
  ordered_cache_behavior {
    path_pattern     = "/rails/active_storage/*"
    target_origin_id = "app-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    compress         = false
    cache_policy_id  = aws_cloudfront_cache_policy.active_storage.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.none.id
  }

  default_cache_behavior {
    target_origin_id = "app-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    cache_policy_id  = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.caching_optimized.id
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }
  viewer_certificate {
    cloudfront_default_certificate = true  # or acm_certificate_arn for a custom domain
  }
}

resource "aws_cloudfront_cache_policy" "active_storage" {
  name        = "active-storage-immutable"
  min_ttl     = 86400
  default_ttl = 31536000
  max_ttl     = 31536000
  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = false
    enable_accept_encoding_gzip   = false
    cookies_config  { cookie_behavior = "none" }
    headers_config  { header_behavior = "none" }
    query_string_config { query_string_behavior = "none" }
  }
}
```

CloudFront honors the origin's `Cache-Control: public, max-age=31536000, immutable` (now set at upload — see R3) for the image behavior; the cache policy above is the belt-and-suspenders cap.

---

## R2 — Variant generation off the request path

**Status in repo:** `Pets::GeneratePhotoVariantsJob` + `Pets::PhotoVariants` already pre-generate thumb/medium/large WebP q80 variants after upload (`lib/pets/photo_manager.rb:48,91`), with on-demand fallback in `PetPresenter`. **Queue isolation added by this plan** (see R4). Remaining hardening:

1. **Enable `config.active_storage.track_variants = true`** in `config/application.rb` (Rails 8.1's replacement for `variant_tracker`). Requires `rails active_storage:install` migration (`active_storage_variant_records` table — absent today). Benefit: DB-backed dedupe (`ActiveStorage::VariantWithRecord`) so representation requests skip the S3 HEAD existence check and variant files are tracked/cleanup-aware. Follow-up migration + config flip, coordinated with the data agent (schema change).
2. Confirm `libvips` availability in the runtime image — yes: `Dockerfile:19` installs `libvips`; `config/initializers/active_storage.rb:5` sets `variant_processor = :vips`.

---

## R3 — S3 object configuration

**Done in this repo:** `config/storage.yml` now sets `upload.cache_control: "public, max-age=31536000, immutable"` on the `amazon` and `localstack` services, so **every uploaded object (originals and variants) carries immutable cache headers** — required for R1 and correct browser caching.

**Still AWS-side (console or IaC with the deployment strategy):**

- **Lifecycle rule — `variants/` prefix:** `purge_later` (`lib/pets/photo_manager.rb:105`) deletes only the original blob key; processed variants under `variants/<key>/` are orphaned. Add an S3 lifecycle rule expiring `variants/` prefix objects after e.g. 30 days. (Enabling `track_variants` also cleans variant *records* on blob destroy, but the uploaded variant objects under `variants/` still need the lifecycle rule.)
- **Intelligent-Tiering:** only after the bucket grows past ~a few GB; not needed at MVP.
- **Bucket policy / OAC:** only when adopting Option B above.

---

## R4 — Queues / processes

**Key finding:** `config/queue.yml` is **unused** — it is Solid Queue config and the repo runs a **custom SQS adapter + single-threaded worker** (`lib/queuing/worker.rb`). Tuning `queue.yml`/`JOB_CONCURRENCY` does nothing.

**Done in this repo:**
- `lib/queuing/queue_registry.rb` — new `variants` queue (`tovitu-variants`) + `SQS_QUEUES` env override so a dedicated worker can poll only the variants queue.
- `app/jobs/pets/generate_photo_variants_job.rb` — `queue_as :variants`.
- `config/application.rb` — `config.active_storage.queues = { transform: :variants }` routes Active Storage's internal transform job to the same queue.
- `.localstack/02-queues.sh` + `lib/tasks/aws/smoke.rake` — provision/verify `tovitu-variants` (+ DLQ, visibility 900s, maxReceiveCount 5, matching the existing queues).

**Ops guidance (deployment is decoupled from this repo):** run a production Procfile-style layout:

```procfile
web:            bin/rails server                       # RAILS_MAX_THREADS=5, WEB_CONCURRENCY=2
worker:         bin/rails queuing:work                 # default + mailers + variants (single small deploy)
variant_worker: env SQS_QUEUES=variants bin/rails queuing:work   # ×2–4 processes
```

- **Puma threads:** proxy mode streams image bytes (IO-bound) — `RAILS_MAX_THREADS=5` is a reasonable ceiling; more threads than DB pool connections is counterproductive (GVL + pool). Keep `config/puma.rb` defaults; set via ENV at deploy time.
- **Variant worker concurrency:** the custom worker is single-threaded per process, so scale by **process count** (each `queuing:work` process = 1). 2–4 variant worker processes keep up with uploads; vips is multi-threaded internally (`VIPS_CONCURRENCY` env tunes it).
- **SQS visibility timeout:** variants queue inherits 900s like the existing queues — appropriate for large images.
- **Polling latency:** with `SQS_QUEUES=variants` the dedicated worker's poll cycle is just that queue (long-poll 20s, returns immediately when messages arrive).

---

## R5 — Asset pipeline

- Propshaft digests + `config/environments/production.rb:19` already serve static assets with 1-year `Cache-Control`; Thruster (Dockerfile) handles gzip/brotli. **No further in-repo change needed.**
- **Done in this repo:** `config.asset_host = ENV["ASSET_HOST"]` in production — set `ASSET_HOST` to a CloudFront/CDN domain when the app domain moves behind CloudFront.
- Note: `importmap` pins are digest-stamped; an asset CDN is safe to add any time.

---

## R6 — Database / query load

**Already handled.** `PetsController#index` (`app/controllers/pets_controller.rb:9,68,79`) eager-loads `:shelter, photos_attachments: :blob` on both browse and NL-search paths; `Pet#ordered_photos`/`primary_photo` sort in memory (`app/models/pet.rb:114,119`). No N+1 on the pets index. (Flag: `photo_gallery` in `pet_presenter.rb:30` maps `ordered_photos` — loaded blobs, no extra queries.)

---

## AWS console / account actions (out of repo)

1. **CloudFront distribution** (Option A) in front of the app domain — cache behavior `/rails/active_storage/*` per R1; attach ACM cert + Route 53 record.
2. **S3 lifecycle rule** on `tovitu-production` expiring `variants/` prefix objects (30d).
3. **Create `tovitu-variants` + `tovitu-variants-dlq` SQS queues** in production (visibility 900s, redrive maxReceiveCount 5) — mirror of `.localstack/02-queues.sh`.
4. (Option B only) **S3 OAC** + bucket policy, **custom CDN domain**, and the CdnS3Service subclass.
5. **Deploy-time env:** `SQS_QUEUES=variants` for dedicated variant workers; `ASSET_HOST` once assets move to CDN; `RAILS_MAX_THREADS=5`, `WEB_CONCURRENCY=2`.

---

## Frontend agent coordination

- **Variant contract is now canonical:** `Pets::PhotoVariants` (thumb 150, medium 400, large 1200 — all WebP q80). Any new image size in views must go through `Pets::PhotoVariants` (or be added there) **or the pre-generation job won't cover it** and the first view will pay on-demand processing. `pet_presenter.rb` already routes through it; `shelter_presenter.rb` (`logo_url`, `cover_url`) uses its own ad-hoc dimensions — decide whether those become canonical variants too (recommended: yes, so they benefit from pre-generation + caching).
- **Cache header strategy:** immutable caching is safe because variant URLs are content-addressed. When a variant definition changes (e.g. `saver.quality`), the variation digest changes → new URL → no stale-cache risk. Do **not** reuse a URL path across different transform sets.
- **Lazy loading is already good** (`pets/index.html.erb:209` — first card eager, rest lazy). With a CDN, consider increasing `prefetch` (`image-prefetch` controller) to warm the CDN cache on hover.
- **Query strings:** keep image tags free of query params (only `disposition: inline`) so the CDN can ignore query strings safely.

---

## Files touched by this plan

| File | Change | Status |
|------|--------|--------|
| `lib/queuing/queue_registry.rb` | `variants` queue mapping + `SQS_QUEUES` override | ✅ implemented |
| `app/jobs/pets/generate_photo_variants_job.rb` | `queue_as :variants` | ✅ implemented |
| `config/application.rb` | `config.active_storage.queues = { transform: :variants }` | ✅ implemented |
| `.localstack/02-queues.sh` | `tovitu-variants` + DLQ provisioning | ✅ implemented |
| `lib/tasks/aws/smoke.rake` | smoke check includes variants queues | ✅ implemented |
| `config/storage.yml` | `upload.cache_control: immutable` on S3 services | ✅ implemented |
| `config/environments/production.rb` | `config.asset_host` behind `ASSET_HOST` | ✅ implemented |
| `db/` (migration) | `active_storage_variant_records` + `track_variants = true` | ✅ implemented (`config/application.rb:78`, `db/migrate/20260615150851...`) |
| `spec/lib/queuing/queue_registry_spec.rb` | `variants` mapping + `SQS_QUEUES` override coverage | ✅ implemented |
| `specs/40_image_delivery_performance/` | specification + acceptance criteria | ✅ implemented |
| `infra/` (new, with deployment strategy) | CloudFront distribution + cache policy (R1) | 📋 AWS account |
| S3 lifecycle rule (`variants/`) | R3 | 📋 AWS account |
| `tovitu-variants` SQS queue | R4 | 📋 AWS account |