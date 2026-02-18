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

# Create a temporary file for collecting images to avoid shell array limit/splitting issues
TEMP_IMAGES=$(mktemp)

for kfile in $MAP_FILES; do
    dir=$(dirname "$kfile")
    # Build the manifests
    if ! manifest=$(kustomize build --enable-helm "$dir" 2>/dev/null); then
        echo "Warning: Failed to build $dir" >&2
        continue
    fi

    # Extract images using yq
    # 1. Select only documents that are NOT CustomResourceDefinitions (avoids schema descriptions)
    # 2. Recursive descent to find 'image' keys
    # 3. Ensure the value is a string (avoids objects/arrays)
    # 4. Filter out common garbage (empty, simple dash, values with spaces which are likely docs)
    echo "$manifest" | yq eval-all 'select(.kind != "CustomResourceDefinition") | .. | select(has("image")) | .image | select(tag == "!!str")' - \
        | grep -v '^---$' \
        | grep -v '^null$' \
        | grep -v ' ' \
        | grep . >> "$TEMP_IMAGES"
done

# Deduplicate and format as JSON array
if [ -s "$TEMP_IMAGES" ]; then
    # Sort, unique, and compile to JSON array
    # jq -R works on raw strings, -s slurps them into an array
    sort -u "$TEMP_IMAGES" | jq -R . | jq -s -c . > "$OUTPUT_FILE"
else
    echo "[]" > "$OUTPUT_FILE"
fi

TOTAL=$(jq length "$OUTPUT_FILE")
echo "Found $TOTAL unique images. Saved to $OUTPUT_FILE" >&2

rm -f "$TEMP_IMAGES"
