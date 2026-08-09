# Plan: AWS Infrastructure Migration (LocalStack-First)

**Domain:** Infrastructure, Queuing, Storage, Email, Authentication, Observability
**Priority:** 2 (foundational enabler — many phases touch the running app)
**Status:** Draft
**Tracks:** Replaces local Postgres/Redis/MinIO/R2 + Sidekiq stack with AWS services emulated locally via LocalStack (student/Pro license).

---

## Overview

Tovitu currently runs entirely on local, self-managed services (Docker Compose) with one external SaaS (Cloudflare R2) and no deployment target. This plan migrates the runtime infrastructure to AWS, **emulating every AWS service locally with LocalStack** so that development, test, and CI behavior mirrors production.

The scope is deliberately restricted: **only AWS services that LocalStack can emulate are considered.** Anything LocalStack cannot emulate faithfully is deferred (see [Deferred / Out of Scope](#deferred--out-of-scope)).

**Goals:**
- Every production AWS dependency has a 1:1 LocalStack-emulated local equivalent running on `docker compose up`.
- Background jobs move from Sidekiq/Redis to **SQS** (explicit decision: rewrite, not adapter-shim).
- Redis is **removed from the stack entirely** (cache stays `solid_cache` on the DB, cable stays `solid_cable` on the DB, jobs move to SQS).
- No app-level call site knows it is talking to AWS — queueing, email, storage, and auth stay behind the repo's existing provider-agnostic abstractions.

---

## Guiding Constraints

1. **LocalStack scope only.** A service is in scope only if LocalStack (student/Pro license) emulates it well enough to run the app end-to-end locally: `s3`, `sqs`, `sns`, `ses`, `cognito-idp`, `secretsmanager`, `logs`, `events`, `scheduler` (EventBridge Scheduler), `bedrock`/`bedrockruntime` (mock, optional).
2. **Provider-agnostic seams stay intact.** The repo already isolates external providers:
   - `Messaging::BaseProvider` (WhatsApp)
   - `Ai::Provider` + `Ai::Rag::*EmbeddingAdapter` (AI)
   - Active Job interface for jobs (keep `perform_later` call sites untouched)
   - Action Mailer for email
   - `has_secure_password` + `lib/authentication/*` service objects for auth
   Migration replaces *implementations behind these seams*, not the call sites.
3. **Deployment is decoupled.** Per AGENTS.md, no deployment tooling in the repo until production-ready. Hosting concerns (ECS/ECR/ALB/Route 53/CloudFront/ACM) are **explicitly out of scope** here.
4. **Env-driven config.** One `config/initializers/aws.rb` centralizes AWS client setup (endpoint, region, credentials) from ENV, so the same code runs against LocalStack and real AWS. No hardcoded endpoints in business code.
5. **Everything provisioned on boot.** LocalStack init scripts (`SERVICES=...` + `.localstack/init/ready.d/*.sh`) create buckets, queues (+ DLQs), SNS topics, user pools, secrets, and scheduled rules before the app starts.

---

## Current Infrastructure Inventory

| Component | Current impl | Where it lives |
|---|---|---|
| Database (PostgreSQL 16 + pgvector) | Docker `pgvector/pgvector:pg16` | `docker-compose.yml` |
| Job queue | Sidekiq + Redis 7 | `config/application.rb:50`, `config/sidekiq.yml`, `Gemfile` |
| Cache | `solid_cache` (DB-backed) | `config/cache.yml` |
| Action Cable | `solid_cable` (DB-backed) | `config/cable.yml` |
| File storage | MinIO (dev) / LocalStack S3 (dev alt) / Cloudflare R2 (prod) | `config/storage.yml` |
| Email | None wired (mailers rendered; no delivery method set) | `app/mailers/*` |
| Auth | `bcrypt` (`has_secure_password`) + `lib/authentication/*` | `app/models/user.rb`, `lib/authentication/` |
| AI | OpenAI HTTP direct (`Ai::Provider`) + Anthropic embeddings | `lib/ai/`, `config/prompts/` |
| WhatsApp | Direct Business API behind `Messaging::BaseProvider` | `lib/messaging/` |
| Secrets | `.env` + `credentials.yml.enc` | repo root |
| Recurring jobs | `config/recurring.yml` (currently references SolidQueue — dead config; gem not present) | `config/recurring.yml` |
| Webhooks | In-app controller (`Messaging::ReceiveWebhook`) | `app/controllers/` |

**Jobs inventory (must survive the SQS rewrite):**
- `Ai::GenerateLifePreviewJob` (app/jobs/ai/)
- `Ai::GenerateAdopterInsightJob` (app/jobs/ai/)
- `Ai::ProcessDocumentJob` (app/jobs/ai/)
- Mailer jobs via `deliver_later` (all `AuthenticationMailer` + `AdoptionMailer` calls in `lib/adoptions/*`, `lib/authentication/*`, `lib/notifications/*`)

---

## Target Architecture (LocalStack-First)

```
┌──────────────────────────────────────────────────────────────┐
│                        Rails app (monolith)                  │
│  Active Storage ──► S3        Action Mailer ──► SES           │
│  Active Job ──────► SQS       Auth (lib/authentication) ─► Cognito
│  Secrets (boot) ──► Secrets Manager      Recurring ─► EventBridge Scheduler
│  Notification fan-out ──► SNS (optional)                    │
└──────────────────────────────────────────────────────────────┘
   local: everything above served by LocalStack (localhost:4566)
   prod:  real AWS endpoints (same code, different ENV)
```

---

## Phases

### Phase 0 — LocalStack Foundation (enabler)

**Scope:** Upgrade LocalStack from `SERVICES=s3` to the full emulated footprint; provision all resources on boot; centralize AWS client config; add required SDK gems.

**Approach**
1. `docker-compose.yml`: extend the `localstack` service:
   - `SERVICES: s3,sqs,sns,ses,cognito-idp,secretsmanager,logs,events,scheduler`
   - Enable `PERSISTENCE: 1` (dev state survives restarts) and `DEBUG: 0`.
   - Add the **LocalStack MailHog extension** (or rely on SES message-catching) for inspecting sent emails in dev.
2. Add gems (all `require: false` unless needed at boot):
   - `aws-sdk-s3` (already present)
   - `aws-sdk-sqs`
   - `aws-sdk-sesv2` (fallback `aws-sdk-ses` if v2 endpoint gaps)
   - `aws-sdk-cognitoidentityprovider`
   - `aws-sdk-secretsmanager`
   - `aws-sdk-sns`
   - `aws-sdk-scheduler` + `aws-sdk-events`
   - `jwt` (Cognito ID-token verification in Phase 7)
3. New `config/initializers/aws.rb`:
   - Read `AWS_ENDPOINT_URL` (set to `http://localhost:4566` in dev via `.env`), `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`.
   - Apply via `Aws.config` (or rely on SDK v3 `AWS_ENDPOINT_URL` support). Never hardcode the LocalStack URL in app code.
4. `.localstack/init/ready.d/` — replace `setup-s3.sh` with a provisioning script set (see per-phase resources):
   - `01-storage.sh` (S3 buckets)
   - `02-queues.sh` (SQS queues + DLQs)
   - `03-topics.sh` (SNS, optional)
   - `04-cognito.sh` (user pool + app client)
   - `05-secrets.sh` (Secrets Manager entries)
   - `06-scheduler.sh` (EventBridge Scheduler rules)
   - Keep the existing `setup-s3.sh` pattern (`awslocal` CLI) and the `${LOCALSTACK_VOLUME}:/etc/localstack/init/ready.d` mount.
5. Smoke rake task `aws:smoke` (or script) that lists buckets/queues/pools and exits non-zero on failure — used by `bin/setup` and CI.

**Acceptance criteria**
- `docker compose up` boots LocalStack with all services; init scripts create every resource idempotently.
- `bin/rails aws:smoke` passes against LocalStack.
- `Aws::S3::Client.new.list_buckets` (etc.) works from a Rails console without per-client endpoint args.
- CI (`.github/workflows`) can run the same smoke against LocalStack service containers.

---

### Phase 1 — S3 Storage (replaces MinIO + Cloudflare R2)

**Scope:** Active Storage moves to S3 in every env. MinIO and R2 are retired.

**Approach**
1. `config/storage.yml`:
   - Promote the existing `localstack` service to the default dev/test service (endpoint from `AWS_ENDPOINT_URL`, keys from ENV).
   - Add `amazon` service for production (real S3 bucket, no `endpoint`, no `force_path_style`).
   - Delete `minio` and `cloudflare_r2` entries once prod R2 data is copied (see rollout).
2. `config/environments/`: `active_storage.service` → `:localstack` (dev/test), `:amazon` (prod).
3. `docker-compose.yml`: remove the `minio` + `minio-init` services and the `minio_data` volume.
4. `.env.example`: remove `MINIO_*` and `R2_*`; add `AWS_ENDPOINT_URL`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `S3_BUCKET`.
5. Data migration (prod only, at rollout): copy R2 objects to S3 (e.g., `aws s3 sync s3://r2… s3://tovitu-prod --endpoint-url …` or an `ActiveStorage::Blob` rake task). Blob keys are content-hashed, so `ActiveStorage::Blob` rows need no changes if keys are preserved.

**Acceptance criteria**
- Pet photos, shelter docs, and generated variants upload/download through LocalStack S3 in dev.
- `ActiveStorage` variant generation (`preview.active_storage` touch hook in `config/initializers/active_storage.rb`) still fires.
- Storage smoke: upload → read → purge a blob through the app in dev.
- Prod `storage.yml` points at a real S3 bucket with `force_path_style` off.

---

### Phase 2 — SQS Jobs (rewrite Sidekiq → SQS)

**Scope:** Remove Sidekiq + Redis. Rewrite the job layer to SQS behind Active Job. This is the largest infra change in the plan.

**Approach**
1. **Remove Redis/Sidekiq:** delete `sidekiq`, `redis` gems; delete `config/sidekiq.yml`, `config/initializers/` sidekiq references, the `redis` docker service + volume, and `REDIS_URL` from `.env`. Keep `solid_cache`/`solid_cable` (DB-backed, no Redis needed).
2. **New `lib/queuing/` domain** (provider-agnostic seam, mirrors `lib/messaging/` style):
   - `Queuing::Client` — wraps `Aws::SQS::Client`; resolves queue URL by name from ENV (`SQS_QUEUE_PREFIX`); `publish(queue:, payload:)`, `receive(queue:, max_messages:, wait_time:)`, `ack(queue:, receipt_handle:)`.
   - `Queuing::Adapter` — `ActiveJob::QueueAdapters::SqsAdapter` with `enqueue(job)` → `Queuing::Client.publish(queue: job.queue_name, payload: job.serialize.to_json)`.
   - `Queuing::Worker` + rake task `queuing:work` — long-polls all configured queues (`WaitTimeSeconds: 20`), decodes `ActiveSupport::JSON`, calls `ActiveJob::Base.execute(job_data)`, deletes the message on success. On `ActiveJob::DeserializationError`/missing records: discard (matches current `discard_on` philosophy). On retryable errors: rely on SQS visibility timeout, message goes to **DLQ** via redrive policy after `maxReceiveCount` (see queue topology).
   - `Queuing::QueueRegistry` — canonical queue names (`default`, `mailers`) + DLQ mapping, env-driven, mirrored in init scripts.
3. **Queue topology** (created by `02-queues.sh`):
   - `tovitu-jobs` (default queue) + `tovitu-jobs-dlq`
   - `tovitu-mailers` + `tovitu-mailers-dlq`
   - Redrive policy: `maxReceiveCount: 5`, `deadLetterTargetArn` → matching DLQ.
4. **Config:** `config/application.rb:50` and `config/environments/production.rb:53` → `config.active_job.queue_adapter = :sqs_adapter` (test keeps `:test`).
5. **Delayed jobs:** SQS native `DelaySeconds` caps at 15 min. Audit for `perform_at`/`wait` usage (none today — all `perform_later`). For future long delays, use EventBridge Scheduler → SQS (Phase 5). Document in `Queuing::Client`.
6. **Mailer queue:** `deliver_later` continues to work — mailer jobs route to the `mailers` queue via Active Job (Phase 3 wires the delivery method).

**Acceptance criteria**
- All three AI jobs execute end-to-end via the SQS worker locally (enqueue from a controller/model, observe execution + message deletion).
- No Redis process required for dev: `docker compose up postgres localstack` + `bin/rails queuing:work` runs the full app.
- DLQ behavior: a job that always fails lands in the DLQ after `maxReceiveCount`; worker logs the failure.
- `deliver_later` mailer jobs appear on `tovitu-mailers` and are consumed.
- `bundle exec sidekiq` no longer referenced anywhere; `REDIS_URL` gone from `.env.example`.

---

### Phase 3 — SES Email

**Scope:** Wire Action Mailer to SES (emulated locally by LocalStack). Mailer templates and `deliver_later` call sites unchanged.

**Approach**
1. New `lib/mailers/ses_delivery_method.rb` (or use `Aws::SESV2::Client#send_email` via a custom `delivery_method`): render the mail via `mail.message`, map to SES `SendEmail` (`ToAddresses`, `FromEmailAddress`, `ReplyTo`, subject, HTML/text body).
2. Config:
   - `development`/`production` → `config.action_mailer.delivery_method = :ses` (name matches the custom method; `config.action_mailer.ses_settings` for region/from).
   - `test` → keep `:test` (already set).
   - `config.action_mailer.default_url_options` host already exists; keep.
3. Local dev: LocalStack catches SES messages; inspect via `awslocal ses list-identities`/`get-send-statistics`, or the MailHog extension UI (`http://localhost:8025`). Add a note to README.
4. Prod rollout: verify the sending domain/identity in SES; set `From` address; move to production access if needed.

**Acceptance criteria**
- Verification email (register), password reset email, and adoption notification emails are all *sent* (visible in LocalStack/MailHog) in dev without SMTP config.
- `AuthenticationMailer`/`AdoptionMailer` templates unchanged.
- Prod SES config uses verified identity; sends are traceable in SES console.

---

### Phase 4 — Secrets Manager

**Scope:** Move runtime secrets out of `.env`/credentials into Secrets Manager (emulated locally). `.env` remains only as bootstrap (endpoint/region/credentials for the AWS client itself).

**Approach**
1. New `config/initializers/secrets.rb`:
   - At boot, fetch a single JSON secret per env, e.g. `tovitu/<env>/runtime` containing `OPENAI_API_KEY` (or Anthropic key), `WHATSAPP_API_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID`, `WHATSAPP_WEBHOOK_VERIFY_TOKEN`, `S3_BUCKET`, `SES_FROM`, Cognito pool ids (Phase 7).
   - Cache in a `Rails.configuration.secrets` `OrderedOptions`; expose `Secrets.fetch(:key)`.
   - Fallback: if the fetch fails (LocalStack not up / no AWS creds), fall back to `ENV` so `bin/rails console` still boots — log a warning.
2. `05-secrets.sh`: seed the dev secret via `awslocal secretsmanager put-secret-value`.
3. Migrate call sites that currently read `ENV.fetch("OPENAI_API_KEY")` (e.g., `lib/ai/provider.rb`) and WhatsApp credentials to `Secrets.fetch(...)`.
4. Keep `credentials.yml.enc` only if needed for non-secret config; document that secrets live in Secrets Manager going forward.

**Acceptance criteria**
- App boots in dev reading all runtime secrets from LocalStack Secrets Manager; removing a key from `.env` does not break the app.
- No new secrets added to `.env`; `Secrets.fetch` used at the edges only.
- `awslocal secretsmanager get-secret-value` returns the seeded JSON in dev; prod secret exists with same shape.

---

### Phase 5 — EventBridge Scheduler (recurring jobs)

**Scope:** Replace `config/recurring.yml` (dead SolidQueue reference) with EventBridge Scheduler rules that enqueue job messages to SQS.

**Approach**
1. Delete/empty `config/recurring.yml` (it references SolidQueue, which is not a gem in this app — dead config).
2. `06-scheduler.sh`: create a one-time + recurring schedule (e.g., nightly maintenance) whose **target is the SQS queue** `tovitu-jobs` with a payload containing the job class + args (e.g., `{"job_class":"MaintenanceJob","arguments":[...]}`).
3. `Queuing::Worker` gains a small payload format handler: if a received payload is a job *invocation* spec rather than a serialized Active Job payload, instantiate the job and `perform_now` (or normalize at enqueue time in the adapter). Keep it explicit and documented — do not auto-`constantize` arbitrary strings without a whitelist.
4. Future recurring work uses the same pattern: Scheduler → SQS → worker.

**Acceptance criteria**
- A scheduled rule fires within its cadence locally and the job executes via the worker.
- `config/recurring.yml` no longer references SolidQueue; nothing references it.
- Schedules are env-parameterized (different rules in dev vs prod) and created idempotently by init scripts.

---

### Phase 6 — SNS Notification Fan-Out (optional)

**Scope:** Wrap the existing in-app notification + email fan-out so external notifications can publish to SNS topics. **Deferred-able** — in-app notifications (`lib/notifications/`) stay DB-backed regardless.

**Approach (when picked up)**
1. `03-topics.sh`: create `tovitu-events` topic; subscribe an SQS queue for local consumption/testing.
2. `lib/notifications/` gains an optional publisher that sends domain events (`adoption_requested`, `status_changed`, …) to SNS; consumers subscribe. Keep `Messaging::`/in-app paths unchanged.

**Acceptance criteria**
- Publishing a domain event puts a message on the SNS topic → subscribed SQS queue in dev.
- In-app notification rows and email sends are unaffected.

---

### Phase 7 — Cognito Auth (largest refactor)

**Scope:** Replace `bcrypt` + `lib/authentication/*` implementations with Cognito User Pools, keeping the service-object interface and Pundit intact. LocalStack emulates `cognito-idp` end-to-end.

**Approach**
1. **Resource setup (`04-cognito.sh`):** user pool (email as username, standard attributes), app client with `ALLOW_USER_PASSWORD_AUTH` (dev convenience) or SRP in prod, verification via Cognito messages → SES.
2. **New `lib/cognito/` seam** (mirrors `Messaging::BaseProvider` style): `Cognito::Client` wrapping `Aws::CognitoIdentityProvider::Client` — `sign_up`, `confirm_sign_up`, `initiate_auth`, `forgot_password`, `confirm_forgot_password`, `admin_get_user`, `admin_create_user` (migration), plus `Cognito::JwtVerifier` (fetch JWKS, verify ID token with the `jwt` gem).
3. **Service objects (`lib/authentication/`) — internals swap, signatures stable:**
   - `register_user` → `Cognito::Client.sign_up` + create/update local `User` (store `cognito_sub`); verification email handled by Cognito (or keep app mailer via custom sender — defer custom Lambda triggers).
   - `verify_email` → `confirm_sign_up(code)`.
   - `authenticate_user` → `initiate_auth` → verify ID token → resolve local `User` by `cognito_sub`.
   - `resend_verification_email` → `resend_confirmation_code`.
   - `send_password_reset`/`reset_password` → `forgot_password`/`confirm_forgot_password`.
4. **User model:** add `cognito_sub` (string, indexed, nullable during dual-mode). Keep `has_secure_password` only during the dual-mode window, then remove `password_digest`.
5. **Sessions:** keep server-side `session[:user_id]`; authenticate once per sign-in via Cognito (verify ID token locally via JWKS). Do not move to stateless JWT everywhere in this phase.
6. **Dual-mode + cutover:** run bcrypt + Cognito side-by-side (feature flag `AUTH_PROVIDER=cognito|bcrypt`); rake task `auth:migrate_users` uses `AdminCreateUser` with temporary passwords + forced change; flip the flag, then drop `password_digest` and the old code paths.
7. **Spec updates:** request specs for register/verify/login/reset updated to hit Cognito-backed flows (LocalStack in test/CI).

**Acceptance criteria**
- Register → confirm → login → logout works end-to-end against LocalStack Cognito in dev.
- Password reset flow works via Cognito (code delivered through SES/LocalStack).
- Existing users can be migrated via the rake task; post-cutover `password_digest` column is dropped.
- Pundit policies and `current_user` semantics unchanged; no auth checks added to views.
- `bcrypt` removed from Gemfile after cutover.

---

### Phase 8 — CloudWatch Logs (deferred, hosting-phase)

**Scope:** Route app logs (Puma, worker, jobs) to CloudWatch Logs. LocalStack emulates `logs`, but shipping is genuinely an *infra* concern and hosting is decoupled per AGENTS.md. **Deferred** — noted here so the app keeps a structured stdout format that a future shipper can consume (already `TaggedLogging.logger(STDOUT)` in production.rb).

**Acceptance criteria (when picked up)**
- Rails logs + `Queuing::Worker` logs appear in CloudWatch Logs (locally: `awslocal logs describe-log-groups`).
- Sensitive data (WhatsApp tokens, passwords, JWTs) filtered by `config/initializers/filter_parameter_logging.rb` (already present — extend as needed).

---

### Phase 9 — Bedrock AI (optional / stretch)

**Scope:** Add a Bedrock-backed implementation of `Ai::Provider` (and optionally embeddings) using LocalStack's mock Bedrock responses. **Not required** for this migration — the app's OpenAI/Anthropic adapters already sit behind provider seams.

**Approach (when picked up)**
1. `Ai::Providers::BedrockProvider` implementing the same contract as `Ai::Provider`; `invoke_model` with Claude model id.
2. Config switch via existing `Rails.configuration.ai` (`AI_PROVIDER` env).
3. LocalStack returns canned mock completions — good for CI, not for realistic output.

**Acceptance criteria**
- Switching `AI_PROVIDER=bedrock` runs AI flows locally with mock responses; switching back restores OpenAI behavior.

---

## Deferred / Out of Scope

| Item | Why deferred |
|---|---|
| **RDS** (prod DB) | LocalStack RDS emulation is API-parity, not a real engine — Active Record dev (and pgvector vector search) needs the real thing. Prod uses RDS/Aurora PostgreSQL via `DATABASE_URL` swap only; local keeps the `pgvector/pgvector:pg16` container. This is a config change, not a code change. |
| **ElastiCache Redis** | Unnecessary — Redis is removed entirely (cache `solid_cache`, cable `solid_cable` on DB, jobs SQS). |
| **Hosting: ECS/ECR, ALB, Route 53, CloudFront, ACM** | Deployment decoupled per AGENTS.md; no deploy tooling until production-ready. Revisit as its own plan. |
| **API Gateway (webhooks)** | The monolith ingests WhatsApp webhooks via a controller; API Gateway adds a layer with little value until hosting (ALB) exists. Revisit with hosting. |
| **WAF, X-Ray, GuardDuty** | Security/monitoring layers over hosted infra; add with hosting. |
| **Route 53 / ACM** | DNS + certs belong to the hosting plan. |
| **SES production access / verified domain** | Part of prod rollout for Phase 3; not a code change. |

---

## Rollout / Sequencing

| Order | Phase | Risk | Depends on |
|---|---|---|---|
| 1 | 0 (Foundation) | Low | — |
| 2 | 1 (S3) | Low | 0 |
| 3 | 2 (SQS jobs) | **High** (largest change) | 0 |
| 4 | 3 (SES) | Low | 0, 2 (mailer queue) |
| 5 | 4 (Secrets) | Low | 0 |
| 6 | 5 (Scheduler) | Low | 0, 2 |
| 7 | 7 (Cognito) | **High** (auth refactor) | 0, 3 (verification email), 4 |
| 8 | 6 (SNS, optional) | Low | 0, 2 |
| 9 | 8, 9 (CloudWatch, Bedrock — optional/deferred) | Low | hosting / stretch |

Phase 2 (SQS) and Phase 7 (Cognito) are the two high-risk items. Both are isolated behind existing seams (Active Job / `lib/authentication`), so they can land independently and be reverted via env flags if needed. Phase 2 should land before 3 (mailer queue) but does not block 1/4.

---

## Risks & Mitigations

1. **SQS adapter correctness** (retries, DLQ, visibility, idempotency): mitigate with a dedicated `lib/queuing/` seam, redrive policies, `ActiveJob::DeserializationError` discard, and request-spec-level job tests that run against LocalStack in CI.
2. **SQS 15-min delay cap**: no delayed jobs today; future long-delay work must use EventBridge Scheduler → SQS (documented in `Queuing::Client`).
3. **LocalStack fidelity gaps** (SES v2 endpoints, Cognito trigger fidelity, scheduler timing): pin behaviors in smoke tests; keep env fallbacks (e.g., SES v1 if v2 gaps; `:test` adapter in test env).
4. **Cognito cutover data loss**: dual-mode flag + `auth:migrate_users` rake task + `cognito_sub` nullable during transition; rollback = flip flag back.
5. **Secrets fallback masking prod errors**: boot fallback to ENV is dev-only (gated by `Rails.env.development?`), so prod never silently boots without Secrets Manager.
6. **MinIO/R2 data**: prod object sync before flipping `active_storage.service`; blob keys unchanged (content-hash keys), so no `active_storage_blobs` migration required.

---

## Success Metrics

- `docker compose up` (postgres + localstack) + `bin/rails queuing:work` runs the **entire** app locally — no Redis, no MinIO, no R2, no SMTP.
- Job throughput: AI jobs enqueued from controllers execute via SQS worker; failures land in DLQs (observable locally).
- Auth flows (register/verify/login/reset) green against LocalStack Cognito; existing specs updated, none skipped.
- Storage/email smoke checks green in dev and CI.
- Zero code changes needed to move from LocalStack to real AWS beyond ENV (endpoint, credentials, resource names).
