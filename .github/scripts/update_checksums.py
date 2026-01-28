#!/usr/bin/env python3
import sys
import re
import hashlib
import urllib.request
import os

IMAGE_YAML_PATH = "infrastructure/manifest/20-image/image.yaml"
DEFAULT_ALGO = "sha256"

def get_hash_func(algo):
    """Return a hashlib function for the given algorithm name."""
    try:
        return getattr(hashlib, algo)()
    except AttributeError:
        print(f"Error: Unsupported algorithm '{algo}'")
        return None

def calculate_checksum(url, algo=DEFAULT_ALGO):
    """Download the file from URL and calculate its checksum."""
    print(f"Downloading {url} with {algo}...")
    hash_func = get_hash_func(algo)
    if not hash_func:
        return None

    try:
        with urllib.request.urlopen(url, timeout=30) as response:
            while True:
                chunk = response.read(8192)
                if not chunk:
                    break
                hash_func.update(chunk)
        return hash_func.hexdigest()
    except Exception as e:
        print(f"Error downloading {url}: {e}")
        return None

def parse_algorithms(lines):
    """
    Scan lines to map URLs to their specified checksum algorithms.
    Returns a dict: {url: algorithm}
    """
    algorithms = {}
    temp_url = None

    for line in lines:
        url_match = re.search(r'image_url:\s*(https?://\S+)', line)
        if url_match:
            temp_url = url_match.group(1)

        algo_match = re.search(r'image_checksum_algorithm:\s*"(.*)"', line)
        if algo_match and temp_url:
            algorithms[temp_url] = algo_match.group(1)
            temp_url = None

    return algorithms

def update_lines(lines, algorithms):
    """
    Process lines and update checksums where applicable.
    Returns: (new_lines, success_boolean)
    """
    new_lines = []
    current_url = None
    success = True

    for line in lines:
        # Preserve existing algorithm lines (don't overwrite or duplicate)
        if re.search(r'image_checksum_algorithm:\s*".*"', line):
            new_lines.append(line)
            continue

        # Capture URL
        url_match = re.search(r'image_url:\s*(https?://\S+)', line)
        if url_match:
            current_url = url_match.group(1)
            new_lines.append(line)
            continue

        # Update Checksum
        checksum_match = re.search(r'(image_checksum:\s*)"([a-f0-9]*)"', line)
        if checksum_match and current_url:
            prefix = checksum_match.group(1)
            old_checksum = checksum_match.group(2)

            algo = algorithms.get(current_url, DEFAULT_ALGO)
            new_checksum = calculate_checksum(current_url, algo)

            if new_checksum:
                if new_checksum != old_checksum:
                    print(f"  Change: {old_checksum[:8]} -> {new_checksum[:8]}")
                    new_line = f'{line[:checksum_match.start(1)]}{prefix}"{new_checksum}"\n'
                    new_lines.append(new_line)
                else:
                    new_lines.append(line)
            else:
                print("  Failed to calculate checksum!")
                success = False
                new_lines.append(line)

            current_url = None
        else:
            new_lines.append(line)

    return new_lines, success

def main():
    if not os.path.exists(IMAGE_YAML_PATH):
        print(f"File not found: {IMAGE_YAML_PATH}")
        sys.exit(1)

    with open(IMAGE_YAML_PATH, 'r') as f:
        lines = f.readlines()

    algorithms = parse_algorithms(lines)
    new_lines, success = update_lines(lines, algorithms)

    if not success:
        print("Script failed due to errors.")
        sys.exit(1)

    with open(IMAGE_YAML_PATH, 'w') as f:
        f.writelines(new_lines)

if __name__ == "__main__":
    main()
