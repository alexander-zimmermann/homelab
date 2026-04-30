-- One-shot DDL for the InfluxDB 3 → TimescaleDB historical backfill.
-- Run as superuser (postgres) on the primary; the migration schema mirrors
-- the public hypertables minus the CAGG attachments. Streams in
-- redpanda-connect write here; after verification each table is INSERT…SELECT'd
-- into public and dropped.
--
-- Apply with:
--   kubectl -n timescaledb exec -i timescaledb-db-1 -- psql -U postgres -d homelab < migration_schema.sql
--
-- Rollback: DROP SCHEMA migration CASCADE;

CREATE SCHEMA IF NOT EXISTS migration AUTHORIZATION homelab;
GRANT USAGE ON SCHEMA migration TO connect;

-- ---------- knx (raw nullable already, dpt NOT NULL → backfill uses 'unknown') ----------
-- LIKE INCLUDING CONSTRAINTS only copies CHECK / NOT NULL, not the PK.
-- Backfill streams use ON CONFLICT (time, ga) so PK must exist explicitly.
CREATE TABLE migration.knx (LIKE public.knx INCLUDING DEFAULTS INCLUDING CONSTRAINTS);
ALTER TABLE migration.knx OWNER TO homelab;
SELECT create_hypertable('migration.knx', 'time', chunk_time_interval => INTERVAL '1 day');
ALTER TABLE migration.knx ADD PRIMARY KEY (time, ga);
GRANT INSERT, SELECT ON migration.knx TO connect;

-- ---------- solaredge_inverter (PK time,inverter_id; raw NOT NULL) ----------
CREATE TABLE migration.solaredge_inverter (LIKE public.solaredge_inverter INCLUDING DEFAULTS INCLUDING CONSTRAINTS);
ALTER TABLE migration.solaredge_inverter OWNER TO homelab;
SELECT create_hypertable('migration.solaredge_inverter', 'time', chunk_time_interval => INTERVAL '1 day');
ALTER TABLE migration.solaredge_inverter ADD PRIMARY KEY (time, inverter_id);
GRANT INSERT, SELECT ON migration.solaredge_inverter TO connect;

-- ---------- solaredge_powerflow (PK time,inverter_id; raw NOT NULL) ----------
CREATE TABLE migration.solaredge_powerflow (LIKE public.solaredge_powerflow INCLUDING DEFAULTS INCLUDING CONSTRAINTS);
ALTER TABLE migration.solaredge_powerflow OWNER TO homelab;
SELECT create_hypertable('migration.solaredge_powerflow', 'time', chunk_time_interval => INTERVAL '1 day');
ALTER TABLE migration.solaredge_powerflow ADD PRIMARY KEY (time, inverter_id);
GRANT INSERT, SELECT ON migration.solaredge_powerflow TO connect;

-- ---------- ems_esp (no PK; raw NOT NULL) ----------
CREATE TABLE migration.ems_esp (LIKE public.ems_esp INCLUDING DEFAULTS INCLUDING CONSTRAINTS);
ALTER TABLE migration.ems_esp OWNER TO homelab;
SELECT create_hypertable('migration.ems_esp', 'time', chunk_time_interval => INTERVAL '1 day');
-- Re-run safety: dedup on (time, topic, raw)
CREATE UNIQUE INDEX ON migration.ems_esp (time, topic, md5(raw::text));
GRANT INSERT, SELECT ON migration.ems_esp TO connect;

-- ---------- warp_evse (no PK; raw NOT NULL) ----------
CREATE TABLE migration.warp_evse (LIKE public.warp_evse INCLUDING DEFAULTS INCLUDING CONSTRAINTS);
ALTER TABLE migration.warp_evse OWNER TO homelab;
SELECT create_hypertable('migration.warp_evse', 'time', chunk_time_interval => INTERVAL '1 day');
CREATE UNIQUE INDEX ON migration.warp_evse (time, sub_topic, md5(raw::text));
GRANT INSERT, SELECT ON migration.warp_evse TO connect;

-- ---------- warp_charge_tracker (no PK; raw NOT NULL) ----------
CREATE TABLE migration.warp_charge_tracker (LIKE public.warp_charge_tracker INCLUDING DEFAULTS INCLUDING CONSTRAINTS);
ALTER TABLE migration.warp_charge_tracker OWNER TO homelab;
SELECT create_hypertable('migration.warp_charge_tracker', 'time', chunk_time_interval => INTERVAL '1 day');
CREATE UNIQUE INDEX ON migration.warp_charge_tracker (time, sub_topic, md5(raw::text));
GRANT INSERT, SELECT ON migration.warp_charge_tracker TO connect;

-- ---------- warp_meter (no PK; raw NOT NULL) ----------
CREATE TABLE migration.warp_meter (LIKE public.warp_meter INCLUDING DEFAULTS INCLUDING CONSTRAINTS);
ALTER TABLE migration.warp_meter OWNER TO homelab;
SELECT create_hypertable('migration.warp_meter', 'time', chunk_time_interval => INTERVAL '1 day');
CREATE UNIQUE INDEX ON migration.warp_meter (time, sub_topic, COALESCE(meter_id, -1), md5(raw::text));
GRANT INSERT, SELECT ON migration.warp_meter TO connect;

-- warp_system, warp_charge_manager: keine Influx-Daten → kein Staging-Mirror nötig.
