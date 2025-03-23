#!/usr/bin/env bash
set -euo pipefail

# Get script directory
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DEPLOYMENT_DIR="$SCRIPT_DIR/../deployment"

# Files and directories to delete
FILES_TO_DELETE=(
    "state.json"
    ".terraform.lock.hcl"
    "terraform.tfstate.backup"
    "terraform.tfstate"
)

DIRS_TO_DELETE=(
    ".terraform/"
)

# Check if the deployment directory exists
if [ ! -d "$DEPLOYMENT_DIR" ]; then
    echo "Deployment directory not found: $DEPLOYMENT_DIR"
    exit 1
fi

# Delete files
for file in "${FILES_TO_DELETE[@]}"; do
    file_path="$DEPLOYMENT_DIR/$file"
    if [ -f "$file_path" ]; then
        echo "Deleting file: $file_path"
        rm -f "$file_path"
    else
        echo "File not found, skipping: $file_path"
    fi
done

# Delete directories
for dir in "${DIRS_TO_DELETE[@]}"; do
    dir_path="$DEPLOYMENT_DIR/$dir"
    if [ -d "$dir_path" ]; then
        echo "Deleting directory: $dir_path"
        rm -rf "$dir_path"
    else
        echo "Directory not found, skipping: $dir_path"
    fi
done

echo "Terraform deployment cleanup completed!"