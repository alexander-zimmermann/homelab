#!/bin/sh
# Idempotently create a list of InfluxDB 3 Core databases.
# Inputs (environment):
#   INFLUXDB_URL         — InfluxDB 3 Core base URL (e.g. http://influxdb:8181)
#   INFLUXDB3_AUTH_TOKEN — admin token with create permissions
#   DATABASES            — space-separated list of database names
set -eu

for db in $DATABASES; do
  if influxdb3 show databases --host "$INFLUXDB_URL" --token "$INFLUXDB3_AUTH_TOKEN" | grep -qx "$db"; then
    echo "Database '$db' already exists — skipping"
  else
    influxdb3 create database --host "$INFLUXDB_URL" --token "$INFLUXDB3_AUTH_TOKEN" "$db"
    echo "Created database '$db'"
  fi
done
