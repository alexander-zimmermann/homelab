#!/bin/sh
# Idempotently create/update InfluxDB 3 Enterprise databases with optional retention.
# Inputs (environment):
#   INFLUXDB_URL         — InfluxDB 3 base URL (e.g. http://influxdb3:8181)
#   INFLUXDB3_AUTH_TOKEN — admin token with create permissions
#   DATABASES            — space-separated list of "name:retention" pairs.
#                          Use "0" for infinite retention (flag omitted).
#                          Example: "homelab:365d homelab_1h:0"
set -eu

db_exists() {
  influxdb3 show databases --host "$INFLUXDB_URL" --token "$INFLUXDB3_AUTH_TOKEN" | grep -q " $1 "
}

for entry in $DATABASES; do
  name="${entry%%:*}"
  retention="${entry#*:}"
  if [ "$name" = "$retention" ]; then
    retention="0"
  fi

  retention_args=""
  if [ "$retention" != "0" ]; then
    retention_args="--retention-period $retention"
  fi

  if db_exists "$name"; then
    echo "Database '$name' already exists — updating retention to '$retention'"
    # shellcheck disable=SC2086
    influxdb3 update database --host "$INFLUXDB_URL" --token "$INFLUXDB3_AUTH_TOKEN" $retention_args "$name"
  else
    # shellcheck disable=SC2086
    influxdb3 create database --host "$INFLUXDB_URL" --token "$INFLUXDB3_AUTH_TOKEN" $retention_args "$name"
    echo "Created database '$name' (retention=$retention)"
  fi
done
