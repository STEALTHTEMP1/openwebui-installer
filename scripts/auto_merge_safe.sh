#!/bin/bash

# Auto-merge safe branches with no conflicts
# Uses the analysis from enhanced_branch_analyzer.sh

set -euo pipefail

echo "🤖 Auto-Merge Safe Branches"
echo "============================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if analysis exists
if [[ ! -f ".branch-analysis/merge_candidates.txt" ]]; then
    echo -e "${RED}❌ No analysis found. Run enhanced_branch_analyzer.sh first.${NC}"
    exit 1
fi

# Create backup branch
BACKUP_BRANCH="backup-before-auto-merge-$(date +%Y%m%d_%H%M%S)"
echo "🔒 Creating backup branch: $BACKUP_BRANCH"
git checkout -b "$BACKUP_BRANCH" 2>/dev/null || echo "Note: Already on a branch"
git checkout main 2>/dev/null || git checkout master 2>/dev/null || echo "Warning: Neither main nor master branch found"

echo ""

# Read safe merge candidates
SAFE_BRANCHES=()
while IFS= read -r line; do
    if [[ "$line" =~ ^[^#] && -n "$line" ]]; then
        SAFE_BRANCHES+=("$line")
    fi
done < ".branch-analysis/merge_candidates.txt"

echo "📋 Found ${#SAFE_BRANCHES[@]} safe merge candidates"
echo ""

MERGED_COUNT=0
FAILED_COUNT=0
FAILED_BRANCHES=()

for branch in "${SAFE_BRANCHES[@]}"; do
    echo -e "${YELLOW}🔄 Merging: $branch${NC}"

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

    # Attempt merge
    if git merge "origin/$branch" --no-edit -m "Auto-merge safe branch: $branch" 2>/dev/null; then
        echo -e "${GREEN}✅ Successfully merged: $branch${NC}"
        MERGED_COUNT=$((MERGED_COUNT + 1))
    else
        echo -e "${RED}❌ Failed to merge: $branch${NC}"
        git merge --abort 2>/dev/null || true
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_BRANCHES+=("$branch")
    fi
    echo ""
done

# Summary
echo "📊 Auto-Merge Summary:"
echo "======================"
echo -e "✅ Successfully merged: ${GREEN}$MERGED_COUNT${NC}"
echo -e "❌ Failed merges: ${RED}$FAILED_COUNT${NC}"

if [[ ${#FAILED_BRANCHES[@]} -gt 0 ]]; then
    echo ""
    echo "Failed branches (need manual review):"
    for branch in "${FAILED_BRANCHES[@]}"; do
        echo "  - $branch"
    done

    # Write failed branches to file for manual processing
    echo "# Failed auto-merge branches" > ".branch-analysis/failed_auto_merge.txt"
    for branch in "${FAILED_BRANCHES[@]}"; do
        echo "$branch" >> ".branch-analysis/failed_auto_merge.txt"
    done
    echo ""
    echo -e "${YELLOW}📝 Failed branches written to: .branch-analysis/failed_auto_merge.txt${NC}"
fi

echo ""
if [[ $MERGED_COUNT -gt 0 ]]; then
    echo -e "${GREEN}🎉 Auto-merge phase complete!${NC}"
    echo "Next: Run merge_critical_branches.sh for high-priority merges"
else
    echo -e "${YELLOW}ℹ️  No branches were auto-merged.${NC}"
    echo "This may indicate that all branches require manual attention."
fi

echo ""
echo -e "${BLUE}💾 Backup available at: $BACKUP_BRANCH${NC}"
