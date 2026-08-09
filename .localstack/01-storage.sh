#!/bin/bash
# Phase 0 — LocalStack init hook: S3 storage bucket.
# Idempotent: creates `tovitu-development` if it does not exist.
set -e

BUCKET="tovitu-development"

echo ">>> Initializing LocalStack S3..."

if awslocal s3 ls "s3://${BUCKET}" >/dev/null 2>&1; then
  echo ">>> S3 bucket '${BUCKET}' already exists."
else
  awslocal s3 mb "s3://${BUCKET}"
  echo ">>> S3 bucket '${BUCKET}' created."
fi
