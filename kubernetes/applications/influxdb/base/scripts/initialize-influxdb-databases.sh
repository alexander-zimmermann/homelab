#!/bin/sh
# Idempotently create/update InfluxDB 3 Enterprise databases with retention.
# Inputs (environment):
#   INFLUXDB_URL         — InfluxDB 3 base URL (e.g. http://influxdb3:8181)
#   INFLUXDB3_AUTH_TOKEN — admin token with create permissions
#   DATABASES            — space-separated "name:retention" pairs.
#                          Retention values are passed through to the CLI:
#                          a duration like "365d" or "none" to clear.
#                          Example: "homelab:365d homelab_1h:none"
set -eu

db_exists() {
  influxdb3 show databases --host "$INFLUXDB_URL" --token "$INFLUXDB3_AUTH_TOKEN" | grep -q " $1 "
}

for entry in $DATABASES; do
  name="${entry%%:*}"
  retention="${entry#*:}"

  if db_exists "$name"; then
    echo "Updating '$name' retention → $retention"
    influxdb3 update database --host "$INFLUXDB_URL" --token "$INFLUXDB3_AUTH_TOKEN" \
      --database "$name" --retention-period "$retention"
  else
    # CLI doesn't support "none" for creation, so we have to conditionally include the argument.
    if [ "$retention" != "none" ]; then
      retention_args="--retention-period $retention"
    else
      retention_args=""
    fi

    echo "Creating '$name' (retention=$retention)"
    # shellcheck disable=SC2086
    influxdb3 create database --host "$INFLUXDB_URL" --token "$INFLUXDB3_AUTH_TOKEN" \
      $retention_args "$name"
  fi
done
