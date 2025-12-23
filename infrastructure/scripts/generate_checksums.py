#!/usr/bin/env python3
"""
Checksum Generator for Infrastructure Images

This script generates SHA256 checksums for container and VM images by:
1. Parsing image definitions from generated.auto.tfvars
2. Attempting to fetch checksums from remote sources (e.g., SHA256SUMS files)
3. Downloading and computing checksums locally if remote sources unavailable
4. Writing results to checksums.yaml

Features:
- Streaming downloads for memory efficiency
- Retry logic for network resilience
- Remote checksum source detection for common distributions
- Incremental updates (preserves unchanged checksums)

Usage:
  python generate_checksums.py --terraform-file generated.auto.tfvars
  python generate_checksums.py --force --verbose
"""

from __future__ import annotations

import argparse
import hashlib
import logging
import re
import sys
import time
import yaml
import urllib.request

from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Optional, Generator
from urllib.error import URLError, HTTPError
from contextlib import contextmanager

from logging_formatter import setup_logging_from_config


# Exit codes
EXIT_SUCCESS = 0
EXIT_CHECKSUM_ERROR = 1
EXIT_PARSING_ERROR = 2
EXIT_NETWORK_ERROR = 3
EXIT_UNEXPECTED_ERROR = 99

# Default paths
DEFAULT_TERRAFORM_PATH = Path("./generated.auto.tfvars")
DEFAULT_CHECKSUM_PATH = Path("./build/checksums.yaml")

# Network configuration
DEFAULT_TIMEOUT = 45
DEFAULT_RETRY_COUNT = 3
DEFAULT_CHUNK_SIZE = 1024 * 1024  # 1MB
USER_AGENT = 'homelab-checksum-generator/1.0'


# Custom exceptions
class ChecksumError(Exception):
    """Base exception for checksum generation errors."""
    pass


class ParseError(ChecksumError):
    """Error parsing Terraform/YAML files."""
    pass


class NetworkError(ChecksumError):
    """Error during network operations."""
    pass


@dataclass
class ImageInfo:
    """Image information extracted from Terraform configuration.

    Attributes:
        image_type: Type of image (container or vm)
        url: Download URL for the image
        filename: Expected filename for the image
        key: Unique identifier for the image
    """
    key: str
    url: str
    image_type: str
    filename: str = ""


@dataclass
class ChecksumInfo:
    """Checksum metadata and validation information.

    Attributes:
        checksum: SHA256 hash of the image
        algorithm: Hash algorithm used (default: sha256)
        source_url: URL where checksum was retrieved from
        last_updated: ISO timestamp of last update
    """
    checksum: str
    algorithm: str = "sha256"
    source_url: str = ""
    last_updated: str = ""


class ConfigurationError(ChecksumError):
    """Raised when configuration is invalid."""
    pass


class NetworkError(ChecksumError):
    """Raised when network operations fail."""
    pass


class ParsingError(ChecksumError):
    """Raised when parsing fails."""
    pass


# Context managers for error handling
@contextmanager
def checksum_generation_context(operation: str) -> Generator[None, None, None]:
    """Context manager for checksum generation operations.

    Args:
        operation: Description of the operation being performed

    Yields:
        None

    Raises:
        ChecksumError: With appropriate exit code set
    """
    logger = logging.getLogger(__name__)
    try:
        yield
    except ParseError as e:
        logger.error(f"Parsing error during {operation}: {e}")
        sys.exit(EXIT_PARSING_ERROR)
    except NetworkError as e:
        logger.error(f"Network error during {operation}: {e}")
        sys.exit(EXIT_NETWORK_ERROR)
    except ChecksumError as e:
        logger.error(f"Checksum error during {operation}: {e}")
        sys.exit(EXIT_CHECKSUM_ERROR)
    except Exception as e:
        logger.error(f"Unexpected error during {operation}: {e}")
        sys.exit(EXIT_UNEXPECTED_ERROR)


class ChecksumRepository:
    """Manages loading and saving checksum data."""

    logger = logging.getLogger(__name__)

    def __init__(self, checksum_file: Path):
        """Initialize checksum repository.

        Args:
            checksum_file: Path to the checksums YAML file
        """
        self.checksum_file = checksum_file

    def load_existing_checksums(self) -> Dict[str, ChecksumInfo]:
        """Load existing checksums from file.

        Returns:
            Dictionary mapping image keys to checksum information

        Raises:
            ParseError: If YAML parsing fails
        """
        if not self.checksum_file.exists():
            self.logger.info(f"No existing checksum file found at {self.checksum_file}")
            return {}

        try:
            with self.checksum_file.open('r', encoding='utf-8') as f:
                data = yaml.safe_load(f) or {}

            checksums = {}
            for key, info in data.get('checksums', {}).items():
                checksums[key] = ChecksumInfo(
                    checksum=info.get('checksum', ''),
                    algorithm=info.get('algorithm', 'sha256'),
                    source_url=info.get('source_url', ''),
                    last_updated=info.get('last_updated', '')
                )

            self.logger.info(f"Loaded {len(checksums)} existing checksums")
            return checksums

        except (yaml.YAMLError, KeyError, TypeError) as e:
            raise ParseError(f"Failed to parse checksum file {self.checksum_file}: {e}")

    def save_checksums(self, checksums: Dict[str, ChecksumInfo]) -> None:
        """Save checksums to file.

        Args:
            checksums: Dictionary mapping image keys to checksum information

        Raises:
            ChecksumError: If file writing fails
        """
        self.checksum_file.parent.mkdir(parents=True, exist_ok=True)

        data = {
            'checksums': {
                key: {
                    'checksum': info.checksum,
                    'algorithm': info.algorithm,
                    'source_url': info.source_url,
                    'last_updated': info.last_updated
                }
                for key, info in checksums.items()
            }
        }

        try:
            with self.checksum_file.open('w', encoding='utf-8') as f:
                yaml.safe_dump(data, f, sort_keys=True, default_flow_style=False)

            self.logger.info(f"Saved {len(checksums)} checksums to {self.checksum_file}")

        except (yaml.YAMLError, OSError) as e:
            raise ChecksumError(f"Failed to save checksums to {self.checksum_file}: {e}")


class TerraformParser:
    """Parses Terraform files to extract image information."""

    logger = logging.getLogger(__name__)

    # Compiled regex patterns for better performance
    IMAGES_BLOCK_RE = re.compile(r'^images\s*=\s*\{(.*?)^}', re.DOTALL | re.MULTILINE)
    IMAGE_ENTRY_RE = re.compile(r'([a-zA-Z0-9_.-]+)\s*=\s*\{(.*?)\}', re.DOTALL)
    URL_RE = re.compile(r'image_url\s*=\s*"([^"]+)"')
    TYPE_RE = re.compile(r'image_type\s*=\s*"([^"]+)"')
    FILENAME_RE = re.compile(r'image_filename\s*=\s*"([^"]*)"')

    def __init__(self, terraform_file: Path):
        """Initialize Terraform parser.

        Args:
            terraform_file: Path to the generated Terraform variables file
        """
        self.terraform_file = terraform_file

    def parse_images(self) -> Dict[str, ImageInfo]:
        """Parse image definitions from Terraform file.

        Returns:
            Dictionary mapping image keys to image information

        Raises:
            ConfigurationError: If Terraform file not found
            ParseError: If parsing fails
        """
        if not self.terraform_file.exists():
            raise ConfigurationError(f"Terraform file not found: {self.terraform_file}")

        try:
            content = self.terraform_file.read_text(encoding='utf-8')
        except OSError as e:
            raise ParseError(f"Failed to read {self.terraform_file}: {e}")

        # Extract images block
        images_match = self.IMAGES_BLOCK_RE.search(content)
        if not images_match:
            raise ParseError("Images block not found in Terraform file")

        images_block = images_match.group(1)
        images = {}

        # Parse individual image entries
        for key, body in self.IMAGE_ENTRY_RE.findall(images_block):
            url_match = self.URL_RE.search(body)
            type_match = self.TYPE_RE.search(body)
            filename_match = self.FILENAME_RE.search(body)

            if not url_match or not type_match:
                self.logger.warning(f"Skipping incomplete image entry: {key}")
                continue

            images[key] = ImageInfo(
                key=key,
                url=url_match.group(1),
                image_type=type_match.group(1),
                filename=filename_match.group(1) if filename_match else ""
            )

        self.logger.info(f"Parsed {len(images)} image definitions")
        return images


class ChecksumGenerator:
    """Generates checksums for images."""

    logger = logging.getLogger(__name__)

    def __init__(self, timeout: int = DEFAULT_TIMEOUT, retry_count: int = DEFAULT_RETRY_COUNT,
                 chunk_size: int = DEFAULT_CHUNK_SIZE):
        """Initialize checksum generator.

        Args:
            timeout: Network request timeout in seconds
            retry_count: Number of retries for failed requests
            chunk_size: Download chunk size in bytes
        """
        self.timeout = timeout
        self.retry_count = retry_count
        self.chunk_size = chunk_size

    def get_checksum(self, image: ImageInfo, existing_checksum: Optional[ChecksumInfo] = None) -> Optional[ChecksumInfo]:
        """Get checksum for an image, trying remote sources first.

        Args:
            image: Image information
            existing_checksum: Previously computed checksum if available

        Returns:
            ChecksumInfo if successful, None otherwise
        """
        self.logger.info(f"Processing {image.key}: {image.url}")

        # Check if we can skip this image (URL unchanged and recent checksum)
        if existing_checksum and self._should_skip_update(image, existing_checksum):
            self.logger.info(f"Skipping {image.key} - URL unchanged and checksum is recent")
            return existing_checksum

        # Try remote checksum first
        remote_checksum = self._get_remote_checksum(image.url)
        if remote_checksum:
            self.logger.info(f"Found remote checksum for {image.key}")
            # Add metadata
            remote_checksum.source_url = image.url
            remote_checksum.last_updated = time.strftime('%Y-%m-%d %H:%M:%S')
            return remote_checksum

        # Fall back to downloading and computing checksum
        local_checksum = self._compute_local_checksum(image.url)
        if local_checksum:
            return ChecksumInfo(
                checksum=local_checksum,
                algorithm="sha256",
                source_url=image.url,
                last_updated=time.strftime('%Y-%m-%d %H:%M:%S')
            )

        self.logger.error(f"Failed to obtain checksum for {image.key}")
        return None

    def _get_remote_checksum(self, url: str) -> Optional[ChecksumInfo]:
        """Attempt to fetch checksum from remote sources.

        Args:
            url: Image URL

        Returns:
            ChecksumInfo if found, None otherwise
        """
        base_url = url.rsplit('/', 1)[0]
        filename = url.rsplit('/', 1)[1]

        # Try different checksum file patterns
        checksum_patterns = [
            # Debian uses SHA512SUMS for cloud images
            ('SHA512SUMS', 'sha512', r'[0-9a-fA-F]{128}'),
            # Standard SHA256SUMS (Ubuntu, etc.)
            ('SHA256SUMS', 'sha256', r'[0-9a-fA-F]{64}'),
            # Some distributions use different names
            ('CHECKSUMS', 'sha256', r'[0-9a-fA-F]{64}'),
        ]

        for sums_file, algorithm, pattern in checksum_patterns:
            sums_url = f"{base_url}/{sums_file}"

            try:
                req = urllib.request.Request(sums_url, headers={'User-Agent': USER_AGENT})
                with urllib.request.urlopen(req, timeout=self.timeout) as response:
                    content = response.read().decode('utf-8', 'replace')

                # Parse checksum file format: checksum  filename
                for line in content.splitlines():
                    if filename in line:
                        parts = line.split()
                        for part in parts:
                            if re.fullmatch(pattern, part):
                                self.logger.debug(f"Found {algorithm} checksum in {sums_file} for {filename}")
                                return ChecksumInfo(checksum=part.lower(), algorithm=algorithm)

            except (URLError, HTTPError, UnicodeDecodeError) as e:
                self.logger.debug(f"Remote checksum lookup failed for {sums_url}: {e}")
                continue

        return None

    def _should_skip_update(self, image: ImageInfo, existing: ChecksumInfo) -> bool:
        """Check if we should skip updating this checksum.

        Args:
            image: Image information
            existing: Existing checksum information

        Returns:
            True if checksum update can be skipped
        """
        # Skip if URL hasn't changed and checksum is recent (less than 7 days old)
        if existing.source_url != image.url:
            self.logger.debug(f"URL changed for {image.key}: {existing.source_url} -> {image.url}")
            return False

        if not existing.last_updated:
            self.logger.debug(f"No last_updated timestamp for {image.key}")
            return False

        try:
            from datetime import datetime, timedelta
            last_update = datetime.strptime(existing.last_updated, '%Y-%m-%d %H:%M:%S')
            age_days = (datetime.now() - last_update).days

            # Check if URL contains dynamic paths that change frequently
            dynamic_patterns = ['current/', 'latest/', 'daily/']
            is_dynamic = any(pattern in image.url for pattern in dynamic_patterns)

            # Use shorter update interval for dynamic URLs (1 day vs 7 days)
            max_age = 1 if is_dynamic else 7

            # Skip if checksum is recent enough
            if age_days < max_age:
                self.logger.debug(f"Checksum for {image.key} is {age_days} days old ({'dynamic' if is_dynamic else 'static'} URL, max age {max_age} days) - skipping")
                return True
            else:
                self.logger.debug(f"Checksum for {image.key} is {age_days} days old ({'dynamic' if is_dynamic else 'static'} URL, max age {max_age} days) - updating")
                return False

        except ValueError as e:
            self.logger.debug(f"Invalid timestamp format for {image.key}: {e}")
            return False

    def _compute_local_checksum(self, url: str) -> Optional[str]:
        """Download file and compute SHA256 checksum.

        Args:
            url: Image URL to download

        Returns:
            SHA256 checksum if successful, None otherwise
        """
        self.logger.info(f"Starting download for checksum computation: {url}")

        for attempt in range(1, self.retry_count + 1):
            try:
                self.logger.info(f"Attempt {attempt}: Creating request...")
                req = urllib.request.Request(url, headers={'User-Agent': USER_AGENT})

                self.logger.info(f"Attempt {attempt}: Opening URL...")
                with urllib.request.urlopen(req, timeout=self.timeout) as response:
                    self.logger.info(f"Attempt {attempt}: Response received, starting download...")

                    # Get content length if available
                    content_length = response.getheader('Content-Length')
                    if content_length:
                        expected_size = int(content_length)
                        self.logger.info(f"Expected download size: {expected_size:,} bytes ({expected_size / 1024 / 1024:.1f} MB)")

                    hasher = hashlib.sha256()
                    total_size = 0
                    last_log_size = 0

                    while True:
                        chunk = response.read(self.chunk_size)
                        if not chunk:
                            break
                        hasher.update(chunk)
                        total_size += len(chunk)

                        # Log progress every 100MB
                        if total_size - last_log_size >= 100 * 1024 * 1024:
                            self.logger.info(f"Downloaded {total_size:,} bytes ({total_size / 1024 / 1024:.1f} MB)...")
                            last_log_size = total_size

                    self.logger.info(f"Download complete! Total: {total_size:,} bytes ({total_size / 1024 / 1024:.1f} MB)")
                    self.logger.info(f"Computing final checksum...")
                    checksum = hasher.hexdigest()
                    self.logger.info(f"Checksum computed: {checksum}")
                    return checksum

            except (URLError, HTTPError) as e:
                self.logger.warning(f"Attempt {attempt} failed for {url}: {e}")
                if attempt < self.retry_count:
                    self.logger.info(f"Retrying in {2 ** attempt} seconds...")
                    time.sleep(2 ** attempt)  # Exponential backoff

        return None


class ChecksumManager:
    """Main orchestrator for checksum operations."""

    logger = logging.getLogger(__name__)

    def __init__(self, terraform_file: Path, checksum_file: Path, force: bool = False):
        """Initialize checksum manager.

        Args:
            terraform_file: Path to Terraform variables file
            checksum_file: Path to checksums YAML file
            force: Force regeneration of all checksums
        """
        self.terraform_parser = TerraformParser(terraform_file)
        self.checksum_repo = ChecksumRepository(checksum_file)
        self.checksum_generator = ChecksumGenerator()
        self.force = force

    def update_checksums(self) -> bool:
        """Update checksums for all images.

        Returns:
            True if any checksums were changed

        Raises:
            ChecksumError: If update fails
        """
        # Load existing checksums
        existing_checksums = self.checksum_repo.load_existing_checksums()

        # Parse image definitions
        images = self.terraform_parser.parse_images()

        # Generate new checksums
        new_checksums = {}
        changed = False

        for image_key, image_info in images.items():
            existing = existing_checksums.get(image_key)
            # Override skip logic if force is enabled
            if self.force and existing:
                existing = None  # Force regeneration
            checksum_info = self.checksum_generator.get_checksum(image_info, existing)

            if checksum_info:
                # Check if checksum actually changed
                if not existing or existing.checksum != checksum_info.checksum or existing.source_url != checksum_info.source_url:
                    changed = True
                    if existing and existing.checksum != checksum_info.checksum:
                        self.logger.info(f"Checksum updated for {image_key}")
                    elif not existing:
                        self.logger.info(f"New checksum added for {image_key}")
                    elif existing.source_url != checksum_info.source_url:
                        self.logger.info(f"URL updated for {image_key}")

                new_checksums[image_key] = checksum_info

            elif image_key in existing_checksums:
                # Keep existing checksum if we can't generate a new one
                self.logger.warning(f"Keeping existing checksum for {image_key}")
                new_checksums[image_key] = existing_checksums[image_key]

            else:
                self.logger.error(f"No checksum available for {image_key}")

        # Save updated checksums
        if new_checksums:
            self.checksum_repo.save_checksums(new_checksums)

        return changed


def main() -> int:
    """Main entry point.

    Returns:
        Exit code (0 for success, non-zero for errors)
    """
    parser = argparse.ArgumentParser(
        description="Generate checksums for infrastructure images",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument('--terraform-file', '-t', type=Path,
                        default=DEFAULT_TERRAFORM_PATH,
                        help='Path to Terraform file containing image definitions'
    )

    parser.add_argument('--checksum-file', '-c', type=Path,
                        default=DEFAULT_CHECKSUM_PATH,
                        help='Path to checksum output file'
    )

    parser.add_argument('--verbose', '-v', action='store_true',
                        help='Enable verbose logging'
    )

    parser.add_argument('--force', '-f', action='store_true',
                        help='Force update all checksums regardless of age'
    )

    args = parser.parse_args()

    # Setup logging from config
    setup_logging_from_config(
        profile='development' if args.verbose else 'production',
        verbose=args.verbose
    )
    logger = logging.getLogger(__name__)

    with checksum_generation_context("checksum generation"):
        manager = ChecksumManager(args.terraform_file, args.checksum_file, args.force)
        changed = manager.update_checksums()

        if changed:
            logger.info("Checksums updated successfully")
        else:
            logger.info("No checksum changes detected")

    return EXIT_SUCCESS


if __name__ == '__main__':
    sys.exit(main())
