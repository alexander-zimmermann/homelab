#!/usr/bin/env python3
"""Update image checksums in the image YAML file.

For each image entry (optionally filtered by name), the checksum is computed
using the appropriate method:

sidecar download
    When ``image_checksum_url`` is set in the entry, only the small companion
    checksum file is fetched (~1 KB).  Suitable for images that publish
    standard distro checksum files (e.g. Debian ``SHA512SUMS``, Ubuntu
    ``SHA256SUMS``).

full download
    When no sidecar URL is configured, the full image is streamed and hashed
    locally.  Necessary for images that are generated on-demand and therefore
    have no pre-published checksum (e.g. Talos factory images).

Usage examples::

    # Update all images
    update_checksums.py

    # Talos images only  — full download, ~4 GB per image
    update_checksums.py talos

    # Debian and Ubuntu only — sidecar fetch, < 1 KB per image
    update_checksums.py debian ubuntu

    # Custom image YAML path
    update_checksums.py --image-yaml path/to/image.yaml talos
"""
from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path
from typing import List, Tuple

sys.path.insert(0, str(Path(__file__).parent))

from lib import checksum as cksum
from lib import yaml_io
from lib.models import ImageEntry

logger = logging.getLogger(__name__)

_DEFAULT_IMAGE_YAML = Path("infrastructure/manifest/20-image/image.yaml")


###############################################################################
## Per-entry logic
###############################################################################
def _update_entry(
    entry: ImageEntry,
    lines: List[str],
    default_algorithm: str,
) -> Tuple[List[str], bool]:
    """Compute and apply the updated checksum for *entry*.

    Returns the (possibly modified) lines and a boolean success flag.
    A 404 response is treated as a non-fatal warning so that a temporarily
    unavailable image does not fail the entire run.
    """
    algorithm = entry.image_checksum_algorithm or default_algorithm

    try:
        if entry.image_checksum_url:
            new_checksum = cksum.from_sidecar(
                entry.image_checksum_url,
                entry.image_filename,
            )
        else:
            new_checksum = cksum.from_download(entry.image_url, algorithm)
    except cksum.ChecksumError as exc:
        if exc.http_status == 404:
            logger.warning(
                "[%s] Image not found (404) — keeping existing checksum",
                entry.key,
            )
            return lines, True
        logger.error("[%s] %s", entry.key, exc)
        return lines, False

    if new_checksum == entry.image_checksum:
        logger.info("[%s] Checksum unchanged", entry.key)
        return lines, True

    logger.info(
        "[%s] %s… → %s…",
        entry.key,
        entry.image_checksum[:12],
        new_checksum[:12],
    )
    return yaml_io.set_checksum(lines, entry.image_url, new_checksum), True


###############################################################################
## Public entry point
###############################################################################
def run(
    image_yaml: Path,
    filters: List[str],
    default_algorithm: str,
) -> bool:
    """Update checksums for all entries matching *filters* in *image_yaml*.

    Args:
        image_yaml:        Path to the image YAML file.
        filters:           Substring filters applied to image keys
                           (case-insensitive).  Empty list = all entries.
        default_algorithm: Fallback algorithm for entries without an explicit
                           ``image_checksum_algorithm`` field.

    Returns:
        ``True`` when all updates succeeded, ``False`` otherwise.
    """
    if not image_yaml.exists():
        logger.error("Image YAML not found: %s", image_yaml)
        return False

    lines = yaml_io.read_lines(image_yaml)
    entries = yaml_io.parse_entries(lines)
    selected = [e for e in entries if e.matches(filters)]

    if not selected:
        logger.warning("No entries matched filters %r", filters)
        return True

    filter_desc = repr(filters) if filters else "all"
    logger.info(
        "Processing %d / %d image(s) [filter=%s]",
        len(selected),
        len(entries),
        filter_desc,
    )

    success = True
    for entry in selected:
        lines, ok = _update_entry(entry, lines, default_algorithm)
        success = success and ok

    yaml_io.write_lines(image_yaml, lines)
    return success


###############################################################################
## CLI
###############################################################################
def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "filters",
        nargs="*",
        metavar="FILTER",
        help=(
            "Process only entries whose key contains FILTER "
            "(case-insensitive substring, repeatable).  "
            "Omit to process all entries."
        ),
    )
    parser.add_argument(
        "--image-yaml",
        type=Path,
        default=_DEFAULT_IMAGE_YAML,
        metavar="PATH",
        help=f"Image YAML file (default: {_DEFAULT_IMAGE_YAML})",
    )
    parser.add_argument(
        "--algorithm",
        default="sha256",
        metavar="ALGO",
        help=(
            "Fallback hash algorithm for entries without an explicit "
            "image_checksum_algorithm field (default: sha256)"
        ),
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Enable debug logging",
    )
    return parser


def main() -> None:
    args = _build_parser().parse_args()
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(levelname)s: %(message)s",
    )
    sys.exit(
        0 if run(args.image_yaml, args.filters, args.algorithm) else 1
    )


if __name__ == "__main__":
    main()
