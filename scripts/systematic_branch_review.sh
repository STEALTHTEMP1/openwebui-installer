#!/bin/bash

# Systematic Branch Review Script
# Reviews all unmerged branches and provides actionable recommendations

set -euo pipefail

echo "🔍 Systematic Branch Review - OpenWebUI Installer"
echo "================================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
REVIEW_DIR=".branch-analysis/review-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REVIEW_DIR"

REPORT_FILE="$REVIEW_DIR/systematic_review_report.md"
HIGH_PRIORITY_FILE="$REVIEW_DIR/high_priority_branches.txt"
DUPLICATE_FILE="$REVIEW_DIR/duplicate_branches.txt"
OBSOLETE_FILE="$REVIEW_DIR/obsolete_branches.txt"
MERGE_CANDIDATES_FILE="$REVIEW_DIR/ready_to_merge.txt"
NEEDS_REVIEW_FILE="$REVIEW_DIR/needs_manual_review.txt"

# Initialize report
cat > "$REPORT_FILE" << 'EOF'
# Systematic Branch Review Report

**Generated**: $(date)
**Repository**: OpenWebUI Installer
**Reviewer**: Automated Analysis + Manual Review Required

## Executive Summary

This report provides a systematic analysis of all unmerged branches, categorizing them by priority and providing actionable recommendations.

## Review Methodology

1. **Content Analysis**: Examine commits and file changes
2. **Conflict Detection**: Check for merge conflicts with main
3. **Duplicate Detection**: Identify branches with similar purposes
4. **Value Assessment**: Evaluate potential impact and usefulness
5. **Priority Ranking**: Assign priority levels for review

EOF

echo "📊 Starting systematic review..."
echo "Current branch: $(git branch --show-current)"

# Ensure we're on main
git checkout main 2>/dev/null || {
    echo -e "${RED}❌ Cannot switch to main branch${NC}"
    exit 1
}

# Update references
echo "🔄 Updating remote references..."
git remote update origin --prune 2>/dev/null || echo "Note: Remote update failed"

# Get all unmerged branches
echo "📋 Getting unmerged branches..."
UNMERGED_BRANCHES=($(git branch -r | grep -v HEAD | sed 's/origin\///' | sed 's/^[[:space:]]*//' | grep -v "^main$" | grep -v "^master$" | sort))

echo "Found ${#UNMERGED_BRANCHES[@]} branches to review"

# Category arrays
HIGH_PRIORITY=()
DUPLICATES=()
OBSOLETE=()
MERGE_READY=()
NEEDS_REVIEW=()

# Analysis functions
analyze_branch_content() {
    local branch=$1
    local commits=$(git log --oneline "main..origin/$branch" 2>/dev/null | wc -l)
    local files_changed=$(git diff --name-only "main...origin/$branch" 2>/dev/null | wc -l)
    local insertions=$(git diff --stat "main...origin/$branch" 2>/dev/null | tail -1 | grep -o '[0-9]\+ insertion' | cut -d' ' -f1 || echo "0")
    local deletions=$(git diff --stat "main...origin/$branch" 2>/dev/null | tail -1 | grep -o '[0-9]\+ deletion' | cut -d' ' -f1 || echo "0")

    echo "$commits:$files_changed:${insertions:-0}:${deletions:-0}"
}

check_merge_conflicts() {
    local branch=$1
    git merge-tree "$(git merge-base main "origin/$branch")" main "origin/$branch" 2>/dev/null | grep -q "<<<<<<< " && echo "conflicts" || echo "clean"
}

categorize_by_purpose() {
    local branch=$1
    case "$branch" in
        *"format"*|*"black"*|*"isort"*) echo "formatting" ;;
        *"newline"*|*"trailing"*) echo "newlines" ;;
        *"requirements"*|*"dependencies"*) echo "deps" ;;
        *"test"*|*"ci"*|*"workflow"*) echo "ci" ;;
        *"refactor"*) echo "refactor" ;;
        *"cli"*|*"command"*) echo "cli" ;;
        *"gui"*|*"qt"*) echo "gui" ;;
        *"install"*|*"setup"*) echo "installer" ;;
        *"docker"*|*"container"*) echo "container" ;;
        *"linux"*|*"macos"*|*"platform"*) echo "platform" ;;
        *"doc"*|*"readme"*|*"md"*) echo "docs" ;;
        *) echo "other" ;;
    esac
}

# Main analysis loop
echo "🔍 Analyzing branches..."

# Use files instead of associative arrays for compatibility

for branch in "${UNMERGED_BRANCHES[@]}"; do
    echo -e "${CYAN}Analyzing: $branch${NC}"

    # Skip if branch doesn't exist remotely
    if ! git show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null; then
        echo "  ⚠️  Branch not found remotely, skipping"
        continue
    fi

    # Get branch analysis
    analysis=$(analyze_branch_content "$branch")
    conflicts=$(check_merge_conflicts "$branch")
    purpose=$(categorize_by_purpose "$branch")

    # Store analysis in temporary file
    echo "$branch:$analysis:$conflicts:$purpose" >> "$REVIEW_DIR/branch_analysis.tmp"

    # Group by purpose in temporary file
    echo "$purpose:$branch" >> "$REVIEW_DIR/purpose_groups.tmp"

    # Extract metrics
    IFS=':' read -r commits files insertions deletions <<< "$analysis"

    # Categorize branch
    if [[ "$purpose" == "formatting" && "$conflicts" == "clean" && "$commits" -le 5 ]]; then
        MERGE_READY+=("$branch")
        echo "  ✅ Ready to merge (formatting, no conflicts)"
    elif [[ "$purpose" == "newlines" && "$conflicts" == "clean" ]]; then
        MERGE_READY+=("$branch")
        echo "  ✅ Ready to merge (newlines, no conflicts)"
    elif [[ "$purpose" == "deps" && "$branch" =~ dependabot ]]; then
        HIGH_PRIORITY+=("$branch")
        echo "  🔥 High priority (dependency update)"
    elif [[ "$purpose" == "cli" || "$purpose" == "installer" || "$purpose" == "container" ]]; then
        HIGH_PRIORITY+=("$branch")
        echo "  🔥 High priority (core functionality)"
    elif [[ "$conflicts" == "conflicts" ]]; then
        NEEDS_REVIEW+=("$branch")
        echo "  ⚠️  Needs review (merge conflicts)"
    elif [[ "$commits" -gt 20 || "$files" -gt 50 ]]; then
        NEEDS_REVIEW+=("$branch")
        echo "  ⚠️  Needs review (large changes)"
    else
        NEEDS_REVIEW+=("$branch")
        echo "  📋 Needs manual review"
    fi
done

# Detect duplicates by purpose
echo "🔍 Detecting duplicates..."
DUPLICATES=()
if [[ -f "$REVIEW_DIR/purpose_groups.tmp" ]]; then
    # Group branches by purpose and find duplicates
    sort "$REVIEW_DIR/purpose_groups.tmp" | uniq -c | while read count purpose_branch; do
        if [[ $count -gt 1 ]]; then
            purpose=$(echo "$purpose_branch" | cut -d: -f1)
            echo "  📋 Multiple $purpose branches detected"
            # Get all branches for this purpose and add to duplicates (except first)
            grep "^$purpose:" "$REVIEW_DIR/purpose_groups.tmp" | cut -d: -f2 | tail -n +2 >> "$REVIEW_DIR/duplicates.tmp" || true
        fi
    done

    if [[ -f "$REVIEW_DIR/duplicates.tmp" ]]; then
        while read -r branch; do
            [[ -n "$branch" ]] && DUPLICATES+=("$branch")
        done < "$REVIEW_DIR/duplicates.tmp"
    fi
fi

# Use DUPLICATES safely
if [[ ${#DUPLICATES[@]} -gt 0 ]]; then
    echo "Processing duplicate branches:"
    for branch in "${DUPLICATES[@]}"; do
        echo "Handling duplicate branch: $branch"
        # Logic to handle duplicates, e.g., decide which branch to keep
    done
else
    echo "No duplicate branches found."
fi

# Write categorized files
echo "📝 Writing categorized branch lists..."

# High priority branches
{
    echo "# High Priority Branches - Review First"
    echo "# These branches contain critical functionality or dependency updates"
    echo ""
    for branch in "${HIGH_PRIORITY[@]}"; do
        # Get analysis from temp file
        analysis_line=$(grep "^$branch:" "$REVIEW_DIR/branch_analysis.tmp" 2>/dev/null || echo "")
        if [[ -n "$analysis_line" ]]; then
            IFS=':' read -r _ commits files insertions deletions conflicts purpose <<< "$analysis_line"
            echo "$branch # $purpose, $commits commits, $files files, $conflicts"
        else
            echo "$branch # analysis not available"
        fi
    done
} > "$HIGH_PRIORITY_FILE"

# Ready to merge
{
    echo "# Ready to Merge - Low Risk"
    echo "# These branches have no conflicts and contain safe changes"
    echo ""
    for branch in "${MERGE_READY[@]}"; do
        # Get analysis from temp file
        analysis_line=$(grep "^$branch:" "$REVIEW_DIR/branch_analysis.tmp" 2>/dev/null || echo "")
        if [[ -n "$analysis_line" ]]; then
            IFS=':' read -r _ commits files insertions deletions conflicts purpose <<< "$analysis_line"
            echo "$branch # $purpose, $commits commits, $files files"
        else
            echo "$branch # analysis not available"
        fi
    done
} > "$MERGE_CANDIDATES_FILE"

# Duplicates
{
    echo "# Potential Duplicate Branches"
    echo "# These branches may have overlapping functionality"
    echo ""
    if [[ ${#DUPLICATES[@]} -gt 0 ]]; then
        for branch in "${DUPLICATES[@]}"; do
            # Get analysis from temp file
            analysis_line=$(grep "^$branch:" "$REVIEW_DIR/branch_analysis.tmp" 2>/dev/null || echo "")
            if [[ -n "$analysis_line" ]]; then
                IFS=':' read -r _ commits files insertions deletions conflicts purpose <<< "$analysis_line"
                echo "$branch # $purpose, $commits commits, compare with other $purpose branches"
            else
                echo "$branch # analysis not available"
            fi
        done
    else
        echo "# No duplicate branches found"
    fi
} > "$DUPLICATE_FILE"

# Needs manual review
{
    echo "# Needs Manual Review"
    echo "# These branches require human assessment"
    echo ""
    for branch in "${NEEDS_REVIEW[@]}"; do
        # Get analysis from temp file
        analysis_line=$(grep "^$branch:" "$REVIEW_DIR/branch_analysis.tmp" 2>/dev/null || echo "")
        if [[ -n "$analysis_line" ]]; then
            IFS=':' read -r _ commits files insertions deletions conflicts purpose <<< "$analysis_line"
            echo "$branch # $purpose, $commits commits, $files files, $conflicts"
        else
            echo "$branch # analysis not available"
        fi
    done
} > "$NEEDS_REVIEW_FILE"

# Generate comprehensive report
cat >> "$REPORT_FILE" << EOF

## Analysis Results

**Total Branches Analyzed**: ${#UNMERGED_BRANCHES[@]}
**High Priority**: ${#HIGH_PRIORITY[@]}
**Ready to Merge**: ${#MERGE_READY[@]}
**Potential Duplicates**: ${#DUPLICATES[@]}
**Needs Manual Review**: ${#NEEDS_REVIEW[@]}

## Branch Categories by Purpose

EOF

# Generate purpose groups from temp file
if [[ -f "$REVIEW_DIR/purpose_groups.tmp" ]]; then
    sort "$REVIEW_DIR/purpose_groups.tmp" | cut -d: -f1 | uniq | while read purpose; do
        branches=($(grep "^$purpose:" "$REVIEW_DIR/purpose_groups.tmp" | cut -d: -f2))
        cat >> "$REPORT_FILE" << EOF
### ${purpose} Branches (${#branches[@]})
$(printf '- `%s`\n' "${branches[@]}")

EOF
    done
fi

cat >> "$REPORT_FILE" << EOF

## Recommended Action Plan

### Phase 1: Quick Wins (Ready to Merge)
Execute these merges immediately - they're safe and beneficial:

\`\`\`bash
# Merge ready branches (no conflicts, safe changes)
EOF

for branch in "${MERGE_READY[@]}"; do
    echo "git merge origin/$branch --no-edit" >> "$REPORT_FILE"
done

cat >> "$REPORT_FILE" << EOF
\`\`\`

### Phase 2: High Priority Review
These branches need immediate attention but require careful review:

EOF

for branch in "${HIGH_PRIORITY[@]}"; do
    # Get analysis from temp file
    analysis_line=$(grep "^$branch:" "$REVIEW_DIR/branch_analysis.tmp" 2>/dev/null || echo "")
    if [[ -n "$analysis_line" ]]; then
        IFS=':' read -r _ commits files insertions deletions conflicts purpose <<< "$analysis_line"
        cat >> "$REPORT_FILE" << EOF
- **\`$branch\`**: $purpose functionality, $commits commits, $files files changed
  - Conflicts: $conflicts
  - Action: $([ "$conflicts" = "clean" ] && echo "Merge after review" || echo "Resolve conflicts first")

EOF
    fi
done

cat >> "$REPORT_FILE" << EOF

### Phase 3: Duplicate Resolution
Choose the best version from each group and close the others:

EOF

if [[ ${#DUPLICATES[@]} -gt 0 ]]; then
    current_purpose=""
    for branch in "${DUPLICATES[@]}"; do
        # Get analysis from temp file
        analysis_line=$(grep "^$branch:" "$REVIEW_DIR/branch_analysis.tmp" 2>/dev/null || echo "")
        if [[ -n "$analysis_line" ]]; then
            IFS=':' read -r _ commits files insertions deletions conflicts purpose <<< "$analysis_line"
            if [[ "$purpose" != "$current_purpose" ]]; then
                echo "" >> "$REPORT_FILE"
                echo "**$purpose branches:**" >> "$REPORT_FILE"
                current_purpose="$purpose"
            fi
            echo "- \`$branch\` ($commits commits, $files files)" >> "$REPORT_FILE"
        fi
    done
else
    echo "No duplicate branches detected." >> "$REPORT_FILE"
fi

cat >> "$REPORT_FILE" << EOF

### Phase 4: Manual Review Queue
These branches need individual assessment:

EOF

for branch in "${NEEDS_REVIEW[@]}"; do
    # Get analysis from temp file
    analysis_line=$(grep "^$branch:" "$REVIEW_DIR/branch_analysis.tmp" 2>/dev/null || echo "")
    if [[ -n "$analysis_line" ]]; then
        IFS=':' read -r _ commits files insertions deletions conflicts purpose <<< "$analysis_line"
        echo "- \`$branch\`: $purpose, $commits commits, $conflicts" >> "$REPORT_FILE"
    fi
done

cat >> "$REPORT_FILE" << EOF

## Generated Files

- **High Priority**: \`$HIGH_PRIORITY_FILE\`
- **Ready to Merge**: \`$MERGE_CANDIDATES_FILE\`
- **Duplicates**: \`$DUPLICATE_FILE\`
- **Manual Review**: \`$NEEDS_REVIEW_FILE\`
- **Full Report**: \`$REPORT_FILE\`

## Next Steps

1. **Start with ready-to-merge**: Execute Phase 1 merges immediately
2. **Review high priority**: Assess Phase 2 branches this week
3. **Resolve duplicates**: Choose best versions in Phase 3
4. **Schedule reviews**: Plan Phase 4 branch assessments

## Branch Review Commands

\`\`\`bash
# Review a specific branch
git log --oneline main..origin/BRANCH_NAME
git diff --stat main...origin/BRANCH_NAME
git show-branch main origin/BRANCH_NAME

# Test merge (dry run)
git merge --no-commit --no-ff origin/BRANCH_NAME
git merge --abort  # if you don't want to proceed

# Check for conflicts
git merge-tree \$(git merge-base main origin/BRANCH_NAME) main origin/BRANCH_NAME
\`\`\`

EOF

# Create quick action scripts
cat > "$REVIEW_DIR/merge_ready_branches.sh" << 'EOF'
#!/bin/bash
# Quick merge script for ready-to-merge branches
set -euo pipefail

echo "🚀 Merging ready-to-merge branches..."

READY_BRANCHES=(
EOF

for branch in "${MERGE_READY[@]}"; do
    echo "    \"$branch\"" >> "$REVIEW_DIR/merge_ready_branches.sh"
done

cat >> "$REVIEW_DIR/merge_ready_branches.sh" << 'EOF'
)

for branch in "${READY_BRANCHES[@]}"; do
    echo "Merging: $branch"
    if git merge "origin/$branch" --no-edit; then
        echo "✅ Merged: $branch"
    else
        echo "❌ Failed: $branch"
        git merge --abort 2>/dev/null || true
    fi
done

echo "🎉 Ready-to-merge phase complete!"
EOF

chmod +x "$REVIEW_DIR/merge_ready_branches.sh"

# Summary output
echo ""
echo "📊 Systematic Review Complete!"
echo "=============================="
echo -e "📈 Total branches analyzed: ${BLUE}${#UNMERGED_BRANCHES[@]}${NC}"
echo -e "🔥 High priority: ${RED}${#HIGH_PRIORITY[@]}${NC}"
echo -e "✅ Ready to merge: ${GREEN}${#MERGE_READY[@]}${NC}"
echo -e "👥 Potential duplicates: ${YELLOW}${#DUPLICATES[@]}${NC}"
echo -e "📋 Needs review: ${PURPLE}${#NEEDS_REVIEW[@]}${NC}"
echo ""

if [[ ${#MERGE_READY[@]} -gt 0 ]]; then
    echo -e "${GREEN}🎯 Quick action available!${NC}"
    echo "Run this to merge safe branches immediately:"
    echo -e "${CYAN}$REVIEW_DIR/merge_ready_branches.sh${NC}"
    echo ""
fi

echo "📄 Full analysis report:"
echo -e "${PURPLE}$REPORT_FILE${NC}"
echo ""
echo "📋 Generated files:"
echo "  • High priority: $HIGH_PRIORITY_FILE"
echo "  • Ready to merge: $MERGE_CANDIDATES_FILE"
echo "  • Duplicates: $DUPLICATE_FILE"
echo "  • Manual review: $NEEDS_REVIEW_FILE"
echo ""
echo "🔧 Next steps:"
echo "1. Review the full report"
echo "2. Execute quick wins (ready-to-merge branches)"
echo "3. Schedule reviews for high-priority branches"
echo "4. Plan duplicate resolution strategy"
