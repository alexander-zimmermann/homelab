"""Line-preserving YAML helpers for the image manifest.

All functions operate on plain ``List[str]`` (lines with newlines preserved)
so that comments, blank lines, and original formatting survive round-trips.
A standard YAML parser is intentionally avoided for this reason.

Expected file structure::

    image:
      <key>:           ← 2-space indent, word chars + hyphens
        <field>: ...   ← 4-space indent
"""
from __future__ import annotations

import re
from pathlib import Path
from typing import Dict, List, Optional

from .models import ImageEntry

###############################################################################
## Compiled patterns
###############################################################################
# Image key line: exactly 2 spaces, then word-chars / hyphens, then colon.
_IMAGE_KEY_RE = re.compile(r"^  ([\w-]+):\s*$")

# Field line: exactly 4 spaces, then a word-only name, then colon + value.
# Stops before inline comments (#) so they are not captured as part of value.
_FIELD_RE = re.compile(r"^    (\w+):\s*([^#\n]*)")

# image_checksum line (not image_checksum_algorithm).
_CHECKSUM_LINE_RE = re.compile(
    r"^(\s*image_checksum:\s*)(['\"]?)([a-f0-9]*)(['\"]?)\s*$"
)

# Filename line.
_FILENAME_LINE_RE = re.compile(r"^\s*image_filename:")

###############################################################################
## I/O
###############################################################################
def read_lines(path: Path) -> List[str]:
    """Read *path* and return its lines with newlines preserved."""
    return path.read_text(encoding="utf-8").splitlines(keepends=True)


def write_lines(path: Path, lines: List[str]) -> None:
    """Write *lines* back to *path*, joining without adding extra newlines."""
    path.write_text("".join(lines), encoding="utf-8")


###############################################################################
## Parsing
###############################################################################
def parse_entries(lines: List[str]) -> List[ImageEntry]:
    """Parse :class:`~lib.models.ImageEntry` objects from *lines*.

    Entries with an empty ``image_url`` (e.g. placeholder Windows images)
    are silently skipped.
    """
    entries: List[ImageEntry] = []
    current_key: Optional[str] = None
    fields: Dict[str, str] = {}

    def _flush() -> None:
        url = fields.get("image_url", "").strip("\"'")
        if current_key and url:
            entries.append(_build_entry(current_key, fields))

    for line in lines:
        key_m = _IMAGE_KEY_RE.match(line)
        if key_m:
            _flush()
            current_key = key_m.group(1)
            fields = {}
            continue

        if current_key:
            field_m = _FIELD_RE.match(line)
            if field_m:
                fields[field_m.group(1)] = field_m.group(2).strip().strip("\"'")

    _flush()
    return entries


def _build_entry(key: str, fields: Dict[str, str]) -> ImageEntry:
    checksum_url = fields.get("image_checksum_url") or None
    checksum_filename = fields.get("image_checksum_filename") or None
    return ImageEntry(
        key=key,
        image_url=fields.get("image_url", ""),
        image_filename=fields.get("image_filename", ""),
        image_checksum=fields.get("image_checksum", ""),
        image_checksum_algorithm=fields.get("image_checksum_algorithm", "sha256"),
        image_checksum_url=checksum_url,
        image_checksum_filename=checksum_filename,
    )


###############################################################################
## In-place line updates
###############################################################################
def set_checksum(lines: List[str], image_url: str, new_checksum: str) -> List[str]:
    """Replace the ``image_checksum`` value in the block containing *image_url*.

    Finds the ``image_url:`` line and updates the next ``image_checksum:``
    line encountered, preserving indentation and any surrounding quotes.

    Lines between the URL and checksum (e.g. ``image_filename``) are passed
    through unchanged.
    """
    result: List[str] = []
    pending = False

    for line in lines:
        if not pending and re.search(
            r"image_url:\s*" + re.escape(image_url), line
        ):
            pending = True
            result.append(line)
            continue

        if pending:
            m = _CHECKSUM_LINE_RE.match(line)
            if m:
                result.append(
                    f"{m.group(1)}{m.group(2)}{new_checksum}{m.group(4)}\n"
                )
                pending = False
                continue

        result.append(line)

    return result


def replace_version_in_keys(
    lines: List[str], old_ver: str, new_ver: str
) -> List[str]:
    """Replace *old_ver* with *new_ver* in versioned Talos YAML keys.

    Converts both version strings to their underscore forms and replaces the
    pattern ``_talos_<old>`` where the old version is followed by ``-``,
    ``_``, or end-of-token.  This covers:

    * YAML keys:             ``vm_talos_1_12_5_cp-prod:``
    * ``image_id`` values:   ``image_id: vm_talos_1_12_5_cp-prod``
    * ``template_id`` values: ``template_id: vm_talos_1_12_5_dp-prod``

    ``image_url:`` lines are intentionally left untouched — Renovate manages
    the URL version independently.
    """
    old_key = old_ver.replace(".", "_")
    new_key = new_ver.replace(".", "_")
    pattern = re.compile(r"(_talos_)" + re.escape(old_key) + r"(?=[-_]|$)")
    return [pattern.sub(r"\g<1>" + new_key, line) for line in lines]
