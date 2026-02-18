#!/usr/bin/env python3
"""
This script recursively finds all `kustomization.yaml` files in the specified directory,
renders them using `kustomize`, extracts all container image references, and outputs
a sorted, unique JSON list of normalized image names.

It is designed to be used in CI/CD pipelines to determine which images need to be
pre-pulled or validated.

Usage:
    ./ci-extract-images.py [search_dir] [output_file] [--verbose]
"""

import argparse
import glob
import json
import logging
import os
import subprocess
import sys
from typing import List, Optional, Set, Any, Dict

import yaml

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(levelname)s: %(message)s"
)
logger = logging.getLogger(__name__)

def find_kustomizations(root_dir: str) -> List[str]:
    """
    Find all kustomization.yaml files under root_dir/overlays/ recursively.

    Args:
        root_dir: The root directory to search in.

    Returns:
        List of absolute paths to kustomization files.
    """
    # Look for both .yaml and .yml extensions
    patterns = [
        os.path.join(root_dir, "**/overlays/**/kustomization.yaml"),
        os.path.join(root_dir, "**/overlays/**/kustomization.yml")
    ]
    files: List[str] = []
    for pattern in patterns:
        files.extend(glob.glob(pattern, recursive=True))
    return files

def run_kustomize(path: str) -> Optional[str]:
    """
    Run `kustomize build` on the directory containing the given file.

    Args:
        path: Path to a kustomization.yaml file.

    Returns:
        The stdout (rendered YAML) if successful, None otherwise.
    """
    if not os.path.isfile(path):
        return None

    dir_path = os.path.dirname(path)
    try:
        result = subprocess.run(
            ["kustomize", "build", "--enable-helm", dir_path],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout
    except subprocess.CalledProcessError as e:
        logger.warning(f"Failed to build {path}: {e.stderr.strip()}")
        return None
    except FileNotFoundError:
        logger.error("kustomize command not found. Please ensure kustomize is installed.")
        sys.exit(1)

def _clean_image(image: str) -> Optional[str]:
    """
    Clean and normalize an image string.

    Performs the following:
    1. Trims whitespace.
    2. Filters out garbage (empty strings, simple dashes, spaces).
    3. Normalizes unqualified images to use `docker.io` prefix (for ORAS compatibility).

    Args:
        image: The raw image string.

    Returns:
        Normalized image string or None if invalid.
    """
    image = image.strip()

    # Filter out garbage (empty, simple dash, spaces implementation artifacts)
    if not image or image == "-" or " " in image:
        return None

    # Normalize image for ORAS checks (Kubernetes defaults to docker.io, ORAS does not)
    # Case 1: No registry/repo (e.g., "busybox" -> "docker.io/library/busybox")
    if "/" not in image:
        return f"docker.io/library/{image}"

    # Case 2: Has slash but first part isn't a domain/port (no dot/colon)
    # Examples: "minio/mc" -> "docker.io/minio/mc", "gcr.io/foo/bar" -> unchanged
    parts = image.split("/", 1)
    domain = parts[0]

    # Check if domain looks like a registry (has dot or colon or is localhost)
    if "." not in domain and ":" not in domain and domain != "localhost":
        return f"docker.io/{image}"

    return image

def _extract_recursive(data: Any, images: Set[str]) -> None:
    """
    Recursively search for 'image' keys in a dictionary or list structure.

    Args:
        data: The dictionary or list to search.
        images: Set to collect found images in.
    """
    if isinstance(data, dict):
        for key, value in data.items():
            if key == "image" and isinstance(value, str):
                cleaned = _clean_image(value)
                if cleaned:
                    images.add(cleaned)
            else:
                _extract_recursive(value, images)
    elif isinstance(data, list):
        for item in data:
            _extract_recursive(item, images)

def extract_images_from_manifests(manifests_str: str) -> Set[str]:
    """
    Parse YAML manifests string and extract all valid image references.

    Args:
        manifests_str: String containing multi-document YAML.

    Returns:
        Set of unique, normalized image strings.
    """
    images: Set[str] = set()
    try:
        documents = yaml.safe_load_all(manifests_str)
        for doc in documents:
            if not doc:
                continue

            # Skip CRDs as they often contain "image" in descriptions/schema validation
            # which are not actual container images used at runtime.
            if doc.get("kind") == "CustomResourceDefinition":
                continue

            # Recursive search for "image" keys in the document structure
            _extract_recursive(doc, images)

    except yaml.YAMLError as e:
        logger.warning(f"Failed to parse YAML manifest: {e}")

    return images

def main() -> None:
    parser = argparse.ArgumentParser(description="Extract container images from Kustomize overlays.")
    parser.add_argument("search_dir", help="Root directory to search for kustomization files")
    parser.add_argument("output_file", help="Path to write the output JSON file")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose logging")

    args = parser.parse_args()

    if args.verbose:
        logger.setLevel(logging.DEBUG)

    logger.info(f"Searching for kustomizations in {args.search_dir}...")
    kustomize_files = find_kustomizations(args.search_dir)

    if not kustomize_files:
        logger.warning("No kustomization files found.")
        with open(args.output_file, "w") as f:
            json.dump([], f)
        return

    all_images: Set[str] = set()
    for kfile in kustomize_files:
        logger.debug(f"Processing {kfile}...")
        manifest_output = run_kustomize(kfile)
        if manifest_output:
            images = extract_images_from_manifests(manifest_output)
            all_images.update(images)

    # Sort consistency
    sorted_images = sorted(list(all_images))
    logger.info(f"Found {len(sorted_images)} unique images.")
    logger.info(f"Writing output to {args.output_file}")

    with open(args.output_file, "w") as f:
        json.dump(sorted_images, f, indent=2)

if __name__ == "__main__":
    main()
