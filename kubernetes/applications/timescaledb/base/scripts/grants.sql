-- GRANTs for non-owner roles. Idempotent — safe to re-run on every PostSync
-- of the timescaledb app. New roles + grants get appended here as they show up;
-- the role itself must exist (created via spec.managed.roles[] in database.yaml).

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'connect') THEN
        GRANT USAGE ON SCHEMA public TO connect;
        GRANT INSERT, SELECT ON ALL TABLES IN SCHEMA public TO connect;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public
            GRANT INSERT, SELECT ON TABLES TO connect;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'iot_mcp_bridge_ro') THEN
        GRANT CONNECT ON DATABASE homelab TO iot_mcp_bridge_ro;
        GRANT USAGE ON SCHEMA public TO iot_mcp_bridge_ro;
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO iot_mcp_bridge_ro;
        ALTER DEFAULT PRIVILEGES IN SCHEMA public
            GRANT SELECT ON TABLES TO iot_mcp_bridge_ro;

        -- Grant SELECT only on CAGG materialisation tables; a blanket grant
        -- on _timescaledb_internal would hit TS bookkeeping tables owned by
        -- the postgres superuser.
        GRANT USAGE ON SCHEMA _timescaledb_internal TO iot_mcp_bridge_ro;
        DECLARE
            cagg RECORD;
        BEGIN
            FOR cagg IN
                SELECT format('%I.%I',
                              materialization_hypertable_schema,
                              materialization_hypertable_name) AS qname
                FROM timescaledb_information.continuous_aggregates
            LOOP
                EXECUTE format('GRANT SELECT ON %s TO iot_mcp_bridge_ro', cagg.qname);
            END LOOP;
        END;
    END IF;
END$$;
