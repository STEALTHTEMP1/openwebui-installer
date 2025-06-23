#!/bin/bash

# Branches to skip (problematic ones)
SKIP_BRANCHES=(
    "codex/new-task"
    "codex/find-and-fix-a-bug-in-the-codebase" 
    "codex/investigate-empty-openwebui-installer-folder"
    "codex/delete-.ds_store-from-repository"  # Keep only one .DS_Store cleanup
    "codex/remove-tracked-.ds_store-and-.snapshots"  # Keep only one .DS_Store cleanup
    "n5pgtt-codex/refactor-install.py-and-update-documentation"  # Duplicate refactor
    "u216g9-codex/refactor-install.py-and-update-documentation"  # Duplicate refactor
    "codex/remove-multi-platform-claims-and-update-docs"  # Conflicts with cross-platform
    "p8x3s6-codex/refactor-settext-to-use-joined-string"  # Duplicate refactor
)

# Get all codex branches
ALL_BRANCHES=$(git branch -r | grep "origin/.*codex" | sed 's/origin\///' | tr -d ' ')

echo "🚀 Starting smart merge of codex branches..."
echo "📊 Total branches found: $(echo "$ALL_BRANCHES" | wc -l)"

MERGED=0
SKIPPED=0
FAILED=0

for branch in $ALL_BRANCHES; do
    # Check if branch should be skipped
    SKIP=false
    for skip_branch in "${SKIP_BRANCHES[@]}"; do
        if [[ "$branch" == *"$skip_branch"* ]]; then
            echo "⏭️  Skipping: $branch (problematic)"
            SKIP=true
            ((SKIPPED++))
            break
        fi
    done
    
    if [ "$SKIP" = true ]; then
        continue
    fi
    
    # Check if already merged
    if git merge-base --is-ancestor "origin/$branch" HEAD; then
        echo "✅ Already merged: $branch"
        ((MERGED++))
        continue
    fi
    
    echo "🔄 Merging: $branch"
    
    # Attempt merge
    if git merge "origin/$branch" --no-edit -m "Merge $branch"; then
        echo "✅ Success: $branch"
        ((MERGED++))
    else
        echo "❌ Failed: $branch (conflicts)"
        git merge --abort 2>/dev/null
        ((FAILED++))
    fi
done

echo ""
echo "📊 Merge Summary:"
echo "   ✅ Merged: $MERGED"
echo "   ⏭️  Skipped: $SKIPPED" 
echo "   ❌ Failed: $FAILED"
echo ""

if [ $FAILED -gt 0 ]; then
    echo "⚠️  Some branches failed to merge due to conflicts."
    echo "   You can manually resolve these later if needed."
fi

echo "🎉 Smart merge complete!"
