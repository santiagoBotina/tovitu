#!/bin/bash
# Phase 0 — LocalStack init hook: Secrets Manager runtime secret.
# Idempotent: creates `tovitu/development/runtime` if missing, and always
# refreshes its value so env changes are picked up across restarts.
# Cognito pool/client ids (written by 04-cognito.sh) are injected when present.
set -e

SECRET_NAME="tovitu/development/runtime"
STATE_DIR="/etc/localstack/init/ready.d/state"
COGNITO_ENV="$STATE_DIR/cognito.env"

echo ">>> Initializing LocalStack Secrets Manager..."

COGNITO_USER_POOL_ID=""
COGNITO_CLIENT_ID=""
if [ -f "$COGNITO_ENV" ]; then
  # shellcheck disable=SC1090
  . "$COGNITO_ENV"
fi

SECRET_JSON="{\"OPENAI_API_KEY\":\"placeholder-local\",\"WHATSAPP_API_TOKEN\":\"placeholder-local\",\"WHATSAPP_PHONE_NUMBER_ID\":\"placeholder-local\",\"WHATSAPP_WEBHOOK_VERIFY_TOKEN\":\"placeholder-local\",\"S3_BUCKET\":\"tovitu-development\",\"SES_FROM\":\"no-reply@example.com\",\"COGNITO_USER_POOL_ID\":\"${COGNITO_USER_POOL_ID}\",\"COGNITO_CLIENT_ID\":\"${COGNITO_CLIENT_ID}\"}"

if awslocal secretsmanager describe-secret --secret-id "$SECRET_NAME" >/dev/null 2>&1; then
  echo ">>> Secret '${SECRET_NAME}' already exists; updating value."
  awslocal secretsmanager put-secret-value --secret-id "$SECRET_NAME" --secret-string "$SECRET_JSON" >/dev/null
else
  awslocal secretsmanager create-secret --name "$SECRET_NAME" --secret-string "$SECRET_JSON" >/dev/null
  echo ">>> Secret '${SECRET_NAME}' created."
fi
