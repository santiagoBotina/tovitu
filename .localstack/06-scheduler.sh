#!/bin/bash
# Phase 0 — LocalStack init hook: EventBridge Scheduler schedule.
# Idempotent: creates `tovitu-nightly-maintenance` targeting the `tovitu-jobs`
# SQS queue with a job-invocation payload. Execution semantics are validated in
# Phase 5; this phase only asserts the rule exists.
set -e

SCHEDULE_NAME="tovitu-nightly-maintenance"
QUEUE_NAME="tovitu-jobs"
ROLE_ARN="arn:aws:iam::000000000000:role/scheduler-sqs"
PAYLOAD='{"job_class":"MaintenanceJob","arguments":[]}'

echo ">>> Initializing LocalStack EventBridge Scheduler..."

if awslocal scheduler get-schedule --name "$SCHEDULE_NAME" >/dev/null 2>&1; then
  echo ">>> Scheduler schedule '${SCHEDULE_NAME}' already exists."
  exit 0
fi

queue_arn=$(awslocal sqs get-queue-attributes \
  --queue-url "$(awslocal sqs get-queue-url --queue-name "$QUEUE_NAME" --query QueueUrl --output text)" \
  --attribute-names QueueArn \
  --query "Attributes.QueueArn" --output text)

input_escaped=$(printf '%s' "$PAYLOAD" | sed 's/"/\\"/g')
target="{\"Arn\":\"${queue_arn}\",\"RoleArn\":\"${ROLE_ARN}\",\"Input\":\"${input_escaped}\"}"

awslocal scheduler create-schedule \
  --name "$SCHEDULE_NAME" \
  --schedule-expression "cron(0 3 * * ? *)" \
  --flexible-time-window '{"Mode":"OFF"}' \
  --target "$target" >/dev/null

echo ">>> Scheduler schedule '${SCHEDULE_NAME}' created -> ${QUEUE_NAME}."
