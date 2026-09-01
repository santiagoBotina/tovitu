# Plan: CI & Database Reliability — PostgreSQL Version Alignment (Epic 3)

**Domain:** CI/CD, Database Infrastructure
**Priority:** 1 (High) — blocks all CI merges
**Status:** Draft
**Tracks:** Epic "CI and Database Reliability" (Stories 3.1–3.4)

---

## Overview

The GitHub Actions CI pipeline fails at `bin/rails db:test:prepare` because the generated `db/structure.sql` contains `SET transaction_timeout = 0;` — a configuration parameter **PostgreSQL 17+** writes into SQL dumps — but the PostgreSQL server used by CI is **PostgreSQL 16**, which does not recognize `transaction_timeout`. The result: `psql … --file db/structure.sql tovitu_test` aborts with `ERROR: unrecognized configuration parameter "transaction_timeout"`.

The fix is to **align PostgreSQL versions across development and CI** and regenerate the structure file on the agreed version — not to hand-edit the schema after every change.

---

## Current State (confirmed in code & environment)

- **Local/development environment:**
  - PostgreSQL **server 17.10** (Homebrew, `aarch64-apple-darwin`).
  - `psql` client **17.10**.
  - `db/structure.sql` was generated on PostgreSQL 17: it contains `SET transaction_timeout = 0;` (line 4) among the standard `SET` preamble. `transaction_timeout` was introduced in PostgreSQL 17.
- **Docker/CI environment:**
  - `docker-compose.yml` runs `pgvector/pgvector:pg16` (PostgreSQL 16 + pgvector).
  - The GitHub Actions `test` job starts PostgreSQL via `docker compose up -d --wait postgres`, then runs `bin/rails db:test:prepare`, which loads `db/structure.sql` into `tovitu_test` → fails on `transaction_timeout`.
- **Repository configuration:**
  - `config/application.rb` sets `config.active_record.schema_format = :sql` → **`db/structure.sql` is the source of truth** for the test database.
  - `config/database.yml` uses standard host/port/user/password envs (`DB_HOST`, `DB_PORT`, `DB_USERNAME`, `DB_PASSWORD`) — consistent between local and CI.
  - Git history shows version churn: `chore: upgrade pgvector to 17` (8fad97b) followed by `chore: set pgvector to v16 again` (6a2d27f) — the `structure.sql` appears to have been dumped while the environment was on PostgreSQL 17 and **was not regenerated** after reverting to 16.

**Root cause:** PostgreSQL version mismatch. The schema dump was produced by PostgreSQL 17; CI serves PostgreSQL 16.

---

## User Story

> As a developer,
> I want CI to use the same PostgreSQL version that produces the schema,
> so that `db:test:prepare` always succeeds and the pipeline is green without manual schema edits.

---

## Requirements & Proposed Behavior

### REQ-47-1 — Document the root cause (Story 3.1)

- The implementation/PR must state the exact versions involved (local server + client, CI server + client) and the confirmed root cause above.
- Verify the versions at implementation time — do not assume: run `psql --version` locally, check the running server version, and confirm the CI PostgreSQL version from the workflow/docker image.

### REQ-47-2 — Standardize PostgreSQL versions (Story 3.2)

Align all environments on one PostgreSQL major version. Two viable directions:

- **Option A — Move CI/docker to PostgreSQL 17.** Matches the current local development environment (17.10). Update `docker-compose.yml` to `pgvector/pgvector:pg17` (verify pgvector compatibility for 17), regenerate `structure.sql` on 17, and pin the version.
- **Option B — Move local development to PostgreSQL 16.** Matches the current docker/CI image. Requires contributors to install/switch to PG 16 locally, regenerate `structure.sql` on 16, and document the setup.

**Selection criteria (evaluate during implementation, founder/team sign-off):**
- Which environment has the majority of active contributors (fewer forced changes wins).
- Current-stable support and pgvector availability per version.
- The requirement's preference: align versions **intentionally**, never leave them drifting.

**Recommendation to validate first:** Option A (dev is already on 17; CI and docker move to 17; regenerate structure.sql on 17). If the team prefers maximum stability on 16, Option B with a documented local upgrade path is acceptable — the choice must be explicit and pinned either way.

### REQ-47-3 — Regenerate the structure file (Story 3.3)

After versions are standardized:

```bash
bin/rails db:structure:dump
```

(or the project's equivalent — Rails 8 with `schema_format = :sql`).

- The regenerated `db/structure.sql` must **not contain configuration statements unsupported** by the PostgreSQL version used in CI.
- Verify `transaction_timeout` is absent (PG 16) or supported (PG 17).
- The fix must **not require manually modifying `db/structure.sql`** after every schema change.

### REQ-47-4 — Pin the PostgreSQL version explicitly (Story 3.2)

- Pin the PostgreSQL major version in CI/docker configuration so future drift is prevented:
  - `docker-compose.yml` service image pinned to the chosen major (e.g., `pgvector/pgvector:pg17`), and
  - where possible, an explicit assertion of the server version in CI (e.g., `SELECT version();` step or a smoke check) so a mismatch fails loudly.

### REQ-47-5 — Validate the full pipeline (Story 3.4)

The fix is complete only when the entire workflow succeeds:

- Database creation.
- Schema loading.
- Test database preparation.
- Test suite execution.
- All remaining CI stages (ruby scan, js scan, lint, aws_localstack).

---

## Acceptance Criteria

- **AC-47-1** — The root cause of the PostgreSQL compatibility issue is identified and documented in the implementation/PR (versions + mechanism).
- **AC-47-2** — PostgreSQL versions are intentionally configured and compatible across development and CI.
- **AC-47-3** — `transaction_timeout` no longer causes schema-loading failures.
- **AC-47-4** — `bin/rails db:test:prepare` completes successfully in CI.
- **AC-47-5** — The test database is created successfully.
- **AC-47-6** — `db/structure.sql` can be loaded by the PostgreSQL version used in GitHub Actions.
- **AC-47-7** — The complete GitHub Actions workflow passes.
- **AC-47-8** — The fix does not require manually modifying `db/structure.sql` after every schema change.
- **AC-47-9** — The PostgreSQL version is explicitly pinned or otherwise intentionally managed in CI to prevent future version drift.

---

## Success Metrics

- **Green CI:** the full workflow passes on every PR after the fix.
- **Zero manual schema edits:** no human edits to `db/structure.sql` (verified via git history + code review).
- **Version certainty:** the PostgreSQL version is documented and pinned; a future version change is an explicit, reviewed action.

---

## Test Strategy

- **CI itself is the primary validation:** the `test` job must pass end-to-end (db create → schema load → test prepare → rspec).
- **Local validation:** run `bin/rails db:test:prepare` against the standardized version locally before pushing.
- **Version assertion:** add a CI step that prints/asserts the PostgreSQL server version (e.g., `psql -c 'SELECT version();'`) so version drift fails loudly instead of surfacing as an obscure schema error.
- **Regression check:** confirm the existing unit-test stage and aws_localstack stage still pass after any workflow change.

---

## Scope

**In scope:** investigation + documentation of the version mismatch; standardizing the PostgreSQL version across development, docker-compose, and CI; regenerating `db/structure.sql` on the chosen version; pinning the version in CI/docker; adding a version assertion; validating the complete pipeline.

**Out of scope:** upgrading/downgrading application code to use PG-specific features; changing the schema format away from `:sql`; altering database configuration beyond the version alignment; other CI failures unrelated to this issue.

---

## Risks

- **pgvector compatibility per version** — the app uses the `vector` extension; the chosen image must include a compatible pgvector build. Verify before finalizing the image tag.
- **Contributor environment drift** — contributors on a different PG version than the pinned one will regenerate incompatible structure files; mitigated by documentation (README) and the CI version assertion.
- **Structure-file diff noise** — regenerating the dump may produce unrelated diffs; review the diff carefully and keep it limited to version-related changes.
- **"Fix by deleting the line" temptation** — hand-editing `transaction_timeout` out of the file would hide the mismatch and break again on the next dump; explicitly rejected by AC-47-8.
- **Option B forcing local changes** — if the team is mostly on PG 17 locally, downgrading everyone is costly; mitigated by the selection criteria (prefer the majority environment).

---

## Dependencies

- **None code-level.** This is an infrastructure/CI reliability fix and can be scheduled independently of Epics 1 and 2.
- **Blocks:** all PRs currently failing CI until merged.
- **Related:** `.github/workflows/ci.yml` (test job), `docker-compose.yml` (postgres service), `config/application.rb` (schema_format), `db/structure.sql`.