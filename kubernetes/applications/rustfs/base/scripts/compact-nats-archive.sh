#!/bin/bash
set -euo pipefail

# Daily compaction of nats-archive 1h parquet files into one daily file per
# stream. Source: s3://nats-archive/<stream>/YYYY/MM/DD/HH/<uuid>.parquet
# Target: s3://nats-archive/<stream>/YYYY/MM/DD/daily.parquet
# Source files are deleted only after the daily file is verified.
#
# Required environment variables:
#   RUSTFS_URL   - e.g. http://rustfs-svc.rustfs.svc.cluster.local:9000
#   ACCESS_KEY   - RustFS admin access key
#   SECRET_KEY   - RustFS admin secret key
#   DUCKDB_VERSION - pinned DuckDB CLI version, e.g. v1.1.3
#   COMPACT_DAY  - optional override, format YYYY/MM/DD (defaults to yesterday UTC)

STREAMS="knx ems_esp solaredge_inverter solaredge_powerflow warp_system warp_evse warp_charge_manager warp_charge_tracker warp_meter"

# Image is debian:12-slim — DuckDB's official linux-amd64 build is glibc-linked
# and needs libstdc++/libgcc, both of which alpine does not ship in an
# ABI-compatible form. debian gives us all of that out of the box.
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y --no-install-recommends curl unzip ca-certificates >/dev/null
curl -fsSL -o /tmp/duckdb.zip "https://github.com/duckdb/duckdb/releases/download/${DUCKDB_VERSION}/duckdb_cli-linux-amd64.zip"
unzip -o /tmp/duckdb.zip -d /usr/local/bin
chmod +x /usr/local/bin/duckdb
curl -fsSL -o /usr/local/bin/mc https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x /usr/local/bin/mc
duckdb --version

DAY="${COMPACT_DAY:-$(date -u -d 'yesterday' '+%Y/%m/%d')}"
echo "Compacting day=$DAY"

export MC_CONFIG_DIR=$(mktemp -d)
mc alias set rustfs "$RUSTFS_URL" "$ACCESS_KEY" "$SECRET_KEY"

S3_ENDPOINT_HOST=$(echo "$RUSTFS_URL" | sed 's|^http://||; s|^https://||')

FAILED=""

for STREAM in $STREAMS; do
  SRC_PREFIX="rustfs/nats-archive/$STREAM/$DAY"
  if ! mc ls "$SRC_PREFIX" >/dev/null 2>&1; then
    echo "[$STREAM] no source files for $DAY — skipping"
    continue
  fi

  echo "[$STREAM] merging hour-files into daily.parquet"

  # threads=1 → one HTTP read at a time so rustfs only buffers a single object.
  # memory_limit=256MB → DuckDB streams instead of loading everything into memory.
  # http_retries / http_timeout → tolerate transient rustfs hiccups.
  if ! duckdb -batch <<SQL
INSTALL httpfs;
LOAD httpfs;
SET threads = 1;
SET memory_limit = '256MB';
SET http_retries = 5;
SET http_timeout = 30000;
SET s3_endpoint = '$S3_ENDPOINT_HOST';
SET s3_access_key_id = '$ACCESS_KEY';
SET s3_secret_access_key = '$SECRET_KEY';
SET s3_url_style = 'path';
SET s3_use_ssl = false;
COPY (SELECT * FROM read_parquet('s3://nats-archive/$STREAM/$DAY/*/*.parquet', union_by_name=true))
  TO 's3://nats-archive/$STREAM/$DAY/daily.parquet' (FORMAT PARQUET, COMPRESSION ZSTD);
SQL
  then
    echo "[$STREAM] ERROR duckdb merge failed — leaving hour-files in place"
    FAILED="$FAILED $STREAM"
    sleep 5
    continue
  fi

  if ! mc stat "$SRC_PREFIX/daily.parquet" >/dev/null 2>&1; then
    echo "[$STREAM] ERROR daily.parquet missing after merge — leaving hour-files"
    FAILED="$FAILED $STREAM"
    sleep 5
    continue
  fi

  # Delete the 24 hour-folders (00..23). daily.parquet sits next to them at the day level.
  for H in 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23; do
    mc rm --recursive --force "$SRC_PREFIX/$H/" >/dev/null 2>&1 || true
  done
  echo "[$STREAM] done"

  # Give rustfs a few seconds to release buffers between streams.
  sleep 5
done

if [ -n "$FAILED" ]; then
  echo "Compaction finished for day=$DAY with failures:$FAILED"
  echo "Job will exit non-zero so the next CronJob run retries the failed streams."
  exit 1
fi
echo "Compaction finished for day=$DAY"
