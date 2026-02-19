#!/bin/bash
set -euo pipefail

# Default values
SOURCE_ROOT="."
DEST_ROOT="dist"
ENVIRONMENTS="dev prod"

# Usage help
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --source <path>   Source root directory containing kubernetes/ (default: .)"
    echo "  --dest <path>     Destination directory for hydrated manifests (default: dist)"
    echo "  --envs <list>     Space-separated list of environments to hydrate (default: 'dev prod')"
    echo "  --help            Show this help message"
    exit 1
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --source) SOURCE_ROOT="$2"; shift ;;
        --dest) DEST_ROOT="$2"; shift ;;
        --envs) ENVIRONMENTS="$2"; shift ;;
        --help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

echo "🔧 Hydrating manifests..."
echo "  Source: $SOURCE_ROOT"
echo "  Dest:   $DEST_ROOT"
echo "  Envs:   $ENVIRONMENTS"

mkdir -p "$DEST_ROOT"

hydrate() {
    local type=$1
    local path=$2
    # path is: <source_root>/kubernetes/applications/<name>/overlays/<env>
    local env=$(basename "$path")
    local name=$(basename "$(dirname "$(dirname "$path")")")

    echo "::group::Hydrating $name ($env)"

    # Destination path: <dest_root>/<env>/<type>/<name>/manifest.yaml
    local dest_dir="$DEST_ROOT/$env/$type/$name"

    # Clean output directory
    rm -rf "$dest_dir"
    mkdir -p "$dest_dir"

    if kustomize build --enable-helm "$path" > "$dest_dir/manifest.yaml"; then
        echo "✅ Hydrated $type/$name ($env)"
    else
        echo "::error::Failed to hydrate $name ($env)"
        exit 1
    fi
    echo "::endgroup::"
}

# Iterate over categories (applications, components)
for category in applications components; do
    base_dir="$SOURCE_ROOT/kubernetes/$category"

    if [ -d "$base_dir" ]; then
        for app_dir in "$base_dir"/*; do
            if [ -d "$app_dir" ]; then
                for env in $ENVIRONMENTS; do
                    overlay_path="$app_dir/overlays/$env"
                    if [ -d "$overlay_path" ]; then
                        hydrate "$category" "$overlay_path"
                    fi
                done
            fi
        done
    fi
done

echo "✨ Hydration complete!"
