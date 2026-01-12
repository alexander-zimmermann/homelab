#!/usr/bin/env python3
"""
Talos Schematic & Image Generator

This script automates the process of generating Talos Image Schematics and updating the
infrastructure image manifest.

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
   - Updates `image.yaml` with the new URL and Checksum.

Usage:
    python3 scripts/generate_schematics.py [--source path/to/schematics.yaml] [--output path/to/image.yaml]
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
from typing import List, Dict, Optional


# --- Configuration ---
DEFAULT_SOURCE = "infrastructure/manifest/20-image/schematics.yaml"
DEFAULT_TARGET = "infrastructure/manifest/20-image/image.yaml"
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

    Expects the document to contain `customization.meta` with a `machineLabels` block
    defining the `image-id`.
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

    Uses `--pxe` flag to retrieve the URL without downloading the artifact locally
    during this step. The ID is extracted from the returned PXE URL.
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

        # Output format example:
        # https://pxe.factory.talos.dev/pxe/<ID>/<VERSION>/nocloud-amd64
        match = re.search(r'https://pxe\.factory\.talos\.dev/pxe/([a-f0-9]+)/', output)
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
    The file is read in chunks to avoid high memory usage.
    """
    print(f"    Downloading to calculate checksum: {url}")
    sha256_hash = hashlib.sha256()
    try:
        with urllib.request.urlopen(url) as response:
            while chunk := response.read(65536):  # 64KB chunks
                sha256_hash.update(chunk)
        return sha256_hash.hexdigest()
    except Exception as e:
        print(f"    Error downloading/hashing {url}: {e}")
        return None


def main():
    parser = argparse.ArgumentParser(description="Generate Talos Schematic IDs and update image.yaml.")
    parser.add_argument("--source", default=DEFAULT_SOURCE, help="Path to schematics.yaml")
    parser.add_argument("--output", default=DEFAULT_TARGET, help="Path to image.yaml file")
    args = parser.parse_args()

    # Validation
    if not os.path.exists(args.source):
        print(f"Error: Source file '{args.source}' not found.")
        sys.exit(1)

    if not os.path.exists(args.output):
        print(f"Error: Target file '{args.output}' not found.")
        sys.exit(1)

    # 1. Read Source Schematics
    print(f"Reading schematics from '{args.source}'...")
    with open(args.source, 'r') as f:
        docs = list(yaml.safe_load_all(f))

    # 2. Read Target Image Manifest
    print(f"Reading targets from '{args.output}'...")
    with open(args.output, 'r') as f:
        image_data = yaml.safe_load(f)

    if 'image' not in image_data:
        print("Error: 'image' key not found in target YAML structure.")
        sys.exit(1)

    updated_count = 0

    # 3. Process each schematic profile
    for doc in docs:
        if not doc or isinstance(doc, str):
            continue

        config = parse_profile(doc)
        if not config:
            continue

        print(f"\nProcessing profile: {config.profile_name}")

        # A. Generate Schematic ID
        schematic_id = generate_schematic_id(config)
        if not schematic_id:
            continue
        print(f"  Generated ID: {schematic_id}")

        # B. Find matching key in image.yaml
        # Matching strategy: Key must end with "_<profile_name>"
        # e.g. "vm_talos_1_12_0_cp-prod" matches profile "cp-prod"
        target_key = None
        for key in image_data['image']:
            if key.endswith(f"_{config.profile_name}"):
                target_key = key
                break

        if not target_key:
            print(f"  Warning: No matching key found in '{args.output}' for profile '{config.profile_name}'")
            continue
        print(f"  Matching key: {target_key}")

        # C. Determine Talos Version
        # We try to extracting it from the existing URL to maintain consistency.
        current_url = image_data['image'][target_key].get('image_url')
        talos_version = DEFAULT_TALOS_VERSION

        if current_url:
            # Regex to capture version segment between ID and Filename
            # Matches: .../image/<ID>/<VERSION>/...
            url_match = re.search(r'/image/[a-f0-9]+/(?P<version>[^/]+)/', current_url)
            if url_match:
                talos_version = url_match.group('version')
                print(f"  Detected Talos Version from URL: {talos_version}")
            else:
                print(f"  Warning: Could not parse version from URL '{current_url}'. Using default {talos_version}")
        else:
             print(f"  Warning: No existing URL for '{target_key}'. Using default {talos_version}")

        # D. Construct New Factory URL
        new_url = f"https://factory.talos.dev/image/{schematic_id}/{talos_version}/nocloud-amd64.raw"

        # E. Check if Update is Required
        current_checksum = image_data['image'][target_key].get('image_checksum')

        if current_url == new_url and current_checksum:
            print("  [OK] URL matches existing configuration. No change.")
            continue

        print("  [UPDATE] URL changed or checksum missing. Updating...")

        # F. Calculate Checksum (Download)
        checksum = calculate_checksum(new_url)
        if not checksum:
            print("  [FAILED] Could not checksum new image. Skipping update.")
            continue

        print(f"  New Checksum: {checksum}")

        # G. Apply Updates to Data Structure
        image_data['image'][target_key]['image_url'] = new_url
        image_data['image'][target_key]['image_checksum'] = checksum
        updated_count += 1

    # 4. Write Changes to Disk
    if updated_count > 0:
        print(f"\nWriting {updated_count} updates to '{args.output}'...")
        with open(args.output, 'w') as f:
            yaml.dump(image_data, f, sort_keys=False)
        print("Done.")
    else:
        print("\nAll images are up to date. No changes written.")


if __name__ == "__main__":
    main()
