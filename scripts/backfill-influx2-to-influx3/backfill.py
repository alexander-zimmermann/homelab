#!/usr/bin/env python3
"""
Backfill hourly downsampled data from the legacy InfluxDB 2 Docker instance
into the in-cluster InfluxDB 3 database `homelab_1h`.

Runs the same Flux aggregation that the legacy task used (mean over 1h,
numeric-only filter via types.isType), chunked by calendar month to keep
memory usage bounded. Writes results as line-protocol to InfluxDB 3.

Meant to be run ONCE, manually, from the Linux host that owns the Docker
InfluxDB 2 (so localhost:8086 works for the source) with a kubectl
port-forward open against the in-cluster InfluxDB 3.

Usage example:

  ./backfill.py \\
    --from 2022-07 --to 2026-04 \\
    --influx2-url http://localhost:8086 \\
    --influx2-org zimmermann.eu.com \\
    --influx2-bucket telegraf/autogen \\
    --influx2-token "$INFLUX2_TOKEN" \\
    --influx3-url http://localhost:8181 \\
    --influx3-db homelab_1h \\
    --influx3-token "$INFLUX3_TOKEN"
"""

import argparse
import csv
import datetime
import io
import sys
import time
import urllib.parse
import urllib.request
from typing import Iterator, List, Optional, Tuple

FLUX_QUERY_TEMPLATE = """\
import "types"
from(bucket: "{bucket}")
  |> range(start: {start}, stop: {stop})
  |> filter(fn: (r) => types.isType(v: r._value, type: "float") or types.isType(v: r._value, type: "int"))
  |> aggregateWindow(every: 1h, fn: mean, createEmpty: false)
"""


def parse_month(value: str) -> datetime.date:
    return datetime.datetime.strptime(value, "%Y-%m").date().replace(day=1)


def month_chunks(start: datetime.date, end: datetime.date) -> Iterator[Tuple[datetime.date, datetime.date]]:
    cur = start
    while cur <= end:
        if cur.month == 12:
            nxt = cur.replace(year=cur.year + 1, month=1)
        else:
            nxt = cur.replace(month=cur.month + 1)
        yield cur, nxt
        cur = nxt


def iso(d: datetime.date) -> str:
    return datetime.datetime(d.year, d.month, d.day, tzinfo=datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def escape_lp_measurement(name: str) -> str:
    return name.replace("\\", "\\\\").replace(",", "\\,").replace(" ", "\\ ")


def escape_lp_tag(value: str) -> str:
    return value.replace("\\", "\\\\").replace(",", "\\,").replace("=", "\\=").replace(" ", "\\ ")


def escape_lp_field_key(name: str) -> str:
    return escape_lp_tag(name)


def rfc3339_to_ns(ts: str) -> int:
    # InfluxDB 2 CSV emits RFC3339, usually with nanosecond precision like
    # 2024-06-01T12:00:00Z or 2024-06-01T12:00:00.123456789Z.
    if ts.endswith("Z"):
        ts = ts[:-1] + "+00:00"
    # Python <3.11 struggles with fractional seconds beyond microseconds.
    if "." in ts:
        head, frac_and_tz = ts.split(".", 1)
        # Split fractional from timezone suffix (+00:00).
        if "+" in frac_and_tz:
            frac, tz = frac_and_tz.split("+", 1)
            tz = "+" + tz
        elif "-" in frac_and_tz:
            frac, tz = frac_and_tz.rsplit("-", 1)
            tz = "-" + tz
        else:
            frac, tz = frac_and_tz, ""
        frac = (frac + "000000000")[:9]
        whole = datetime.datetime.fromisoformat(head + tz)
        return int(whole.timestamp()) * 1_000_000_000 + int(frac)
    return int(datetime.datetime.fromisoformat(ts).timestamp() * 1_000_000_000)


def query_influx2(url: str, org: str, token: str, flux: str) -> io.BytesIO:
    params = urllib.parse.urlencode({"org": org})
    req = urllib.request.Request(
        f"{url}/api/v2/query?{params}",
        data=flux.encode(),
        headers={
            "Authorization": f"Token {token}",
            "Content-Type": "application/vnd.flux",
            "Accept": "application/csv",
        },
        method="POST",
    )
    return urllib.request.urlopen(req, timeout=600)


def iter_flux_records(resp) -> Iterator[dict]:
    """Yield one dict per data row from InfluxDB 2's annotated CSV stream.

    Handles the multi-table format (blank line separates tables; each table
    starts with #datatype / #group / #default annotations, then a header).
    """
    reader = csv.reader(io.TextIOWrapper(resp, encoding="utf-8", newline=""))
    header: Optional[List[str]] = None
    for row in reader:
        if not row or all(c == "" for c in row):
            header = None
            continue
        if row[0].startswith("#"):
            header = None
            continue
        if header is None:
            header = row
            continue
        yield dict(zip(header, row))


RESERVED = {"", "result", "table", "_start", "_stop", "_time", "_value", "_field", "_measurement"}


def record_to_line(rec: dict) -> Optional[str]:
    measurement = rec.get("_measurement")
    field = rec.get("_field")
    value = rec.get("_value")
    time_s = rec.get("_time")
    if not measurement or not field or value in (None, "") or not time_s:
        return None
    try:
        fval = float(value)
    except ValueError:
        return None
    tag_parts = []
    for k, v in rec.items():
        if k in RESERVED or v in (None, ""):
            continue
        tag_parts.append(f"{escape_lp_tag(k)}={escape_lp_tag(v)}")
    head = escape_lp_measurement(measurement)
    if tag_parts:
        head += "," + ",".join(sorted(tag_parts))
    ns = rfc3339_to_ns(time_s)
    return f"{head} {escape_lp_field_key(field)}={fval} {ns}"


def write_batch(url: str, db: str, token: str, lines: List[str]) -> None:
    if not lines:
        return
    body = ("\n".join(lines)).encode()
    params = urllib.parse.urlencode({"db": db, "precision": "nanosecond"})
    req = urllib.request.Request(
        f"{url}/api/v3/write_lp?{params}",
        data=body,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "text/plain"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        if resp.status >= 300:
            raise RuntimeError(f"InfluxDB 3 write failed: HTTP {resp.status}")


def backfill_month(args, start: datetime.date, stop: datetime.date) -> int:
    flux = FLUX_QUERY_TEMPLATE.format(
        bucket=args.influx2_bucket, start=iso(start), stop=iso(stop)
    )
    print(f"[{start:%Y-%m}] querying InfluxDB 2 ({iso(start)} .. {iso(stop)})", flush=True)
    t0 = time.monotonic()
    resp = query_influx2(args.influx2_url, args.influx2_org, args.influx2_token, flux)

    batch: List[str] = []
    total = 0
    for rec in iter_flux_records(resp):
        line = record_to_line(rec)
        if line is None:
            continue
        batch.append(line)
        if len(batch) >= args.batch_size:
            if not args.dry_run:
                write_batch(args.influx3_url, args.influx3_db, args.influx3_token, batch)
            total += len(batch)
            batch = []
    if batch:
        if not args.dry_run:
            write_batch(args.influx3_url, args.influx3_db, args.influx3_token, batch)
        total += len(batch)

    dt = time.monotonic() - t0
    tag = " (dry-run)" if args.dry_run else ""
    print(f"[{start:%Y-%m}] wrote {total} points in {dt:.1f}s{tag}", flush=True)
    return total


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--from", dest="from_month", required=True, help="Start month, inclusive (YYYY-MM)")
    p.add_argument("--to", dest="to_month", required=True, help="End month, inclusive (YYYY-MM)")
    p.add_argument("--influx2-url", required=True)
    p.add_argument("--influx2-org", required=True)
    p.add_argument("--influx2-bucket", required=True)
    p.add_argument("--influx2-token", required=True)
    p.add_argument("--influx3-url", required=True)
    p.add_argument("--influx3-db", required=True)
    p.add_argument("--influx3-token", required=True)
    p.add_argument("--batch-size", type=int, default=5000)
    p.add_argument("--dry-run", action="store_true", help="Query source but skip writes")
    args = p.parse_args()

    start = parse_month(args.from_month)
    end = parse_month(args.to_month)
    if start > end:
        print("error: --from must be <= --to", file=sys.stderr)
        return 2

    grand_total = 0
    for mstart, mstop in month_chunks(start, end):
        grand_total += backfill_month(args, mstart, mstop)
    print(f"done. total points: {grand_total}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
