"""
Scheduled plugin: aggregate numeric fields of every measurement in `homelab`
into 1-hour means and write them to `homelab_1h`.

Replaces the legacy Flux task `downsample_telegraf_1h` (InfluxDB 2).

Trigger spec: cron:5 * * * *  (runs at :05 every hour, processes the previous
full hour — mirrors the old task's 1h window + 5m offset).

Registered against database `homelab` (the source). Writes cross-database to
`homelab_1h` via the HTTP API, because `influxdb3_local.write` only targets
the trigger's own database.
"""

import datetime
import json
import os
import urllib.parse
import urllib.request

TARGET_DB = "homelab_1h"
INFLUX_URL = os.environ.get("INFLUXDB3_LOCAL_URL", "http://127.0.0.1:8181")
TOKEN_FILE = "/etc/influxdb3/tokens/admin-token.json"

NUMERIC_TYPES = {"Float64", "Int64", "UInt64", "Float32", "Int32", "UInt32"}


def _load_token():
    with open(TOKEN_FILE) as f:
        return json.load(f)["token"]


def _window(call_time):
    # call_time is a datetime (UTC). Process the hour that just ended.
    end = call_time.replace(minute=0, second=0, microsecond=0)
    start = end - datetime.timedelta(hours=1)
    return start, end


def _iso(ts):
    return ts.strftime("%Y-%m-%dT%H:%M:%SZ")


def _escape_ident(name):
    return '"' + name.replace('"', '""') + '"'


def _escape_lp_tag(value):
    return str(value).replace("\\", "\\\\").replace(",", "\\,").replace("=", "\\=").replace(" ", "\\ ")


def _escape_lp_measurement(name):
    return name.replace("\\", "\\\\").replace(",", "\\,").replace(" ", "\\ ")


def _escape_lp_field_key(name):
    return name.replace("\\", "\\\\").replace(",", "\\,").replace("=", "\\=").replace(" ", "\\ ")


def _list_tables(influxdb3_local):
    # Skip Telegraf's self-monitoring tables (`internal_*`). Their fields are
    # cumulative counters (metrics_written, errors, buffer_size, ...) for
    # which an hourly mean is meaningless, and steady-state raw data in
    # `homelab` with 365d retention already covers any debugging need.
    rows = influxdb3_local.query(
        "SELECT table_name FROM information_schema.tables "
        "WHERE table_schema = 'iox' AND table_name NOT LIKE 'internal\\_%' ESCAPE '\\'"
    )
    return [r["table_name"] for r in rows]


def _columns(influxdb3_local, table):
    rows = influxdb3_local.query(
        "SELECT column_name, data_type FROM information_schema.columns "
        f"WHERE table_schema = 'iox' AND table_name = '{table}'"
    )

    tags, fields, has_time = [], [], False
    for r in rows:
        col, dtype = r["column_name"], r["data_type"]
        if col == "time":
            has_time = True
        elif dtype in ("Utf8", "Dictionary(Int32, Utf8)"):
            tags.append(col)
        elif dtype in NUMERIC_TYPES:
            fields.append(col)
    return tags, fields, has_time


def _build_query(table, tags, fields, start, end):
    select_fields = ", ".join(
        f"mean({_escape_ident(f)}) AS {_escape_ident(f)}" for f in fields
    )
    tag_select = "".join(f", {_escape_ident(t)}" for t in tags)
    group_by = "time" + "".join(f", {_escape_ident(t)}" for t in tags)
    return (
        f"SELECT date_bin(INTERVAL '1 hour', time) AS time{tag_select}, "
        f"{select_fields} FROM {_escape_ident(table)} "
        f"WHERE time >= TIMESTAMP '{_iso(start)}' AND time < TIMESTAMP '{_iso(end)}' "
        f"GROUP BY {group_by}"
    )


def _to_ns(ts):
    """Convert the `time` value from a query result into nanoseconds since epoch.

    The influxdb3 plugin runtime surfaces Timestamp columns in different forms
    depending on the DataFusion/pyarrow version in play, so handle the common
    shapes explicitly.
    """
    if isinstance(ts, bool):
        raise TypeError(f"unexpected bool timestamp: {ts!r}")
    if isinstance(ts, int):
        # Nanoseconds since epoch (the arrow/pyarrow representation).
        return ts
    if isinstance(ts, float):
        # Seconds since epoch (defensive — less common).
        return int(ts * 1_000_000_000)
    if isinstance(ts, datetime.datetime):
        if ts.tzinfo is None:
            ts = ts.replace(tzinfo=datetime.timezone.utc)
        return int(ts.timestamp() * 1_000_000_000)
    # Fallback: ISO8601 string. Accept the `...Z` and naive-UTC forms the
    # influxdb3 JSON output is known to use.
    s = str(ts)
    if s.endswith("Z"):
        s = s[:-1] + "+00:00"
    dt = datetime.datetime.fromisoformat(s)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=datetime.timezone.utc)
    return int(dt.timestamp() * 1_000_000_000)


def _row_to_line(measurement, row, tags, fields):
    tag_parts = []
    for t in tags:
        v = row.get(t)
        if v is None or v == "":
            continue
        tag_parts.append(f"{_escape_lp_tag(t)}={_escape_lp_tag(v)}")

    field_parts = []
    for f in fields:
        v = row.get(f)
        if v is None:
            continue
        field_parts.append(f"{_escape_lp_field_key(f)}={float(v)}")
    if not field_parts:
        return None

    ns = _to_ns(row["time"])

    head = _escape_lp_measurement(measurement)
    if tag_parts:
        head += "," + ",".join(tag_parts)
    return f"{head} {','.join(field_parts)} {ns}"


def _write(lines, token):
    if not lines:
        return 0

    body = "\n".join(lines).encode()
    query = urllib.parse.urlencode({"db": TARGET_DB, "precision": "nanosecond"})
    req = urllib.request.Request(
        f"{INFLUX_URL}/api/v3/write_lp?{query}",
        data=body,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "text/plain"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        if resp.status >= 300:
            raise RuntimeError(f"write_lp HTTP {resp.status}")
    return len(lines)


def process_scheduled_call(influxdb3_local, call_time, args=None):
    start, end = _window(call_time)
    influxdb3_local.info(f"downsample_1h: window {_iso(start)} .. {_iso(end)}")

    try:
        token = _load_token()
    except Exception as e:
        influxdb3_local.error(f"downsample_1h: cannot read admin token: {e}")
        raise

    tables = _list_tables(influxdb3_local)
    influxdb3_local.info(f"downsample_1h: {len(tables)} tables to aggregate")

    total_lines = 0
    failed_tables = 0

    for table in tables:
        try:
            tags, fields, has_time = _columns(influxdb3_local, table)
            if not has_time or not fields:
                continue
            query = _build_query(table, tags, fields, start, end)
            rows = influxdb3_local.query(query)
            lines = [
                ln for ln in
                (_row_to_line(table, r, tags, fields) for r in rows)
                if ln is not None
            ]
            written = _write(lines, token)
            total_lines += written
        except Exception as e:
            failed_tables += 1
            influxdb3_local.error(f"downsample_1h: table '{table}' failed: {e}")

    if failed_tables:
        influxdb3_local.warn(
            f"downsample_1h: wrote {total_lines} lines across "
            f"{len(tables) - failed_tables}/{len(tables)} tables "
            f"({failed_tables} failed)"
        )
    else:
        influxdb3_local.info(
            f"downsample_1h: wrote {total_lines} lines across {len(tables)} tables"
        )
