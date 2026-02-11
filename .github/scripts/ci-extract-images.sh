#!/usr/bin/env bash

# This script finds all container images in the Kubernetes manifests
# by building the kustomization overlays.

set -euo pipefail

# Directory containing the overlays (e.g., kubernetes/applications)
SEARCH_DIR="${1:-kubernetes}"
OUTPUT_FILE="${2:-images.json}"

echo "Gathering images from $SEARCH_DIR..." >&2

# Find all kustomization.yaml files in overlays
# We include both 'prod' and 'dev' to ensure all environment images are captured
MAP_FILES=$(find "$SEARCH_DIR" -type f -name "kustomization.yaml" | grep "overlays/")

IMAGES=()

for kfile in $MAP_FILES; do
    dir=$(dirname "$kfile")
    # Build the manifests
    if ! manifest=$(kustomize build --enable-helm "$dir" 2>/dev/null); then
        echo "Warning: Failed to build $dir" >&2
        continue
    fi

    # Extract images using yq (assuming v4)
    # It looks for .image in containers, initContainers, etc.
    extracted=$(echo "$manifest" | yq eval-all '.. | select(has("image")) | .image' - | sed '/^---$/d' | sed '/^$/d')

    if [ -n "$extracted" ]; then
        while read -r img; do
            IMAGES+=("$img")
        done <<< "$extracted"
    fi
done

# Deduplicate and format as JSON array
# shellcheck disable=SC2207
UNIQUE_IMAGES=($(printf "%s\n" "${IMAGES[@]}" | sort -u))

# Build JSON array using jq
printf "%s\n" "${UNIQUE_IMAGES[@]}" | jq -R . | jq -s -c . > "$OUTPUT_FILE"

echo "Found ${#UNIQUE_IMAGES[@]} unique images. Saved to $OUTPUT_FILE" >&2
