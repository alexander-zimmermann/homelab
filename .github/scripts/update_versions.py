#!/usr/bin/env python3
"""Propagate Talos version bumps across manifest files.

When Renovate updates the version in a Talos factory image URL, the
``image_filename`` field and versioned YAML keys (e.g.
``vm_talos_1_12_5_cp-prod``) still carry the old version.  This script
detects such mismatches and propagates the new version to:

1. ``image_filename`` values in the image YAML.
2. Versioned YAML keys in the image YAML
   (e.g. ``vm_talos_1_12_5_`` → ``vm_talos_1_12_6_``).
3. Key references (``image_id``, ``template_id``, etc.) in any additional
   manifest files passed via ``--related``.

This script is intended to run as a Renovate post-upgrade command, before
``update_checksums.py`` recalculates the checksum for the updated image.

Usage examples::

    # Default paths (image YAML + standard related manifests)
    update_versions.py

    # Explicit paths
    update_versions.py \\
        --image-yaml infrastructure/manifest/20-image/image.yaml \\
        --related    infrastructure/manifest/40-template/template-vm.yaml \\
        --related    infrastructure/manifest/50-fleet/fleet-vm.yaml
"""
from __future__ import annotations

import argparse
import logging
import re
import sys
from pathlib import Path
from typing import Dict, List

sys.path.insert(0, str(Path(__file__).parent))

from lib import yaml_io
from lib.models import ImageEntry

logger = logging.getLogger(__name__)

_DEFAULT_IMAGE_YAML = Path("infrastructure/manifest/20-image/image.yaml")
_DEFAULT_RELATED: List[Path] = [
    Path("infrastructure/manifest/40-template/template-vm.yaml"),
    Path("infrastructure/manifest/50-fleet/fleet-vm.yaml"),
]

# Talos factory URL version: .../image/<schematic>/<version>/nocloud-amd64.raw
_TALOS_URL_VER_RE = re.compile(
    r"factory\.talos\.dev/image/[a-f0-9]+/(\d+\.\d+\.\d+)/"
)

# Semver-like version string inside an image_filename
_FILENAME_VER_RE = re.compile(r"(\d+\.\d+\.\d+)")


###############################################################################
## Detection
###############################################################################
def _detect_bumps(entries: List[ImageEntry]) -> Dict[str, str]:
    """Return ``{old_version: new_version}`` for Talos entries with a
    URL / filename version mismatch.

    The URL version is authoritative (Renovate has already updated it);
    the filename version is the stale value to be replaced.
    """
    bumps: Dict[str, str] = {}
    for entry in entries:
        url_m = _TALOS_URL_VER_RE.search(entry.image_url)
        if not url_m:
            continue  # not a Talos factory image

        fn_m = _FILENAME_VER_RE.search(entry.image_filename)
        if not fn_m:
            continue

        url_ver = url_m.group(1)
        fn_ver = fn_m.group(1)
        if url_ver != fn_ver and fn_ver not in bumps:
            logger.info("Version bump detected: %s → %s", fn_ver, url_ver)
            bumps[fn_ver] = url_ver

    return bumps


###############################################################################
## Applying bumps
###############################################################################
def _apply_bumps(
    lines: List[str],
    bumps: Dict[str, str],
    *,
    update_filenames: bool,
) -> List[str]:
    """Apply all version replacements from *bumps* to *lines*.

    Args:
        lines:            File content to process.
        bumps:            Mapping of ``old_version → new_version``.
        update_filenames: When ``True``, also update ``image_filename``
                          lines.  Set to ``False`` for related manifests
                          that do not contain ``image_filename`` fields.
    """
    for old_ver, new_ver in bumps.items():
        if update_filenames:
            lines = [
                line.replace(old_ver, new_ver)
                if yaml_io._FILENAME_LINE_RE.match(line)
                else line
                for line in lines
            ]
        lines = yaml_io.replace_version_in_keys(lines, old_ver, new_ver)
    return lines


def _process_file(
    path: Path,
    bumps: Dict[str, str],
    *,
    update_filenames: bool,
) -> None:
    """Read *path*, apply *bumps*, and write back only when something changed."""
    if not path.exists():
        logger.warning("File not found, skipping: %s", path)
        return

    original = yaml_io.read_lines(path)
    updated = _apply_bumps(original, bumps, update_filenames=update_filenames)

    if updated == original:
        logger.debug("No changes in %s", path)
        return

    yaml_io.write_lines(path, updated)
    logger.info("Updated %s", path)


###############################################################################
## Public entry point
###############################################################################
def run(image_yaml: Path, related_files: List[Path]) -> bool:
    """Detect and propagate Talos version bumps.

    Args:
        image_yaml:    Primary image YAML file.
        related_files: Additional manifest files whose key references need
                       updating (no ``image_filename`` fields).

    Returns:
        ``True`` on success, ``False`` when the image YAML was not found.
    """
    if not image_yaml.exists():
        logger.error("Image YAML not found: %s", image_yaml)
        return False

    entries = yaml_io.parse_entries(yaml_io.read_lines(image_yaml))
    bumps = _detect_bumps(entries)

    if not bumps:
        logger.info("No version bumps detected — nothing to do")
        return True

    _process_file(image_yaml, bumps, update_filenames=True)

    for path in related_files:
        _process_file(path, bumps, update_filenames=False)

    return True


###############################################################################
## CLI
###############################################################################
def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--image-yaml",
        type=Path,
        default=_DEFAULT_IMAGE_YAML,
        metavar="PATH",
        help=f"Image YAML file (default: {_DEFAULT_IMAGE_YAML})",
    )
    parser.add_argument(
        "--related",
        type=Path,
        action="append",
        dest="related_files",
        metavar="PATH",
        help=(
            "Additional manifest file whose versioned key references should "
            "be updated.  Can be repeated.  "
            f"Default: {', '.join(str(p) for p in _DEFAULT_RELATED)}"
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
    related = (
        args.related_files if args.related_files is not None else _DEFAULT_RELATED
    )
    sys.exit(0 if run(args.image_yaml, related) else 1)


if __name__ == "__main__":
    main()
