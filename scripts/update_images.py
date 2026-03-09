#!/usr/bin/env python3
"""
Talos Schematic & Image Generator

This script automates the process of generating Talos Image Schematics and updating the
infrastructure image manifest while preserving its structure (comments, empty lines).

Workflow:
1. Reads schematic definitions from a YAML source file.
2. Uses `omnictl` to generate a unique Factory ID for each schematic profile.
3. Reads the target `image.yaml` file to find corresponding entries (matched by key suffix).
4. Extracts the currently used Talos version from the existing image URL.
5. Constructs the new Factory Image URL.
6. Checks if the URL has changed or if the checksum is missing.
7. If an update is required:
   - Downloads the new image (streamed).
   - Calculates the SHA256 checksum.
   - Surgically updates `image.yaml` using regex to preserve comments and structure.

Usage:
    python3 scripts/update_images.py [--source path/to/schematics.yaml] [--output path/to/image.yaml] [--refresh]
"""

import argparse
import hashlib
import os
import re
import subprocess
import sys
import traceback
import urllib.request
import yaml

from dataclasses import dataclass, field
from typing import List, Dict, Optional, Tuple


# --- Configuration ---
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)

DEFAULT_SOURCE = os.path.join(REPO_ROOT, "infrastructure", "manifest", "20-image", "schematics.yaml")
DEFAULT_TARGET = os.path.join(REPO_ROOT, "infrastructure", "manifest", "20-image", "image.yaml")
DEFAULT_TALOS_VERSION = "1.12.0"  # Fallback version if parsing fails


@dataclass
class SchematicConfig:
    """Represents a parsed Talos schematic configuration."""
    profile_name: str
    extensions: List[str] = field(default_factory=list)
    kernel_args: List[str] = field(default_factory=list)
    initial_labels: Dict[str, str] = field(default_factory=dict)


def parse_profile(doc: dict) -> Optional[SchematicConfig]:
    """
    Parses a dictionary (YAML document) into a SchematicConfig object.
    """
    try:
        customization = doc.get('customization', {})

        # 1. Parse Meta to find machineLabels
        meta_items = customization.get('meta', [])
        labels = {}

        for item in meta_items:
            value = item.get('value', '')
            if 'machineLabels' in value:
                # The value is a YAML string inside the metadata
                data = yaml.safe_load(value)
                labels = data.get('machineLabels', {})
                break

        # Filter empty keys/values and ensure string types
        final_labels = {str(k).strip(): str(v).strip() for k, v in labels.items() if k and v}

        if not final_labels:
            print("  Warning: No valid machineLabels found in document.")
            return None

        # 2. Extract profile name (image-id)
        profile_name = final_labels.get('image-id')
        if not profile_name:
            print(f"  Warning: Missing 'image-id' in labels: {final_labels}")
            return None

        # 3. Parse extensions
        extensions = []
        sys_ext = customization.get('systemExtensions', {})
        extensions.extend(sys_ext.get('officialExtensions', []))

        # 4. Parse kernel args
        kernel_args = customization.get('extraKernelArgs', [])

        return SchematicConfig(
            profile_name=profile_name,
            extensions=extensions,
            kernel_args=kernel_args,
            initial_labels=final_labels
        )

    except Exception:
        print("  Error parsing document:")
        traceback.print_exc()
        return None


def generate_schematic_id(config: SchematicConfig) -> Optional[str]:
    """
    Invokes `omnictl` to generate the schematic ID based on the configuration.
    """
    cmd = [
        'omnictl', 'download', 'nocloud',
        '--arch', 'amd64',
        '--pxe'
    ]

    for ext in config.extensions:
        cmd.extend(['--extensions', ext])

    for arg in config.kernel_args:
        cmd.extend(['--extra-kernel-args', arg])

    for k, v in config.initial_labels.items():
        cmd.extend(['--initial-labels', f"{k}={v}"])

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        output = result.stdout.strip()
        error_output = result.stderr.strip()

        # Check for version mismatch warning
        version_mismatch_msg = "[WARN] omnictl version differs from the backend version"
        if version_mismatch_msg in output or version_mismatch_msg in error_output:
            print(f"\nERROR: omnictl version mismatch detected for '{config.profile_name}'.")
            print("Please update omnictl to match the backend version.")
            sys.exit(1)

        for line in output.splitlines():
            # Extract ID from PXE URL
            match = re.search(r'https://pxe\.factory\.talos\.dev/pxe/([a-f0-9]+)/', line)
            if match:
                return match.group(1)

        print(f"  Error: Could not parse ID from omnictl output for '{config.profile_name}'")
        return None

    except subprocess.CalledProcessError as e:
        print(f"  Error running omnictl for '{config.profile_name}': {e.stderr.strip()}")
        return None


def calculate_checksum(url: str) -> Optional[str]:
    """
    Downloads the file from the given URL and calculates its SHA256 checksum.
    """
    print(f"    Downloading to calculate checksum: {url}")
    sha256_hash = hashlib.sha256()
    try:
        req = urllib.request.Request(
            url,
            data=None,
            headers={
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36'
            }
        )
        with urllib.request.urlopen(req) as response:
            while chunk := response.read(65536):  # 64KB chunks
                sha256_hash.update(chunk)
        return sha256_hash.hexdigest()
    except Exception as e:
        print(f"    Error downloading/hashing {url}: {e}")
        return None


def update_yaml_surgically(file_path: str, updates: Dict[str, Dict[str, str]]):
    """
    Updates the YAML file using regex to preserve comments and empty lines.
    """
    with open(file_path, 'r') as f:
        lines = f.readlines()

    new_lines = []
    current_key = None

    for line in lines:
        # Detect top-level image keys (indented by 2 spaces)
        key_match = re.match(r'^  (\w+):', line)
        if key_match:
            current_key = key_match.group(1)
            new_lines.append(line)
            continue

        if current_key and current_key in updates:
            # Check for image_url
            url_match = re.search(r'(image_url:\s*)(\S+)', line)
            if url_match:
                new_url = updates[current_key]['url']
                # Preserve indentation and prefix, replace the rest
                new_line = f"{line[:url_match.start(2)]}{new_url}\n"
                new_lines.append(new_line)
                continue

            # Check for image_checksum
            # Supports both quoted and unquoted checksums
            checksum_match = re.search(r'(image_checksum:\s*)("?)([a-f0-9]*)("?)', line)
            if checksum_match:
                new_checksum = updates[current_key]['checksum']
                prefix = checksum_match.group(1)
                quote_start = checksum_match.group(2)
                quote_end = checksum_match.group(4)
                # Preserve indentation, prefix and existing quoting
                new_line = f"{line[:checksum_match.start(1)]}{prefix}{quote_start}{new_checksum}{quote_end}\n"
                new_lines.append(new_line)
                continue

        new_lines.append(line)

    with open(file_path, 'w') as f:
        f.writelines(new_lines)


def main():
    parser = argparse.ArgumentParser(description="Generate Talos Schematic IDs and update image.yaml.")
    parser.add_argument("--source", default=DEFAULT_SOURCE, help="Path to schematics.yaml")
    parser.add_argument("--output", default=DEFAULT_TARGET, help="Path to image.yaml file")
    parser.add_argument("--refresh", action="store_true", help="Force refresh of all checksums")
    args = parser.parse_args()

    if not os.path.exists(args.source) or not os.path.exists(args.output):
        print("Error: Source or target file not found.")
        sys.exit(1)

    print(f"Reading schematics from '{args.source}'...")
    with open(args.source, 'r') as f:
        docs = list(yaml.safe_load_all(f))

    print(f"Reading targets from '{args.output}'...")
    with open(args.output, 'r') as f:
        image_data = yaml.safe_load(f)

    if 'image' not in image_data:
        print("Error: 'image' key not found in target YAML.")
        sys.exit(1)

    pending_updates = {}

    for doc in docs:
        if not doc or isinstance(doc, str):
            continue

        config = parse_profile(doc)
        if not config:
            continue

        print(f"\nProcessing profile: {config.profile_name}")

        schematic_id = generate_schematic_id(config)
        if not schematic_id:
            continue
        print(f"  Generated ID: {schematic_id}")

        target_key = next((k for k in image_data['image'] if k.endswith(f"_{config.profile_name}")), None)
        if not target_key:
            print(f"  Warning: No matching key for profile '{config.profile_name}'")
            continue

        current_info = image_data['image'][target_key]
        current_url = current_info.get('image_url')
        current_checksum = current_info.get('image_checksum')

        # Determine Version
        talos_version = DEFAULT_TALOS_VERSION
        if current_url:
            url_match = re.search(r'/image/[a-f0-9]+/(?P<version>[^/]+)/', current_url)
            if url_match:
                talos_version = url_match.group('version')

        new_url = f"https://factory.talos.dev/image/{schematic_id}/{talos_version}/nocloud-amd64.raw"

        if not args.refresh and current_url == new_url and current_checksum:
            print("  [OK] URL matches existing configuration. No change.")
            continue

        print(f"  [UPDATE] Updating {target_key}...")
        checksum = calculate_checksum(new_url)
        if checksum:
            pending_updates[target_key] = {"url": new_url, "checksum": checksum}
            print(f"  New Checksum: {checksum}")

    if pending_updates:
        print(f"\nSurgically updating {len(pending_updates)} entries in '{args.output}'...")
        update_yaml_surgically(args.output, pending_updates)
        print("Done.")
    else:
        print("\nAll images are up to date.")


if __name__ == "__main__":
    main()
