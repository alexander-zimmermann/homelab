#!/usr/bin/env python3
import sys
import re
import hashlib
import urllib.request
import os

IMAGE_YAML_PATH = "infrastructure/manifest/20-image/image.yaml"

def calculate_checksum(url, algo="sha256"):
    print(f"Downloading {url}...")
    hash_func = getattr(hashlib, algo)()
    try:
        with urllib.request.urlopen(url) as response:
            while True:
                chunk = response.read(8192)
                if not chunk:
                    break
                hash_func.update(chunk)
        return hash_func.hexdigest()
    except Exception as e:
        print(f"Error downloading {url}: {e}")
        return None

def update_image_yaml():
    if not os.path.exists(IMAGE_YAML_PATH):
        print(f"File not found: {IMAGE_YAML_PATH}")
        sys.exit(1)

    with open(IMAGE_YAML_PATH, 'r') as f:
        lines = f.readlines()

    new_lines = []
    current_url = None

    for i, line in enumerate(lines):
        # Detect and update Algorithm
        # If the file defines an algorithm, we enforce sha256 to match our calculation.
        algo_match = re.search(r'(image_checksum_algorithm:\s*)"(.*)"', line)
        if algo_match:
             prefix = algo_match.group(1)
             # Always enforce sha256 if we are recalculating everything or just encountering the field
             # Ideally we only change it if we also touched the checksum, but keeping it consistent is safer.
             print("  Updating algorithm to sha256")
             new_lines.append(f'{prefix}"sha256"\n')
             continue

        # Check for URL
        url_match = re.search(r'image_url:\s*(https?://\S+)', line)
        if url_match:
            current_url = url_match.group(1)
            print(f"Found URL: {current_url}")
            new_lines.append(line)
            continue

        # Check for Checksum
        checksum_match = re.search(r'(image_checksum:\s*)"([a-f0-9]*)"', line)
        if checksum_match and current_url:
            prefix = checksum_match.group(1)
            old_checksum = checksum_match.group(2)

            # Recalculate hash (SHA256)
            new_checksum = calculate_checksum(current_url, algo="sha256")

            if new_checksum:
                print(f"  Old: {old_checksum[:10]}...")
                print(f"  New: {new_checksum[:10]}...")
                new_line = f'{line[:checksum_match.start(1)]}{prefix}"{new_checksum}"\n'
                new_lines.append(new_line)
            else:
                print("  Failed to calculate checksum, keeping old.")
                new_lines.append(line)

            current_url = None # Reset after using
        else:
            new_lines.append(line)

    with open(IMAGE_YAML_PATH, 'w') as f:
        f.writelines(new_lines)

if __name__ == "__main__":
    update_image_yaml()
