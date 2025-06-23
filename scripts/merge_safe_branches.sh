#!/bin/bash

# Merge Safe Branches Script
# Merges branches that are safe to merge (no conflicts, formatting/newlines)

set -euo pipefail

echo "🚀 Merging Safe Branches - OpenWebUI Installer"
echo "=============================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Safe branches to merge (from systematic review)
SAFE_BRANCHES=(
    "codex/add-trailing-newline-to-files"
    "codex/add-trailing-newline-to-multiple-files"
    "codex/format-python-files-with-black-and-isort"
    "codex/run-isort-and-black-on-openwebui_installer-and-tests"
)

# Check we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
    echo "🔄 Switching to main branch..."
    git checkout main || {
        echo -e "${RED}❌ Cannot switch to main branch${NC}"
        exit 1
    }
fi

# Update remote references
echo "🔄 Updating remote references..."
git remote update origin --prune 2>/dev/null || echo "Note: Remote update failed"

# Create backup branch
BACKUP_BRANCH="backup-safe-merge-$(date +%Y%m%d_%H%M%S)"
echo "💾 Creating backup branch: $BACKUP_BRANCH"
git checkout -b "$BACKUP_BRANCH" 2>/dev/null || echo "Note: Backup branch creation failed"
git checkout main

echo ""
echo "🔍 About to merge ${#SAFE_BRANCHES[@]} safe branches:"
for branch in "${SAFE_BRANCHES[@]}"; do
    echo "  • $branch"
done

echo ""
read -p "Continue with merge? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Merge cancelled"
    exit 1
fi

MERGED_COUNT=0
FAILED_COUNT=0
FAILED_BRANCHES=()

echo ""
echo "🚀 Starting merge process..."

for branch in "${SAFE_BRANCHES[@]}"; do
    echo ""
    echo -e "${YELLOW}🔄 Processing: $branch${NC}"

    # Check if branch exists
    if ! git show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null; then
        echo -e "${RED}❌ Branch not found: $branch${NC}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_BRANCHES+=("$branch (not found)")
        continue
    fi

    # Check if already merged
    if git merge-base --is-ancestor "origin/$branch" HEAD 2>/dev/null; then
        echo -e "${GREEN}✅ Already merged: $branch${NC}"
        MERGED_COUNT=$((MERGED_COUNT + 1))
        continue
    fi

    # Show what will be merged
    echo "📋 Changes to be merged:"
    git log --oneline "main..origin/$branch" | head -3
    git diff --stat "main...origin/$branch"

    # Attempt merge
    echo "🔄 Merging..."
    if git merge "origin/$branch" --no-edit -m "Safe merge: $branch

- Contains formatting/newline fixes
- No conflicts detected
- Automated merge from safe branch review" 2>/dev/null; then
        echo -e "${GREEN}✅ Successfully merged: $branch${NC}"
        MERGED_COUNT=$((MERGED_COUNT + 1))

        # Run basic validation
        if python3 -m py_compile openwebui_installer/*.py 2>/dev/null; then
            echo "  ✅ Python syntax validation passed"
        else
            echo "  ⚠️  Python syntax validation failed"
        fi
    else
        echo -e "${RED}❌ Failed to merge: $branch${NC}"
        git merge --abort 2>/dev/null || true
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_BRANCHES+=("$branch")
    fi
done

# Summary
echo ""
echo "📊 Merge Summary:"
echo "================="
echo -e "✅ Successfully merged: ${GREEN}$MERGED_COUNT${NC}"
echo -e "❌ Failed merges: ${RED}$FAILED_COUNT${NC}"

if [[ ${#FAILED_BRANCHES[@]} -gt 0 ]]; then
    echo ""
    echo "Failed branches:"
    for branch in "${FAILED_BRANCHES[@]}"; do
        echo "  - $branch"
    done
fi

echo ""
echo -e "${BLUE}💾 Backup available at: $BACKUP_BRANCH${NC}"

# Show final status
echo ""
echo "📈 Repository status:"
git log --oneline -5

if [[ $MERGED_COUNT -gt 0 ]]; then
    echo ""
    echo -e "${GREEN}🎉 Safe merge phase complete!${NC}"
    echo "Next steps:"
    echo "1. Test the merged changes"
    echo "2. Run the validation script"
    echo "3. Review high-priority branches"
    echo "4. Push changes to remote"
    echo ""
    echo "Commands to run:"
    echo "  git log --oneline -10  # Review recent commits"
    echo "  ./scripts/post_merge_validation.sh  # Validate changes"
    echo "  git push origin main  # Push to remote"
else
    echo ""
    echo -e "${YELLOW}ℹ️  No branches were merged.${NC}"
fi
