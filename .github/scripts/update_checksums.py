#!/usr/bin/env python3
"""
This script parses a YAML file containing image URLs and checksums, downloads the latest
version of each image, calculates its checksum, and updates the YAML file in-place.

It uses a regex-based approach to preserve comments and file structure (which standard
YAML parsers might destroy).

Usage:
    ./update_checksums.py [file_path] [--algorithm sha256] [--verbose]
"""

import argparse
import hashlib
import logging
import os
import re
import sys
import urllib.request
from typing import Dict, List, Optional, Tuple, Callable, Any

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(levelname)s: %(message)s"
)
logger = logging.getLogger(__name__)

DEFAULT_IMAGE_YAML_PATH = "infrastructure/manifest/20-image/image.yaml"

def get_hash_func(algo: str) -> Optional[Callable[[], Any]]:
    """
    Return a hashlib function constructor for the given algorithm name.

    Args:
        algo: Hash algorithm name (e.g., "sha256", "md5").

    Returns:
        Hash constructor or None if unsupported.
    """
    if hasattr(hashlib, algo):
        return getattr(hashlib, algo) # type: ignore

    logger.error(f"Unsupported algorithm '{algo}'")
    return None

def calculate_checksum(url: str, algo: str) -> Optional[str]:
    """
    Download the file from URL and calculate its checksum.

    Args:
        url: URL to download.
        algo: Hash algorithm to use.

    Returns:
        Hex digest of the checksum, or None if failed.
    """
    logger.info(f"Downloading {url} with {algo}...")
    hash_constructor = get_hash_func(algo)
    if not hash_constructor:
        return None

    hash_obj = hash_constructor()
    try:
        # Standard timeout to avoid hanging indefinitely.
        # Add User-Agent to avoid 404s from some registries (e.g. linuxcontainers.org)
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=30) as response:
            while True:
                chunk = response.read(8192)
                if not chunk:
                    break
                hash_obj.update(chunk)
        return hash_obj.hexdigest()
    except Exception as e:
        logger.error(f"Error downloading {url}: {e}")
        return None

def parse_algorithms(lines: List[str]) -> Dict[str, str]:
    """
    Scan lines to map URLs to their specified checksum algorithms.

    Args:
        lines: List of lines from the file.

    Returns:
        Dict mapping URL -> algorithm name.
    """
    algorithms: Dict[str, str] = {}
    temp_url: Optional[str] = None

    for line in lines:
        # Match "image_url: https://..."
        url_match = re.search(r'image_url:\s*(https?://\S+)', line)
        if url_match:
            temp_url = url_match.group(1)

        # Match "image_checksum_algorithm: "sha256""
        algo_match = re.search(r'image_checksum_algorithm:\s*"(.*)"', line)
        if algo_match and temp_url:
            algorithms[temp_url] = algo_match.group(1)
            temp_url = None

    return algorithms

def update_lines(lines: List[str], algorithms: Dict[str, str], default_algo: str) -> Tuple[List[str], bool]:
    """
    Process lines and update checksums where applicable.

    Args:
        lines: Original file lines.
        algorithms: Map of URL to algorithm.
        default_algo: Fallback algorithm.

    Returns:
        Tuple of (new_lines list, success boolean).
    """
    new_lines: List[str] = []
    current_url: Optional[str] = None
    success = True

    for line in lines:
        # Preserve lines that define the algorithm (don't overwrite or duplicate logic)
        if re.search(r'image_checksum_algorithm:\s*".*"', line):
            new_lines.append(line)
            continue

        # Capture URL
        url_match = re.search(r'image_url:\s*(https?://\S+)', line)
        if url_match:
            current_url = url_match.group(1)
            new_lines.append(line)
            continue

        # Find and Update Checksum
        # Look for 'image_checksum: "..."'
        checksum_match = re.search(r'(image_checksum:\s*)"([a-f0-9]*)"', line)
        if checksum_match and current_url:
            prefix = checksum_match.group(1)
            old_checksum = checksum_match.group(2)

            algo = algorithms.get(current_url, default_algo)
            new_checksum = calculate_checksum(current_url, algo)

            if new_checksum:
                if new_checksum != old_checksum:
                    logger.info(f"  Change: {old_checksum[:8]} -> {new_checksum[:8]}")
                    # Reconstruct line with new checksum
                    new_line = f'{line[:checksum_match.start(1)]}{prefix}"{new_checksum}"\n'
                    new_lines.append(new_line)
                else:
                    logger.debug("  No change.")
                    new_lines.append(line)
            else:
                logger.error("  Failed to calculate checksum!")
                success = False
                new_lines.append(line)

            current_url = None
        else:
            new_lines.append(line)

    return new_lines, success

def main() -> None:
    parser = argparse.ArgumentParser(description="Update checksums in a YAML file.")
    parser.add_argument("file_path", nargs="?", default=DEFAULT_IMAGE_YAML_PATH,
                        help=f"Path to the YAML file (default: {DEFAULT_IMAGE_YAML_PATH})")
    parser.add_argument("--algorithm", default="sha256",
                        help="Default hash algorithm if not specified in file (default: sha256)")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose logging")

    args = parser.parse_args()

    if args.verbose:
        logger.setLevel(logging.DEBUG)

    if not os.path.exists(args.file_path):
        logger.error(f"File not found: {args.file_path}")
        sys.exit(1)

    logger.info(f"Processing {args.file_path}...")
    with open(args.file_path, 'r') as f:
        lines = f.readlines()

    algorithms = parse_algorithms(lines)
    new_lines, success = update_lines(lines, algorithms, args.algorithm)

    if not success:
        logger.error("Script failed due to errors during checksum calculation.")
        sys.exit(1)

    with open(args.file_path, 'w') as f:
        f.writelines(new_lines)

    logger.info("Successfully updated checksums.")

if __name__ == "__main__":
    main()
