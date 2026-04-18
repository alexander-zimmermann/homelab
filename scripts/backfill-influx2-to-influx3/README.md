# Backfill: legacy InfluxDB 2 → in-cluster InfluxDB 3 (`homelab_1h`)

One-shot manual migration of the hourly-downsampled history.

## What it does

For each calendar month in the requested range:

1. Runs the same Flux query the legacy `downsample_telegraf_1h` task used
   (filter numeric fields only, `aggregateWindow(every: 1h, fn: mean)`).
2. Streams the annotated CSV response row-by-row (no big in-memory buffer).
3. Writes line protocol to InfluxDB 3 in 5 000-line batches via `/api/v3/write_lp`.

Expected wall-clock: ~53 min for 2022-07 through 2026-04. Memory stays flat.

Skips bool and string fields automatically — the `types.isType(float|int)` Flux
filter is the whole reason the legacy task didn't crash on heterogeneous
measurements, and we preserve it here verbatim.

## Where to run it

On the Linux host that owns the Docker InfluxDB 2 container, because that host
can trivially reach `http://localhost:8086`.

For the InfluxDB 3 side, open a port-forward from a machine with cluster
access (the in-cluster service has no external ingress):

```
kubectl -n influxdb port-forward svc/influxdb3 8181:8181
```

If you run the port-forward on a different machine than the one where
`backfill.py` executes, use `--influx3-url http://<forwarding-host>:8181`
instead of localhost.

## Running

```sh
# 1. Sanity check — single month, no writes
./backfill.py \
  --from 2024-06 --to 2024-06 \
  --influx2-url http://localhost:8086 \
  --influx2-org zimmermann.eu.com \
  --influx2-bucket telegraf/autogen \
  --influx2-token "$INFLUX2_TOKEN" \
  --influx3-url http://localhost:8181 \
  --influx3-db homelab_1h \
  --influx3-token "$INFLUX3_TOKEN" \
  --dry-run

# 2. Same month, for real — verify points show up in Grafana (InfluxDB 1h SQL datasource)
./backfill.py --from 2024-06 --to 2024-06 [... same args, no --dry-run]

# 3. Full history. Break into 1–2 year chunks if you want to resume safely.
./backfill.py --from 2022-07 --to 2026-04 [... same args]
```

## Tokens

- **Influx 2**: use the operator token or any read-scoped token for the
  `telegraf/autogen` bucket. On the Docker host: `docker exec influx influx auth list`.
- **Influx 3**: the admin token from the `influxdb-credentials` SealedSecret.
  Grab it with `kubectl -n influxdb get secret influxdb-credentials -o jsonpath='{.data.admin-token}' | base64 -d`.

## Verification

After the full run:

```sql
-- Point count in homelab_1h (target: ~5.67 M)
SELECT count(*) FROM information_schema.tables WHERE table_schema = 'iox';
-- Rough per-measurement check
SELECT count(*) FROM "Heizung.EG.Büro.FBH.Stellwert-Status";
```

Or simply open a Grafana panel with the `InfluxDB 1h (SQL)` datasource and a
time range of `-4y` — it should show the full history with the known data
gap 2023-08-10 .. 2024-01-14.

## After a clean run

- Keep the Docker Influx 2 container running for at least a week — the
  scheduled downsampler is producing new rows at :05 every hour, and you
  want a safety window before discarding the legacy storage.
- Then stop the container and archive its volume; don't delete it outright.

## Gotchas

- The script reconstructs line protocol from CSV field-by-field. For
  measurements that store multiple numeric fields, the Flux output emits
  one record per field, so each hour-bin gets written as multiple single-field
  LP lines. That's fine — InfluxDB 3 merges them into the same row on the
  same (measurement, tag set, timestamp).
- If the backfill overlaps with a tick of the scheduled downsampler (the last
  hour), the writes are idempotent: same timestamp + same tag set = overwrite,
  and the mean is deterministic.
