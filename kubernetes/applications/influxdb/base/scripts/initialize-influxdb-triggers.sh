#!/bin/sh
# Idempotently register the downsample_1h scheduled trigger.
# Inputs (environment):
#   INFLUXDB_URL         — InfluxDB 3 base URL
#   INFLUXDB3_AUTH_TOKEN — admin token
#   PLUGIN_FILENAME      — filename of the plugin inside the server's plugin-dir
#                          (mounted at /plugins via values.yaml extraVolumes)
#   TRIGGER_NAME         — name of the trigger (e.g. downsample_1h)
#   TRIGGER_DATABASE     — database the trigger runs against (source: homelab)
#   TRIGGER_SPEC         — CLI trigger spec (6-field cron, e.g. "cron:0 5 * * * *")
set -eu

# Triggers live in a per-database system table, so we check existence via SQL.
trigger_exists() {
  influxdb3 query \
    --host "$INFLUXDB_URL" \
    --token "$INFLUXDB3_AUTH_TOKEN" \
    --database "$TRIGGER_DATABASE" \
    "SELECT trigger_name FROM system.processing_engine_triggers WHERE trigger_name = '$TRIGGER_NAME'" \
    | grep -q "$TRIGGER_NAME"
}

if trigger_exists; then
  echo "Trigger '$TRIGGER_NAME' already exists on '$TRIGGER_DATABASE' — skipping"
  exit 0
fi

echo "Creating trigger '$TRIGGER_NAME' on '$TRIGGER_DATABASE' (spec: $TRIGGER_SPEC)"
influxdb3 create trigger \
  --host "$INFLUXDB_URL" \
  --token "$INFLUXDB3_AUTH_TOKEN" \
  --database "$TRIGGER_DATABASE" \
  --trigger-spec "$TRIGGER_SPEC" \
  --path "$PLUGIN_FILENAME" \
  "$TRIGGER_NAME"
echo "Trigger '$TRIGGER_NAME' created"
