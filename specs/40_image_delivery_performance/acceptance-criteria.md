# Acceptance Criteria: Image Delivery & Background Processing Performance (40)

All criteria reference `specs/40_image_delivery_performance_plan.md` (R2/R4 + Files Touched).

---

## AC-40-1: Variant generation is off the request path

```
Given a pet photo is uploaded via Pets::PhotoManager#attach_many or #attach_by_url
Then Pets::GeneratePhotoVariantsJob is enqueued for the new blob
And the on-demand path in PetPresenter remains as a fallback
```

Verified by `spec/lib/pets/photo_manager_spec.rb` (job enqueued on attach and attach-by-URL).

---

## AC-40-2: Every canonical variant is pre-generated

```
Given Pets::GeneratePhotoVariantsJob runs for a blob
Then all Pets::PhotoVariants.keys (thumb, medium, large) exist in storage as WebP q80
```

Verified by `spec/jobs/pets/generate_photo_variants_job_spec.rb` (variant keys exist after `perform_now`).

---

## AC-40-3: Pre-generation is best-effort

```
Given the blob no longer exists, or a variant cannot be processed (InvariableError, ...)
Then the job does not raise
And (for a missing blob) it is a no-op
```

Verified by `spec/jobs/pets/generate_photo_variants_job_spec.rb`.

---

## AC-40-4: Variants are generated through one canonical contract

```
Given a view/presenter/job requests a pet photo size
Then it uses Pets::PhotoVariants (or the size is added there first)
And the generated variant keys always match between pre-generation and on-demand use
```

Verified by `spec/lib/pets/photo_variants_spec.rb` (canonical webp options, all keys) and
`spec/presenters/pet_presenter_spec.rb` (routing through `Pets::PhotoVariants`).

---

## AC-40-5: Image processing has a dedicated queue

```
Given Pets::GeneratePhotoVariantsJob and ActiveStorage::TransformJob run
Then they route to the `variants` queue (SQS: <prefix>-variants)
And they never head-of-line-block jobs on `default` or `mailers`
```

Verified by `spec/lib/queuing/queue_registry_spec.rb` (variants mapping) + `config/application.rb`
(`config.active_storage.queues = { transform: :variants }`).

---

## AC-40-6: A dedicated variant worker is supported

```
Given SQS_QUEUES=variants
Then Queuing::QueueRegistry.queues returns only ['variants']
And a dedicated worker (SQS_QUEUES=variants bin/rails queuing:work) polls only that queue
```

Verified by `spec/lib/queuing/queue_registry_spec.rb`.

---

## AC-40-7: Dev resources match production (queues + smoke)

```
Given LocalStack init runs
Then tovitu-variants exists with a redrive policy to tovitu-variants-dlq
    (visibility 900s, maxReceiveCount 5)
And bin/rails aws:smoke verifies the variants queues
```

Verified by `.localstack/02-queues.sh` and `lib/tasks/aws/smoke.rake`.

---

## AC-40-8: Uploaded objects are immutably cached

```
Given an object is uploaded to the amazon or localstack S3 service
Then it carries Cache-Control: public, max-age=31536000, immutable
And that applies to originals and variants alike
```

Verified by `config/storage.yml` (upload block on both services). Safe because keys are content-addressed.

---

## AC-40-9: Variant dedupe uses the database

```
Given config.active_storage.track_variants is true
And active_storage_variant_records exists (active_storage:install migration)
Then representation requests resolve from the DB instead of a per-request S3 HEAD
```

Verified by `config/application.rb` and `db/structure.sql` (`active_storage_variant_records`).

---

## AC-40-10: Assets are CDN-ready

```
Given ASSET_HOST is set in production
Then Propshaft digests are served from the asset host
And static assets keep their 1-year Cache-Control
```

Verified by `config/environments/production.rb` (`config.asset_host`).

---

## Summary

All in-repo acceptance criteria implemented and verified by the spec suite (1751 examples green).

## AWS account follow-ups (out of repo, deployment decoupled)

- CloudFront distribution in front of the app caching `/rails/active_storage/*` (plan R1 Option A).
- S3 lifecycle rule expiring `variants/` prefix objects (~30d) (plan R3).
- Production `tovitu-variants` + `tovitu-variants-dlq` SQS queues (plan R4).
- Deploy-time env: `SQS_QUEUES=variants` for dedicated variant workers, `ASSET_HOST` once assets
  move to a CDN, `RAILS_MAX_THREADS=5`, `WEB_CONCURRENCY=2`.