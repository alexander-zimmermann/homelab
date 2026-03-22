from __future__ import annotations

import hashlib
import logging
import re
import urllib.error
from typing import Optional

from .http import fetch_text, stream_into

logger = logging.getLogger(__name__)

# Matches both common distro sidecar formats:
#   <digest>  <filename>   — Debian, linuxcontainers.org (two spaces)
#   <digest> *<filename>   — Ubuntu (space + asterisk)
_SIDECAR_LINE_RE = re.compile(
    r"^([a-f0-9]+)\s+\*?(?P<filename>.+?)\s*$",
    re.MULTILINE,
)


class ChecksumError(Exception):
    """Raised when a checksum cannot be computed or retrieved.

    Attributes:
        http_status: HTTP status code when the failure was an HTTP error,
                     ``None`` otherwise.
    """

    def __init__(self, message: str, http_status: Optional[int] = None) -> None:
        super().__init__(message)
        self.http_status = http_status


def from_download(url: str, algorithm: str) -> str:
    """Compute the checksum of the file at *url* by streaming it.

    The file is never stored on disk; data is fed directly into the hash
    object chunk by chunk.

    Args:
        url:       URL of the file to hash.
        algorithm: Hash algorithm name recognised by :mod:`hashlib`
                   (e.g. ``"sha256"``, ``"sha512"``).

    Returns:
        Lowercase hex digest string.

    Raises:
        ChecksumError: On download failure or unsupported algorithm.
    """
    logger.info("Downloading %s (%s)…", url, algorithm)
    try:
        h = hashlib.new(algorithm)
    except ValueError as exc:
        raise ChecksumError(f"Unsupported algorithm: {algorithm!r}") from exc

    try:
        stream_into(url, h)
    except urllib.error.HTTPError as exc:
        raise ChecksumError(
            f"HTTP {exc.code} downloading {url}", http_status=exc.code
        ) from exc
    except Exception as exc:
        raise ChecksumError(f"Download failed for {url}: {exc}") from exc

    return h.hexdigest()


def from_sidecar(checksum_url: str, filename: str) -> str:
    """Fetch *checksum_url* and return the hex digest for *filename*.

    Supports the two common distro sidecar formats::

        <digest>  <filename>   — Debian, linuxcontainers.org
        <digest> *<filename>   — Ubuntu

    Args:
        checksum_url: URL of the sidecar checksum file (e.g. ``SHA256SUMS``).
        filename:     Basename of the image file to look up in the sidecar.

    Returns:
        Lowercase hex digest string.

    Raises:
        ChecksumError: When the sidecar cannot be fetched or *filename* is
                       not found within it.
    """
    logger.info("Fetching sidecar %s for %s…", checksum_url, filename)
    try:
        content = fetch_text(checksum_url)
    except urllib.error.HTTPError as exc:
        raise ChecksumError(
            f"HTTP {exc.code} fetching sidecar {checksum_url}",
            http_status=exc.code,
        ) from exc
    except Exception as exc:
        raise ChecksumError(
            f"Failed to fetch sidecar {checksum_url}: {exc}"
        ) from exc

    pattern = re.compile(
        r"^([a-f0-9]+)\s+\*?" + re.escape(filename) + r"\s*$",
        re.MULTILINE,
    )
    match = pattern.search(content)
    if not match:
        raise ChecksumError(
            f"{filename!r} not found in sidecar {checksum_url}"
        )

    return match.group(1)
