#!/usr/bin/env bash
#
# Script to replace all release-service-utils image references with a custom image
# Usage: ./scripts/replace-utils-image.sh <new-image>
# Example: ./scripts/replace-utils-image.sh quay.io/myuser/release-service-utils:pr-123
#

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <new-image>"
    echo "Example: $0 quay.io/myuser/release-service-utils:pr-123"
    exit 1
fi

NEW_IMAGE="$1"

# Validate that the image looks reasonable
if [[ ! "$NEW_IMAGE" =~ ^[a-zA-Z0-9._/-]+:[a-zA-Z0-9._-]+$ ]]; then
    echo "Error: Image '$NEW_IMAGE' doesn't look like a valid image reference (should be registry/image:tag)"
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "Replacing release-service-utils images with: $NEW_IMAGE"
echo "Searching in: $REPO_ROOT/tasks"
echo ""

# Find all yaml files in tasks/internal and tasks/managed
# Replace any line with "image: quay.io/.../release-service-utils:..." 
MODIFIED_COUNT=0

while IFS= read -r file; do
    # Check if file contains release-service-utils image references
    if grep -q "release-service-utils:" "$file"; then
        # Count how many lines match before replacement
        BEFORE=$(grep -c "release-service-utils:" "$file" || true)
        
        # Replace all release-service-utils image references
        # Handle both formats:
        # 1. image: quay.io/.../release-service-utils:tag
        sed -i -E "s|image: *quay\.io/[^/]+/release-service-utils:[^ ]*|image: $NEW_IMAGE|g" "$file"
        # 2. image:\n        quay.io/.../release-service-utils:tag (on separate line with indentation)
        sed -i -E "s|^( *)quay\.io/[^/]+/release-service-utils:[^ ]*|\1$NEW_IMAGE|g" "$file"
        
        # Count after to verify
        AFTER=$(grep -c "$NEW_IMAGE" "$file" || true)
        
        echo "✓ $file ($BEFORE references replaced)"
        MODIFIED_COUNT=$((MODIFIED_COUNT + 1))
    fi
done < <(find "$REPO_ROOT/tasks/internal" "$REPO_ROOT/tasks/managed" -name "*.yaml" -type f 2>/dev/null)

echo ""
echo "========================================"
echo "Summary: Modified $MODIFIED_COUNT files"
echo "New image: $NEW_IMAGE"
echo "========================================"
echo ""
echo "To revert changes: git restore tasks/"

