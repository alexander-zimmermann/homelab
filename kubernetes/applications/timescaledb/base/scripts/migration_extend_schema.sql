-- Phase B (#757) — extend hot tables with Influx-only typed cols, make raw
-- nullable, and add 365d retention. Idempotent where possible: ADD COLUMN
-- IF NOT EXISTS, ALTER COLUMN DROP NOT NULL is no-op if already nullable,
-- add_retention_policy is wrapped to skip if already configured.
--
-- CAGGs are already materialized_only = true (verified live), so the flip
-- step from the issue is intentionally omitted.
--
-- Apply with:
--   kubectl -n timescaledb exec -i timescaledb-db-1 -- psql -U postgres -d homelab < migration_extend_schema.sql
--
-- After apply: live streams keep writing the existing typed cols only; new
-- columns stay NULL until the Bloblang update lands (separate PR) and the
-- 13d backfill runs.

-- ---------- ems_esp: 28 new typed cols ----------
ALTER TABLE public.ems_esp
  ADD COLUMN IF NOT EXISTS seltemp           DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS comforttemp       DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS ecotemp           DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS manualtemp        DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS reducetemp        DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS noreducetemp      DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS tempautotemp      DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS targetflowtemp    DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS selflowtemp       DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS selburnpow        DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS flowtempoffset    DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS nompower          DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS nrg               DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS nrgheat           DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS nrgtotal          DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS ubauptime         DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS burngas           SMALLINT,
  ADD COLUMN IF NOT EXISTS burngas2          SMALLINT,
  ADD COLUMN IF NOT EXISTS ignwork           DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS fanwork           DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS oilpreheat        SMALLINT,
  ADD COLUMN IF NOT EXISTS threewayvalve     SMALLINT,
  ADD COLUMN IF NOT EXISTS circ              SMALLINT,
  ADD COLUMN IF NOT EXISTS disinfecting      SMALLINT,
  ADD COLUMN IF NOT EXISTS activated         SMALLINT,
  ADD COLUMN IF NOT EXISTS tapwateractive    SMALLINT,
  ADD COLUMN IF NOT EXISTS storagetemp1      DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS servicecodenumber DOUBLE PRECISION;

-- ---------- solaredge_inverter: 8 new typed cols ----------
ALTER TABLE public.solaredge_inverter
  ADD COLUMN IF NOT EXISTS ac_current_l1     DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS ac_current_l2     DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS ac_current_l3     DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS ac_voltage_l2     DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS ac_voltage_l3     DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS ac_power_apparent DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS ac_power_factor   DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS ac_power_reactive DOUBLE PRECISION;

-- ---------- solaredge_powerflow: 9 new typed cols ----------
ALTER TABLE public.solaredge_powerflow
  ADD COLUMN IF NOT EXISTS battery_power                    DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS consumer_inverter                DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS consumer_used_battery_production DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS consumer_used_pv_production      DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS consumer_used_production         DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS inverter_battery_production      DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS inverter_pv_production           DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS inverter_consumption             DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS inverter_production              DOUBLE PRECISION;

-- ---------- warp_evse: 4 new typed cols ----------
ALTER TABLE public.warp_evse
  ADD COLUMN IF NOT EXISTS allowed_charging_current DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS iec61851_state           SMALLINT,
  ADD COLUMN IF NOT EXISTS lock_state               SMALLINT,
  ADD COLUMN IF NOT EXISTS contactor_state          SMALLINT;

-- ---------- warp_charge_tracker: 6 new typed cols ----------
ALTER TABLE public.warp_charge_tracker
  ADD COLUMN IF NOT EXISTS authorization_type     DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS meter_start            DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS timestamp_minutes      DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS evse_uptime_start      DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS first_charge_timestamp DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS generator_state        SMALLINT;

-- ---------- raw nullable on 8 tables (knx already nullable) ----------
ALTER TABLE public.ems_esp             ALTER COLUMN raw DROP NOT NULL;
ALTER TABLE public.solaredge_inverter  ALTER COLUMN raw DROP NOT NULL;
ALTER TABLE public.solaredge_powerflow ALTER COLUMN raw DROP NOT NULL;
ALTER TABLE public.warp_evse           ALTER COLUMN raw DROP NOT NULL;
ALTER TABLE public.warp_charge_tracker ALTER COLUMN raw DROP NOT NULL;
ALTER TABLE public.warp_meter          ALTER COLUMN raw DROP NOT NULL;
ALTER TABLE public.warp_system         ALTER COLUMN raw DROP NOT NULL;
ALTER TABLE public.warp_charge_manager ALTER COLUMN raw DROP NOT NULL;

-- ---------- 365d retention on all 9 hypertables ----------
-- if_not_exists=>true makes re-running this script safe.
SELECT add_retention_policy('public.knx',                 INTERVAL '365 days', if_not_exists => true);
SELECT add_retention_policy('public.solaredge_inverter',  INTERVAL '365 days', if_not_exists => true);
SELECT add_retention_policy('public.solaredge_powerflow', INTERVAL '365 days', if_not_exists => true);
SELECT add_retention_policy('public.ems_esp',             INTERVAL '365 days', if_not_exists => true);
SELECT add_retention_policy('public.warp_system',         INTERVAL '365 days', if_not_exists => true);
SELECT add_retention_policy('public.warp_evse',           INTERVAL '365 days', if_not_exists => true);
SELECT add_retention_policy('public.warp_charge_manager', INTERVAL '365 days', if_not_exists => true);
SELECT add_retention_policy('public.warp_charge_tracker', INTERVAL '365 days', if_not_exists => true);
SELECT add_retention_policy('public.warp_meter',          INTERVAL '365 days', if_not_exists => true);
