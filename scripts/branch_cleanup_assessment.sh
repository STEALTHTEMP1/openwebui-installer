#!/bin/bash

# Comprehensive Branch Cleanup and Assessment Script
# Identifies merged branches, suggests cleanup, and provides maintenance recommendations

set -euo pipefail

echo "🔍 Branch Cleanup Assessment - OpenWebUI Installer"
echo "=================================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
ASSESSMENT_DIR=".branch-analysis/cleanup-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ASSESSMENT_DIR"

REPORT_FILE="$ASSESSMENT_DIR/branch_cleanup_report.md"
MERGED_BRANCHES_FILE="$ASSESSMENT_DIR/merged_branches.txt"
SAFE_TO_DELETE_FILE="$ASSESSMENT_DIR/safe_to_delete.txt"
ACTIVE_BRANCHES_FILE="$ASSESSMENT_DIR/active_branches.txt"
CLEANUP_SCRIPT="$ASSESSMENT_DIR/cleanup_merged_branches.sh"

# Initialize report
cat > "$REPORT_FILE" << EOF
# Branch Cleanup Assessment Report

**Generated**: $(date)
**Repository**: OpenWebUI Installer
**Current Branch**: $(git branch --show-current)
**Last Commit**: $(git log -1 --format="%h - %s (%an, %ar)")

## Executive Summary

EOF

echo "📊 Analyzing branch status..."

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
MAIN_BRANCH="main"

# Check if main branch exists, fallback to master
if ! git show-ref --verify --quiet refs/heads/main; then
    if git show-ref --verify --quiet refs/heads/master; then
        MAIN_BRANCH="master"
    else
        echo -e "${RED}❌ Neither 'main' nor 'master' branch found${NC}"
        exit 1
    fi
fi

echo "🎯 Using '$MAIN_BRANCH' as base branch"

# Ensure we're on the main branch for analysis
if [[ "$CURRENT_BRANCH" != "$MAIN_BRANCH" ]]; then
    echo "🔄 Switching to $MAIN_BRANCH for analysis..."
    git checkout "$MAIN_BRANCH" 2>/dev/null || {
        echo -e "${RED}❌ Cannot switch to $MAIN_BRANCH${NC}"
        exit 1
    }
fi

# Update remote references
echo "🔄 Updating remote references..."
git remote update origin --prune 2>/dev/null || echo "Note: Remote update failed"

# Get all branches
echo "📋 Collecting branch information..."
ALL_REMOTE_BRANCHES=$(git branch -r | grep -v HEAD | sed 's/origin\///' | sed 's/^[[:space:]]*//' | sort)
ALL_LOCAL_BRANCHES=$(git branch | sed 's/^[[:space:]]*//' | sed 's/^\*//' | sed 's/^[[:space:]]*//' | sort)

# Arrays for categorization
MERGED_BRANCHES=()
UNMERGED_BRANCHES=()
ACTIVE_BRANCHES=()
CODEX_BRANCHES=()
DEPENDABOT_BRANCHES=()
FEATURE_BRANCHES=()
STALE_BRANCHES=()

# Analyze each remote branch
echo "🔍 Analyzing remote branches..."
while IFS= read -r branch; do
    [[ -z "$branch" ]] && continue

    # Skip main/master branches
    if [[ "$branch" == "$MAIN_BRANCH" || "$branch" == "main" || "$branch" == "master" ]]; then
        continue
    fi

    # Check if branch exists remotely
    if ! git show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null; then
        echo "⚠️  Branch not found remotely: $branch"
        continue
    fi

    # Categorize by naming convention
    if [[ "$branch" =~ ^codex/ ]]; then
        CODEX_BRANCHES+=("$branch")
    elif [[ "$branch" =~ ^dependabot/ ]]; then
        DEPENDABOT_BRANCHES+=("$branch")
    elif [[ "$branch" =~ ^[a-z0-9]+-codex/ ]]; then
        CODEX_BRANCHES+=("$branch")  # Include user-prefixed codex branches
    else
        FEATURE_BRANCHES+=("$branch")
    fi

    # Check if branch is merged
    if git merge-base --is-ancestor "origin/$branch" HEAD 2>/dev/null; then
        MERGED_BRANCHES+=("$branch")
        echo "✅ Merged: $branch"
    else
        UNMERGED_BRANCHES+=("$branch")

        # Check if branch is stale (no commits in last 30 days)
        LAST_COMMIT_DATE=$(git log -1 --format="%ct" "origin/$branch" 2>/dev/null || echo "0")
        THIRTY_DAYS_AGO=$(($(date +%s) - 30*24*3600))

        if [[ "$LAST_COMMIT_DATE" -lt "$THIRTY_DAYS_AGO" ]]; then
            STALE_BRANCHES+=("$branch")
            echo "🕐 Stale: $branch"
        else
            ACTIVE_BRANCHES+=("$branch")
            echo "🔄 Active: $branch"
        fi
    fi
done <<< "$ALL_REMOTE_BRANCHES"

# Generate statistics
TOTAL_BRANCHES=$(echo "$ALL_REMOTE_BRANCHES" | wc -l)
MERGED_COUNT=${#MERGED_BRANCHES[@]}
UNMERGED_COUNT=${#UNMERGED_BRANCHES[@]}
ACTIVE_COUNT=${#ACTIVE_BRANCHES[@]}
STALE_COUNT=${#STALE_BRANCHES[@]}
CODEX_COUNT=${#CODEX_BRANCHES[@]}
DEPENDABOT_COUNT=${#DEPENDABOT_BRANCHES[@]}
FEATURE_COUNT=${#FEATURE_BRANCHES[@]}

# Write merged branches to file
if [[ ${#MERGED_BRANCHES[@]} -gt 0 ]]; then
    printf '%s\n' "${MERGED_BRANCHES[@]}" > "$MERGED_BRANCHES_FILE"
else
    echo "# No merged branches found" > "$MERGED_BRANCHES_FILE"
fi

# Write active branches to file
if [[ ${#ACTIVE_BRANCHES[@]} -gt 0 ]]; then
    printf '%s\n' "${ACTIVE_BRANCHES[@]}" > "$ACTIVE_BRANCHES_FILE"
else
    echo "# No active branches found" > "$ACTIVE_BRANCHES_FILE"
fi

# Determine safe to delete branches
SAFE_TO_DELETE=()
if [[ ${#MERGED_BRANCHES[@]} -gt 0 ]]; then
    for branch in "${MERGED_BRANCHES[@]}"; do
        # Additional safety checks
        if [[ "$branch" =~ ^codex/ ]] || [[ "$branch" =~ ^[a-z0-9]+-codex/ ]]; then
            # Codex branches are typically safe to delete after merge
            SAFE_TO_DELETE+=("$branch")
        elif [[ "$branch" =~ ^dependabot/ ]]; then
            # Dependabot branches are safe to delete after merge
            SAFE_TO_DELETE+=("$branch")
        elif [[ "$branch" =~ ^(feature|bugfix|hotfix)/ ]]; then
            # Standard feature branches are safe to delete after merge
            SAFE_TO_DELETE+=("$branch")
        fi
    done
fi

if [[ ${#SAFE_TO_DELETE[@]} -gt 0 ]]; then
    printf '%s\n' "${SAFE_TO_DELETE[@]}" > "$SAFE_TO_DELETE_FILE"
else
    echo "# No branches safe to delete found" > "$SAFE_TO_DELETE_FILE"
fi

# Generate cleanup script
cat > "$CLEANUP_SCRIPT" << 'EOF'
#!/bin/bash

# Automated Branch Cleanup Script
# Generated by branch_cleanup_assessment.sh

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "🧹 Branch Cleanup - OpenWebUI Installer"
echo "========================================"

# Safety check
read -p "⚠️  This will DELETE merged branches. Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

# Create backup
BACKUP_DIR=".branch-analysis/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "💾 Creating backup of branch information..."
git branch -r > "$BACKUP_DIR/remote_branches.txt"
git branch > "$BACKUP_DIR/local_branches.txt"

DELETED_COUNT=0
FAILED_COUNT=0
FAILED_BRANCHES=()

EOF

# Add branches to cleanup script
echo "# Branches to delete (merged and safe)" >> "$CLEANUP_SCRIPT"
echo "BRANCHES_TO_DELETE=(" >> "$CLEANUP_SCRIPT"
if [[ ${#SAFE_TO_DELETE[@]} -gt 0 ]]; then
    for branch in "${SAFE_TO_DELETE[@]}"; do
        echo "    \"$branch\"" >> "$CLEANUP_SCRIPT"
    done
fi
echo ")" >> "$CLEANUP_SCRIPT"

cat >> "$CLEANUP_SCRIPT" << 'EOF'

if [[ ${#BRANCHES_TO_DELETE[@]} -eq 0 ]]; then
    echo "ℹ️  No branches to delete - all branches are either unmerged or not safe to delete"
    echo ""
    echo -e "${BLUE}💾 Backup saved to: $BACKUP_DIR${NC}"
    echo -e "${YELLOW}🎉 No cleanup needed!${NC}"
    exit 0
fi

echo "🗑️  Deleting merged branches..."
for branch in "${BRANCHES_TO_DELETE[@]}"; do
    echo "Deleting: $branch"

    # Delete remote branch
    if git push origin --delete "$branch" 2>/dev/null; then
        echo -e "${GREEN}✅ Deleted remote: $branch${NC}"
        DELETED_COUNT=$((DELETED_COUNT + 1))
    else
        echo -e "${RED}❌ Failed to delete remote: $branch${NC}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_BRANCHES+=("$branch")
    fi

    # Delete local branch if it exists
    if git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
        if git branch -D "$branch" 2>/dev/null; then
            echo -e "${GREEN}✅ Deleted local: $branch${NC}"
        else
            echo -e "${YELLOW}⚠️  Could not delete local: $branch${NC}"
        fi
    fi
done

echo ""
echo "📊 Cleanup Summary:"
echo "=================="
echo -e "✅ Successfully deleted: ${GREEN}$DELETED_COUNT${NC}"
echo -e "❌ Failed to delete: ${RED}$FAILED_COUNT${NC}"

if [[ ${#FAILED_BRANCHES[@]} -gt 0 ]]; then
    echo ""
    echo "Failed branches:"
    for branch in "${FAILED_BRANCHES[@]}"; do
        echo "  - $branch"
    done
fi

echo ""
echo -e "${BLUE}💾 Backup saved to: $BACKUP_DIR${NC}"
echo -e "${GREEN}🎉 Branch cleanup complete!${NC}"
EOF

chmod +x "$CLEANUP_SCRIPT"

# Update report with detailed analysis
cat >> "$REPORT_FILE" << EOF
**Total Branches Analyzed**: $TOTAL_BRANCHES
**Merged Branches**: $MERGED_COUNT ($(( TOTAL_BRANCHES > 0 ? MERGED_COUNT * 100 / TOTAL_BRANCHES : 0 ))%)
**Unmerged Branches**: $UNMERGED_COUNT ($(( TOTAL_BRANCHES > 0 ? UNMERGED_COUNT * 100 / TOTAL_BRANCHES : 0 ))%)
**Active Branches**: $ACTIVE_COUNT
**Stale Branches**: $STALE_COUNT
**Safe to Delete**: ${#SAFE_TO_DELETE[@]}

## Branch Categories

### By Type
- **Codex Branches**: $CODEX_COUNT
- **Dependabot Branches**: $DEPENDABOT_COUNT
- **Feature Branches**: $FEATURE_COUNT

### By Status
- **Merged & Safe to Delete**: ${#SAFE_TO_DELETE[@]}
- **Active (recent commits)**: $ACTIVE_COUNT
- **Stale (>30 days old)**: $STALE_COUNT

## Recommendations

### ✅ Immediate Actions
1. **Delete Merged Branches**: Run the generated cleanup script to remove ${#SAFE_TO_DELETE[@]} merged branches
2. **Review Stale Branches**: Consider closing $STALE_COUNT stale branches
3. **Establish Branch Policies**: Implement automatic cleanup for merged branches

### 🔄 Ongoing Maintenance
1. **Weekly Cleanup**: Run branch cleanup weekly
2. **Auto-delete**: Configure GitHub to auto-delete merged branches
3. **Branch Naming**: Enforce consistent naming conventions
4. **Stale Branch Alerts**: Set up alerts for branches >30 days old

## Generated Files

- **Merged Branches**: \`$MERGED_BRANCHES_FILE\`
- **Active Branches**: \`$ACTIVE_BRANCHES_FILE\`
- **Safe to Delete**: \`$SAFE_TO_DELETE_FILE\`
- **Cleanup Script**: \`$CLEANUP_SCRIPT\`

## Next Steps

1. Review the lists above
2. Run: \`$CLEANUP_SCRIPT\`
3. Configure GitHub branch protection rules
4. Set up automated cleanup workflows

EOF

# Console output summary
echo ""
echo "📊 Assessment Complete!"
echo "======================="
echo -e "📈 Total branches analyzed: ${BLUE}$TOTAL_BRANCHES${NC}"
echo -e "✅ Merged branches: ${GREEN}$MERGED_COUNT${NC}"
echo -e "🔄 Unmerged branches: ${YELLOW}$UNMERGED_COUNT${NC}"
echo -e "🗑️  Safe to delete: ${RED}${#SAFE_TO_DELETE[@]}${NC}"
echo ""

if [[ ${#SAFE_TO_DELETE[@]} -gt 0 ]]; then
    echo -e "${GREEN}🎯 Ready for cleanup!${NC}"
    echo "To delete merged branches, run:"
    echo -e "${CYAN}$CLEANUP_SCRIPT${NC}"
else
    echo -e "${YELLOW}ℹ️  No branches safe to delete found${NC}"
fi

echo ""
echo "📄 Detailed analysis:"
echo -e "${PURPLE}$REPORT_FILE${NC}"
echo ""
echo "🔧 Branch management best practices:"
echo "1. Delete merged branches immediately after merging"
echo "2. Use consistent naming conventions (feature/, bugfix/, etc.)"
echo "3. Configure GitHub to auto-delete merged branches"
echo "4. Review stale branches monthly"
echo "5. Set up branch protection rules"
