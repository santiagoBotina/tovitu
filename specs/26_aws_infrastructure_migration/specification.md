# Specification: AWS Infrastructure Migration — Phase 0: LocalStack Foundation

**Domain:** Infrastructure, AWS
**Priority:** 2 (foundational enabler — every later phase depends on this)
**Status:** Draft (implementation ready)
**Source plan:** `specs/26_aws_infrastructure_migration_plan.md` (Phase 0)
**Owner:** Backend/Infra coordination. Touches `Gemfile`, `config/initializers/`, `docker-compose.yml`, `.localstack/`, `lib/tasks/`, `Makefile`, `bin/setup`, `.github/workflows/ci.yml`. No business behavior changes.

---

## Overview

Phase 0 makes LocalStack the local equivalent of every AWS service the migration will use: `s3`, `sqs`, `sns`, `ses`, `cognito-idp`, `secretsmanager`, `logs`, `events`, `scheduler`. It provisions all resources idempotently on boot, centralizes AWS client configuration in one initializer, adds the SDK gems later phases need, and provides a smoke task that proves the footprint is alive in dev, setup, and CI.

No application behavior changes in this phase. The app continues to run exactly as it does today (MinIO storage, Sidekiq/Redis, bcrypt auth) — Phase 0 only stands up the AWS emulation layer beneath it.

---

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| SDK footprint | Add all AWS SDK gems now (`s3`, `sqs`, `sesv2`, `cognitoidentityprovider`, `secretsmanager`, `sns`, `scheduler`), `require: false`, required lazily by their consumers | One bundle update; all gems share `aws-sdk-core`; later phases never touch the Gemfile |
| Client config | Single `config/initializers/aws.rb` sets `Aws.config` from ENV (`AWS_ENDPOINT_URL`, `AWS_REGION`, static creds, logger). App code never hardcodes `localhost:4566` | Same code runs against LocalStack and real AWS; only ENV changes |
| SDK env-var support | Rely on SDK v3's native `AWS_ENDPOINT_URL` handling where available; the initializer is belt-and-braces for older clients and centralized logging | Fewer moving parts, one place to debug |
| Service footprint | `SERVICES: s3,sqs,sns,ses,cognito-idp,secretsmanager,logs,events,scheduler` + `PERSISTENCE: 1` | Full emulated surface; state survives restarts |
| Provisioning | LocalStack init hooks in `.localstack/init/ready.d/` (already mounted via `${LOCALSTACK_VOLUME}`), numbered `NN-*.sh`, idempotent (create-if-not-exists) | Boot-time, no manual steps; mirrors existing `setup-s3.sh` pattern |
| Resource identity | Discover by name where the SDK supports it (`get_queue_url`, `list_user_pools`, `list_topics`). Generated IDs (Cognito pool id) written to git-ignored `.localstack/state/*.env` | No hardcoded ARNs/IDs in code; state survives restarts |
| Smoke | `bin/rails aws:smoke` verifies every configured service; wired into `bin/setup`, `Makefile`, and a CI job | Fail-fast signal that the emulation layer is alive |
| Logging | `Aws.config[:logger] = Rails.logger` at `:info`; debug via `AWS_LOG_LEVEL` | Request tracing for emulated calls without noise |
| Fidelity | SES v2 preferred; if LocalStack gaps surface, fall back to SES v1 or SMTP (see Risks) | Smoke asserts API success, not delivery semantics |

---

## Changes

### 1. Gemfile

Add (all with `require: false` — each consumer requires its own client):

```ruby
gem "aws-sdk-s3", require: false                  # already present
gem "aws-sdk-sqs", require: false
gem "aws-sdk-sesv2", require: false
gem "aws-sdk-cognitoidentityprovider", require: false
gem "aws-sdk-secretsmanager", require: false
gem "aws-sdk-sns", require: false
gem "aws-sdk-scheduler", require: false
```

`aws-sdk-s3` moves to the main dependency block (it already is). Run `bundle install` once.

### 2. `config/initializers/aws.rb` (new)

Responsibilities:
- `Aws.config[:region] = ENV.fetch("AWS_REGION", "us-east-1")`.
- If `ENV["AWS_ENDPOINT_URL"]` is present → `Aws.config[:endpoint] = ENV["AWS_ENDPOINT_URL"]`.
- If `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` present → `Aws.config[:credentials] = Aws::Credentials.new(...)`; else leave the default credential chain (IAM roles in prod).
- `Aws.config[:logger] = Rails.logger`; `:log_level` from `AWS_LOG_LEVEL` (default `:info`).
- No auto-require of clients here — consumers (`lib/queuing/`, etc.) require their own.

Guard: in `test` env, keep config but never fail boot when LocalStack is absent (smoke task is the explicit gate).

### 3. `docker-compose.yml` — `localstack` service only

- `SERVICES: s3,sqs,sns,ses,cognito-idp,secretsmanager,logs,events,scheduler`
- `PERSISTENCE: "1"`
- Keep existing healthcheck, ports, and the `${LOCALSTACK_VOLUME}:/etc/localstack/init/ready.d` mount.
- **No other service changes in Phase 0** (MinIO/Redis removal happens in Phases 1–2).

### 4. `.localstack/init/ready.d/` provisioning scripts

Replace `setup-s3.sh` with numbered scripts (keep the `awslocal` + echo pattern). Each script is idempotent and `set -e`.

| Script | Resources created |
|--------|-------------------|
| `01-storage.sh` | S3 bucket `tovitu-development` (`mb --ignore-existing`) |
| `02-queues.sh` | SQS queues `tovitu-jobs`, `tovitu-jobs-dlq`, `tovitu-mailers`, `tovitu-mailers-dlq`; redrive policy `maxReceiveCount: 5` on the two primary queues |
| `03-topics.sh` | SNS topic `tovitu-events` |
| `04-cognito.sh` | Cognito user pool `tovitu` (email as username) + app client (SRP; `ALLOW_USER_PASSWORD_AUTH` in dev); writes pool id + client id to `.localstack/state/cognito.env` |
| `05-secrets.sh` | Secrets Manager secret `tovitu/development/runtime` (JSON: `OPENAI_API_KEY`, `WHATSAPP_*`, `S3_BUCKET`, `SES_FROM`, Cognito ids) |
| `06-scheduler.sh` | EventBridge Scheduler rule `tovitu-nightly-maintenance` targeting SQS `tovitu-jobs` (payload: job invocation spec) |

State directory `.localstack/state/` is created by scripts and **git-ignored**.

### 5. `.gitignore`

Add `.localstack/state/`.

### 6. `.env.example`

Add (keep `MINIO_*`/`R2_*` until Phase 1 retires them):

```
AWS_ENDPOINT_URL="http://localhost:4566"
AWS_REGION="us-east-1"
AWS_ACCESS_KEY_ID="test"
AWS_SECRET_ACCESS_KEY="test"
S3_BUCKET="tovitu-development"
SQS_QUEUE_PREFIX="tovitu"
AWS_LOG_LEVEL="info"
```

### 7. `lib/tasks/aws/smoke.rake` (new)

`bin/rails aws:smoke` — checks each configured service and prints `✔ <service>`:

- S3: `list_buckets` includes `S3_BUCKET`
- SQS: `get_queue_url` for `tovitu-jobs`, `tovitu-jobs-dlq`, `tovitu-mailers`, `tovitu-mailers-dlq`
- SNS: `list_topics` includes `tovitu-events`
- SES: `list_identities` succeeds (may be empty)
- Secrets: `describe_secret` for `tovitu/development/runtime`
- Cognito: `list_user_pools` includes pool named `tovitu` (hint if `.localstack/state/cognito.env` missing)
- Scheduler: `list_schedules` succeeds (rule exists)

Exit 1 with an actionable message naming the failing service. `SKIP_AWS_SMOKE=1` skips (offline dev). Logs to stdout for CI.

### 8. `Makefile`

- Add `aws-smoke` target → `bin/rails aws:smoke`.
- Update `localstack-up` to wait for the full service set via the LocalStack health endpoint (`_localstack/health` lists each service, not just `s3`).

### 9. `bin/setup`

After Docker services start, run `bin/rails aws:smoke` with a warning (not a hard failure) when LocalStack is not running.

### 10. CI — `.github/workflows/ci.yml`

New job `aws_localstack` (independent of scan/lint):
- `docker compose up -d localstack`; wait for health.
- `bin/rails aws:smoke` with `AWS_ENDPOINT_URL`, region, and test creds set on the job.
- No DB required.

---

## Data Model

None. Phase 0 introduces **no migrations** and no schema changes.

---

## Out of Scope (this phase)

- MinIO/R2 retirement and Active Storage switch to S3 (Phase 1)
- SQS Active Job adapter, worker, DLQ consumption (Phase 2)
- SES Action Mailer delivery method (Phase 3)
- Secrets Manager consumption at boot (Phase 4)
- EventBridge Scheduler job consumer (Phase 5)
- SNS fan-out consumers (Phase 6)
- Cognito auth swap (Phase 7)
- CloudWatch log shipping, hosting, API Gateway

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| LocalStack SES v2 API gaps | Smoke asserts API success; fallback to SES v1 or SMTP in Phase 3 if needed |
| LocalStack scheduler timing fidelity | Smoke asserts rule existence; execution semantics validated in Phase 5 |
| Cognito pool id changes across restarts | `.localstack/state/cognito.env` + discovery-by-name + `PERSISTENCE=1` |
| SDK gem version conflicts (shared `aws-sdk-core`) | Single `bundle install`; all SDK gems resolve to one core version; lockfile reviewed |
| Init scripts not idempotent (double-provision on restart) | Every script uses create-if-not-exists guards; verified by running `docker compose restart localstack` twice |

---

## Rollout

1. Gemfile + `bundle install`.
2. `config/initializers/aws.rb`.
3. `docker-compose.yml` SERVICES/PERSISTENCE.
4. `.localstack/init/ready.d/*.sh` + `.gitignore` + `.env.example`.
5. `lib/tasks/aws/smoke.rake` + Makefile + `bin/setup`.
6. CI job.
7. Verify: `docker compose up -d localstack` → `bin/rails aws:smoke` green → existing app still boots (MinIO storage and Sidekiq untouched).
