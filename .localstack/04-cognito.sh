#!/bin/bash
# Phase 0 — LocalStack init hook: Cognito user pool + app client.
# Idempotent: discovers the existing pool/client by name, creates them if
# missing. Generated pool id + client id are written to the git-ignored state
# file `.localstack/state/cognito.env` (mounted at .../ready.d/state/).
set -e

POOL_NAME="tovitu"
CLIENT_NAME="tovitu-app"
STATE_DIR="/etc/localstack/init/ready.d/state"
COGNITO_ENV="$STATE_DIR/cognito.env"

echo ">>> Initializing LocalStack Cognito..."

pool_id=$(awslocal cognito-idp list-user-pools --max-results 60 \
  --query "UserPools[?Name=='${POOL_NAME}'].Id" --output text 2>&1 || true)

# cognito-idp is a LocalStack Pro/student feature. Without the Pro image +
# license (LOCALSTACK_IMAGE=localstack/localstack-pro:4 and LOCALSTACK_AUTH_TOKEN)
# the API responds with a license error — skip gracefully instead of failing
# the whole init sequence.
if echo "$pool_id" | grep -qi "not included within your LocalStack license"; then
  echo ">>> Cognito skipped: cognito-idp requires the LocalStack Pro/student image + license (LOCALSTACK_IMAGE=localstack/localstack-pro:4, LOCALSTACK_AUTH_TOKEN)."
  exit 0
fi

pool_id=$(echo "$pool_id" | tr -d '[:space:]')

if [ -z "$pool_id" ] || [ "$pool_id" = "None" ]; then
  pool_id=$(awslocal cognito-idp create-user-pool \
    --pool-name "$POOL_NAME" \
    --username-attributes email \
    --auto-verified-attributes email \
    --alias-attributes email \
    --schema '[{"Name":"email","Required":true,"AttributeDataType":"String"}]' \
    --query "UserPool.Id" --output text)
  echo ">>> Cognito user pool '${POOL_NAME}' created (${pool_id})."
else
  echo ">>> Cognito user pool '${POOL_NAME}' already exists (${pool_id})."
fi

client_id=$(awslocal cognito-idp list-user-pool-clients --user-pool-id "$pool_id" --max-results 60 \
  --query "UserPoolClients[0].ClientId" --output text 2>/dev/null | tr -d '[:space:]' || true)

if [ -z "$client_id" ] || [ "$client_id" = "None" ]; then
  client_id=$(awslocal cognito-idp create-user-pool-client \
    --user-pool-id "$pool_id" \
    --client-name "$CLIENT_NAME" \
    --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
    --query "UserPoolClient.ClientId" --output text)
  echo ">>> Cognito app client '${CLIENT_NAME}' created (${client_id})."
else
  echo ">>> Cognito app client '${CLIENT_NAME}' already exists (${client_id})."
fi

mkdir -p "$STATE_DIR"
cat > "$COGNITO_ENV" <<EOF
COGNITO_USER_POOL_ID=$pool_id
COGNITO_CLIENT_ID=$client_id
EOF
echo ">>> Cognito state written to ${COGNITO_ENV}."
