import yaml
import subprocess
import re
import os
import sys
from dataclasses import dataclass, field
from typing import List, Dict, Optional

# Configuration
SCHEMATICS_FILE = 'manifest/schematics.yaml'
OUTPUT_FILE = 'build/schematicIDs.yaml'

@dataclass
class SchematicConfig:
    profile_name: str
    extensions: List[str] = field(default_factory=list)
    kernel_args: List[str] = field(default_factory=list)
    initial_labels: Dict[str, str] = field(default_factory=dict)

import traceback

def parse_profile(doc: dict) -> Optional[SchematicConfig]:
    """Parses a YAML document into a SchematicConfig object."""
    try:
        customization = doc.get('customization', {})

        # Parse Meta for labels & profile name
        meta_items = customization.get('meta', [])
        labels = {}
        for item in meta_items:
            # We look for the item containing 'machineLabels' in its value
            value = item.get('value', '')
            if 'machineLabels' in value:
                # Parse the inner YAML block
                data = yaml.safe_load(value)
                labels = data.get('machineLabels', {})
                break

        if not labels:
            return None

        # Ensure we have a clean dict.
        final_labels = {}
        if isinstance(labels, dict):
             # Since YAML is now clean (key: value), we can trust the dict mostly.
             for k, v in labels.items():
                 final_labels[str(k).strip()] = str(v).strip()

        labels = final_labels

        if not labels:
             print(f"Error: machineLabels is empty or invalid.")
             return None

        # Simplified Logic: Use 'image-id' directly as profile name
        profile_name = labels.get('image-id')
        if not profile_name:
            print(f"Warning: Missing 'image-id' in labels: {labels}")
            return None

        # Parse extensions
        extensions = []
        sys_ext = customization.get('systemExtensions', {})
        extensions.extend(sys_ext.get('officialExtensions', []))

        # Parse kernel args
        kernel_args = customization.get('extraKernelArgs', [])

        return SchematicConfig(
            profile_name=profile_name,
            extensions=extensions,
            kernel_args=kernel_args,
            initial_labels=labels
        )

    except Exception:
        print(f"Error parsing document:")
        traceback.print_exc()
        return None

def generate_schematic_id(config: SchematicConfig) -> Optional[str]:
    """Invokes omnictl to generate the schematic ID."""

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

        # Example: https://pxe.factory.talos.dev/pxe/<ID>/<VERSION>/nocloud-amd64
        match = re.search(r'https://pxe\.factory\.talos\.dev/pxe/([a-f0-9]+)/', output)
        if match:
            return match.group(1)
        else:
            print(f"  Error: Could not parse ID from omnictl output for {config.profile_name}")
            return None

    except subprocess.CalledProcessError as e:
        print(f"  Error running omnictl for {config.profile_name}: {e.stderr.strip()}")
        return None

def main():
    if not os.path.exists(SCHEMATICS_FILE):
        print(f"Error: {SCHEMATICS_FILE} not found.")
        sys.exit(1)

    print(f"Reading schematics from {SCHEMATICS_FILE}...")

    with open(SCHEMATICS_FILE, 'r') as f:
        docs = list(yaml.safe_load_all(f))

    results = {}
    errors = 0

    for doc in docs:
        if not doc: continue

        if isinstance(doc, str):
            print(f"Skipping string document: {doc.strip()}")
            continue

        config = parse_profile(doc)
        if not config: continue

        print(f"Processing profile: {config.profile_name}")

        schematic_id = generate_schematic_id(config)
        if schematic_id:
            print(f"  -> Generated ID: {schematic_id}")
            results[config.profile_name] = {'id': schematic_id}
        else:
            errors += 1

    # Write output regardless of partial failures
    if results:
        os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
        with open(OUTPUT_FILE, 'w') as f:
            yaml.dump({'schematics': results}, f)
        print(f"\nSuccessfully wrote {len(results)} schematics to {OUTPUT_FILE}")

    if errors > 0:
        print(f"Completed with {errors} errors.")
        sys.exit(1)

if __name__ == "__main__":
    main()
