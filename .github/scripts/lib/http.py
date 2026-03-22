from __future__ import annotations

import logging
import urllib.request
from typing import Any

logger = logging.getLogger(__name__)

_TIMEOUT_SECONDS = 30
_CHUNK_SIZE = 8192
_USER_AGENT = "homelab-image-updater/1.0"


def _request(url: str) -> urllib.request.Request:
    return urllib.request.Request(url, headers={"User-Agent": _USER_AGENT})


def fetch_text(url: str) -> str:
    """Fetch *url* and return its content as a UTF-8 string.

    Suitable for small sidecar files (SHA256SUMS, SHA512SUMS, etc.).
    """
    logger.debug("GET %s", url)
    with urllib.request.urlopen(_request(url), timeout=_TIMEOUT_SECONDS) as resp:
        return resp.read().decode("utf-8")


def stream_into(url: str, sink: Any) -> None:
    """Stream *url* content into *sink* by calling ``sink.update(chunk)``.

    Suitable for feeding data into :mod:`hashlib` hash objects without
    buffering the entire file in memory.
    """
    logger.debug("Streaming %s", url)
    with urllib.request.urlopen(_request(url), timeout=_TIMEOUT_SECONDS) as resp:
        while chunk := resp.read(_CHUNK_SIZE):
            sink.update(chunk)
