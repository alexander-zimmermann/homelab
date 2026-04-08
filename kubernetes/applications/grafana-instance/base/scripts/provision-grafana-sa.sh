#!/bin/sh
set -euo pipefail

# Required environment variables:
#   GRAFANA_URL        - e.g. http://grafana.grafana-instance.svc.cluster.local
#   SA_NAME            - Grafana service account name
#   SA_ROLE            - Grafana service account role (e.g. Viewer, Editor, Admin)
#   TOKEN_NAME         - Grafana token name
#   SECRET_NAME        - Kubernetes secret name to create
#   SECRET_NAMESPACE   - Namespace for the Kubernetes secret
#   ADMIN_USER         - Grafana admin username
#   ADMIN_PASS         - Grafana admin password

# Skip if secret already exists
if kubectl get secret "$SECRET_NAME" -n "$SECRET_NAMESPACE" >/dev/null 2>&1; then
  echo "Secret $SECRET_NAME already exists, skipping"
  exit 0
fi

# Get existing SA or create it
SA_ID=$(curl -sf -u "$ADMIN_USER:$ADMIN_PASS" \
  "$GRAFANA_URL/api/serviceaccounts/search?query=$SA_NAME" \
  | jq -r --arg name "$SA_NAME" '.serviceAccounts[] | select(.name == $name) | .id' | head -1)

if [ -z "$SA_ID" ]; then
  echo "Creating Grafana Service Account '$SA_NAME'..."
  SA_ID=$(curl -sf -X POST -u "$ADMIN_USER:$ADMIN_PASS" \
    -H "Content-Type: application/json" \
    "$GRAFANA_URL/api/serviceaccounts" \
    -d "{\"name\":\"$SA_NAME\",\"role\":\"$SA_ROLE\"}" | jq -r '.id')
fi
echo "SA ID: $SA_ID"

# Create token
TOKEN=$(curl -sf -X POST -u "$ADMIN_USER:$ADMIN_PASS" \
  -H "Content-Type: application/json" \
  "$GRAFANA_URL/api/serviceaccounts/$SA_ID/tokens" \
  -d "{\"name\":\"$TOKEN_NAME\"}" | jq -r '.key')

# Store as Kubernetes Secret
kubectl create secret generic "$SECRET_NAME" \
  -n "$SECRET_NAMESPACE" \
  --from-literal=GRAFANA_HOMEPAGE_SA_TOKEN="$TOKEN"

echo "Done: secret $SECRET_NAME created in $SECRET_NAMESPACE"
