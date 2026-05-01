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
        -- Continuous aggregates store materialised data under _timescaledb_internal;
        -- iot_mcp_bridge_ro needs SELECT there to read CAGGs.
        GRANT USAGE ON SCHEMA _timescaledb_internal TO iot_mcp_bridge_ro;
        GRANT SELECT ON ALL TABLES IN SCHEMA _timescaledb_internal TO iot_mcp_bridge_ro;
        ALTER DEFAULT PRIVILEGES IN SCHEMA _timescaledb_internal
            GRANT SELECT ON TABLES TO iot_mcp_bridge_ro;
    END IF;
END$$;
