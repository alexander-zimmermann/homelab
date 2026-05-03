#!/bin/sh
set -eu

# Required environment variables:
#   NAMESPACE   - crowdsec namespace
#   SELECTOR    - label selector for the LAPI pod
#   DURATION    - inactivity threshold passed to cscli machines prune

POD=$(kubectl -n "$NAMESPACE" get pod -l "$SELECTOR" \
  -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' \
  | awk '{print $1}')

if [ -z "$POD" ]; then
  echo "no running lapi pod found"
  exit 1
fi

echo "pruning stale machines via $POD"
kubectl -n "$NAMESPACE" exec "$POD" -- cscli machines prune --duration "$DURATION" --force
