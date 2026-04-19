#!/bin/sh
set -euo pipefail

# Required environment variables:
#   RUSTFS_URL   - e.g. http://rustfs-svc.rustfs.svc.cluster.local:9000
#   BUCKETS      - space-separated list of bucket names to create
#   ACCESS_KEY   - RustFS admin access key
#   SECRET_KEY   - RustFS admin secret key

export MC_CONFIG_DIR=$(mktemp -d)
mc alias set rustfs "$RUSTFS_URL" "$ACCESS_KEY" "$SECRET_KEY"

for BUCKET in $BUCKETS; do
  if ! mc ls "rustfs/$BUCKET" >/dev/null 2>&1; then
    mc mb "rustfs/$BUCKET"
  fi
done

echo "Done"
