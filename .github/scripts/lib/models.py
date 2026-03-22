from __future__ import annotations

from dataclasses import dataclass
from typing import List, Optional


@dataclass
class ImageEntry:
    """Represents a single image definition from the image YAML.

    Attributes:
        key:                      YAML key identifying this image
                                  (e.g. ``vm_talos_1_12_5_cp-prod``).
        image_url:                Download URL for the image.
        image_filename:           Local filename used when storing the image.
        image_checksum:           Current hex digest of the image.
        image_checksum_algorithm: Hash algorithm (default: ``sha256``).
        image_checksum_url:       Optional URL to a sidecar checksum file.
                                  When set the checksum is fetched from this
                                  URL instead of hashing a full image download.
                                  Suitable for images that publish companion
                                  checksum files (e.g. Debian SHA512SUMS,
                                  Ubuntu SHA256SUMS).
    """

    key: str
    image_url: str
    image_filename: str
    image_checksum: str
    image_checksum_algorithm: str = "sha256"
    image_checksum_url: Optional[str] = None

    def matches(self, filters: List[str]) -> bool:
        """Return ``True`` when any filter is a substring of this entry's key.

        Comparison is case-insensitive.  An empty *filters* list matches every
        entry.
        """
        if not filters:
            return True
        key_lower = self.key.lower()
        return any(f.lower() in key_lower for f in filters)
