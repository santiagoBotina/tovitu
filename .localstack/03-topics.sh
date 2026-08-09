#!/bin/bash
# Phase 0 — LocalStack init hook: SNS topic (optional fan-out seam).
# Idempotent: creates `tovitu-events` if it does not exist.
set -e

TOPIC_NAME="tovitu-events"

echo ">>> Initializing LocalStack SNS..."

if awslocal sns list-topics --query "Topics[?ends_with(TopicArn, ':${TOPIC_NAME}')].TopicArn" --output text 2>/dev/null | grep -q "${TOPIC_NAME}"; then
  echo ">>> SNS topic '${TOPIC_NAME}' already exists."
else
  awslocal sns create-topic --name "$TOPIC_NAME" >/dev/null
  echo ">>> SNS topic '${TOPIC_NAME}' created."
fi
