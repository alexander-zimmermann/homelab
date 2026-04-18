#!/bin/sh
# Idempotently register the downsample_1h scheduled trigger.
# Inputs (environment):
#   INFLUXDB_URL         — InfluxDB 3 base URL
#   INFLUXDB3_AUTH_TOKEN — admin token
#   PLUGIN_PATH          — absolute path to the plugin file (mounted ConfigMap)
#   TRIGGER_NAME         — name of the trigger (e.g. downsample_1h)
#   TRIGGER_DATABASE     — database the trigger runs against (source: homelab)
#   TRIGGER_SPEC         — CLI trigger spec (e.g. "cron:5 * * * *")
set -eu

trigger_exists() {
  influxdb3 show triggers --host "$INFLUXDB_URL" --token "$INFLUXDB3_AUTH_TOKEN" \
    --database "$TRIGGER_DATABASE" | grep -q " $TRIGGER_NAME "
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
  --path "$PLUGIN_PATH" \
  --upload \
  "$TRIGGER_NAME"
echo "Trigger '$TRIGGER_NAME' created"
