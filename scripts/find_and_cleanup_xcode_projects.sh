#!/bin/bash
# Find and optionally remove 'abandoned' Xcode project and workspace directories.

set -euo pipefail

ROOT_DIR="."
DAYS_INACTIVE=${1:-90}
DRY_RUN=${DRY_RUN:-1}
MIN_DEPTH=1
MAX_DEPTH=6

echo "🔍 Searching for Xcode projects/workspaces NOT modified in the last $DAYS_INACTIVE days..."

# Find .xcodeproj and .xcworkspace directories, print last modification time, and filter by age.
find "$ROOT_DIR" -type d \( -name "*.xcodeproj" -o -name "*.xcworkspace" \) -mindepth $MIN_DEPTH -maxdepth $MAX_DEPTH | while read -r folder; do
    # Get most recent file modification time inside the folder.
    last_mod_unix=$(find "$folder" -type f -print0 | xargs -0 stat -f "%m" 2>/dev/null | sort -n | tail -1)
    folder_name="$folder"
    if [[ -z "$last_mod_unix" ]]; then
        last_mod_unix=$(stat -f "%m" "$folder" 2>/dev/null || echo 0)
    fi
    age_days=$(( ( $(date +%s) - ${last_mod_unix:-0} ) / 86400 ))
    if [[ $age_days -ge $DAYS_INACTIVE ]]; then
        echo "🚨 $folder_name (inactive for $age_days days)"
        echo "$folder_name" >> /tmp/abandoned_xcode_folders.txt
    fi
done

if [[ ! -f /tmp/abandoned_xcode_folders.txt || ! -s /tmp/abandoned_xcode_folders.txt ]]; then
    echo "✅ No abandoned Xcode project/workspace folders found."
    rm -f /tmp/abandoned_xcode_folders.txt
    exit 0
fi

echo ""
echo "The following Xcode folders have not been modified in $DAYS_INACTIVE+ days:"
cat /tmp/abandoned_xcode_folders.txt

if [[ "$DRY_RUN" == "1" ]]; then
    echo ""
    echo "💡 DRY RUN ONLY (default): No folders will be deleted."
    echo "    To remove, re-run this script with DRY_RUN=0, e.g.:"
    echo "    DRY_RUN=0 $0 $DAYS_INACTIVE"
    rm /tmp/abandoned_xcode_folders.txt
    exit 0
fi

echo ""
read -p "❗ Proceed to DELETE these folders? This cannot be undone. (y/N): " yn
if [[ $yn =~ ^[Yy]$ ]]; then
    while read -r folder; do
        echo "🗑️  Deleting $folder"
        rm -rf "$folder"
    done < /tmp/abandoned_xcode_folders.txt
    echo "✅ Abandoned Xcode folders deleted."
else
    echo "❌ Deletion canceled."
fi

rm -f /tmp/abandoned_xcode_folders.txt
