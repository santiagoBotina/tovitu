#!/bin/bash
# Phase 0 — LocalStack init hook: SQS queues + DLQs.
# Idempotent. Primary queues get a redrive policy (maxReceiveCount = 5) to
# their matching DLQ, so permanently-failing jobs are observable, not lost.
set -e

echo ">>> Initializing LocalStack SQS..."

# DLQs must exist before primary queues so their ARNs can be referenced.
ensure_queue() {
  local queue="$1"
  if awslocal sqs get-queue-url --queue-name "$queue" >/dev/null 2>&1; then
    echo ">>> SQS queue '${queue}' already exists."
    return 0
  fi
  awslocal sqs create-queue --queue-name "$queue" >/dev/null
  echo ">>> SQS queue '${queue}' created."
}

ensure_queue_with_redrive() {
  local queue="$1"
  local dlq="$2"
  local dlq_arn

  if awslocal sqs get-queue-url --queue-name "$queue" >/dev/null 2>&1; then
    # Convergent: enforce desired attributes even on an existing queue so
    # policy/visibility changes propagate across restarts.
    dlq_arn=$(awslocal sqs get-queue-attributes \
      --queue-url "$(awslocal sqs get-queue-url --queue-name "$dlq" --query QueueUrl --output text)" \
      --attribute-names QueueArn \
      --query "Attributes.QueueArn" --output text)
    apply_queue_attributes "$queue" "$dlq_arn"
    echo ">>> SQS queue '${queue}' already exists; attributes updated."
    return 0
  fi

  dlq_arn=$(awslocal sqs get-queue-attributes \
    --queue-url "$(awslocal sqs get-queue-url --queue-name "$dlq" --query QueueUrl --output text)" \
    --attribute-names QueueArn \
    --query "Attributes.QueueArn" --output text)

  # VisibilityTimeout 900s: AI generation jobs can run for minutes; a short
  # timeout would redeliver them mid-run (duplicate execution).
  awslocal sqs create-queue \
    --queue-name "$queue" \
    --attributes "$(queue_attributes "$dlq_arn")" >/dev/null
  echo ">>> SQS queue '${queue}' created with redrive to '${dlq}' (maxReceiveCount=5, visibility 900s)."
}

queue_attributes() {
  local dlq_arn="$1"
  printf '{"VisibilityTimeout":"900","RedrivePolicy":"{\\"deadLetterTargetArn\\":\\"%s\\",\\"maxReceiveCount\\":\\"5\\"}"}' "$dlq_arn"
}

apply_queue_attributes() {
  local queue="$1"
  local dlq_arn="$2"
  local url
  url=$(awslocal sqs get-queue-url --queue-name "$queue" --query QueueUrl --output text)
  awslocal sqs set-queue-attributes \
    --queue-url "$url" \
    --attributes "$(queue_attributes "$dlq_arn")" >/dev/null
}

ensure_queue "tovitu-jobs-dlq"
ensure_queue "tovitu-mailers-dlq"
ensure_queue "tovitu-variants-dlq"

ensure_queue_with_redrive "tovitu-jobs" "tovitu-jobs-dlq"
ensure_queue_with_redrive "tovitu-mailers" "tovitu-mailers-dlq"
# Dedicated queue for image variant generation (Pets::GeneratePhotoVariantsJob,
# ActiveStorage::TransformJob). Keeps vips work off the default queue and lets
# ops run a dedicated worker (SQS_QUEUES=variants) with its own concurrency.
ensure_queue_with_redrive "tovitu-variants" "tovitu-variants-dlq"
