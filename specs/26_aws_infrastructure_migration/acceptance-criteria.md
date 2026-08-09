# Acceptance Criteria: AWS Infrastructure Migration — Phase 0: LocalStack Foundation

## AC1: LocalStack boots the full service footprint
```
Given a developer runs `docker compose up -d localstack`
Then LocalStack starts with services s3, sqs, sns, ses, cognito-idp,
    secretsmanager, logs, events, and scheduler
And the health endpoint reports every configured service as "running"
And restarting LocalStack does not duplicate or break provisioned resources
    (idempotent init)
```

## AC2: Resources are provisioned automatically on boot
```
Given LocalStack has started (fresh volume or after restart)
When the init scripts finish
Then an S3 bucket `tovitu-development` exists
And SQS queues `tovitu-jobs`, `tovitu-jobs-dlq`, `tovitu-mailers`, `tovitu-mailers-dlq` exist
    (primary queues have a redrive policy with maxReceiveCount = 5)
And an SNS topic `tovitu-events` exists
And a Cognito user pool named `tovitu` exists with an app client
And a Secrets Manager secret `tovitu/development/runtime` exists
And an EventBridge Scheduler rule `tovitu-nightly-maintenance` exists
And generated IDs (Cognito pool/client) are written to `.localstack/state/cognito.env`
    which is git-ignored
```

## AC3: Smoke task validates the footprint
```
Given LocalStack is running with provisioned resources
When I run `bin/rails aws:smoke`
Then every configured service is checked and prints `✔ <service>`
And the command exits 0

Given LocalStack is NOT running (or a service is missing)
When I run `bin/rails aws:smoke`
Then the command exits 1
And it names the failing service with an actionable message

Given AWS_ENDPOINT_URL is unset and SKIP_AWS_SMOKE=1
When I run `bin/rails aws:smoke`
Then it skips without failing
```

## AC4: AWS clients are centrally configured
```
Given a Rails process boots with AWS_ENDPOINT_URL=http://localhost:4566
When any AWS SDK client is created in a Rails console
Then it uses the LocalStack endpoint without per-client configuration
And region, credentials, and logger come from `config/initializers/aws.rb` / ENV

Given the same code runs in production without AWS_ENDPOINT_URL
When an AWS SDK client is created
Then it uses the default credential chain and real AWS endpoints
```

## AC5: No app behavior changes
```
Given the app previously ran with MinIO storage, Sidekiq/Redis, and bcrypt auth
When Phase 0 lands and LocalStack is running
Then the app boots and behaves exactly as before
    (no storage service switch, no queue adapter switch, no auth change)
And `bin/rails aws:smoke` is the only new runtime behavior
```

## AC6: Developer ergonomics
```
Given a developer runs `bin/setup`
When Docker services (including LocalStack) have started
Then `bin/rails aws:smoke` runs and reports LocalStack health (warning, not failure, when down)

Given a developer runs `make aws-smoke`
Then it executes `bin/rails aws:smoke`
```

## AC7: CI validates the emulation layer
```
Given a PR is opened
When the `aws_localstack` CI job runs
Then it boots LocalStack, waits for health, and runs `bin/rails aws:smoke`
And the job passes only when the full footprint is verified
```

## Edge cases
- LocalStack already running with resources from a previous session → init scripts no-op for existing resources (idempotent).
- LocalStack not running when the app boots → app still boots; `aws:smoke` is the explicit gate.
- Secrets state outlives restart (PERSISTENCE=1) but secret values change → `05-secrets.sh` updates values idempotently.
- Cognito state file missing after a fresh volume → `04-cognito.sh` recreates pool + client and rewrites the file; smoke hints when stale.
- One service fails to start → `aws:smoke` names it and exits 1; CI fails with the service name.
