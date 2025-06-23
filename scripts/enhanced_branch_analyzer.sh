#!/bin/bash

# Enhanced Branch Analysis for Universal App Store
# Systematically identifies conflicts and provides resolution strategies

set -euo pipefail

echo "🔍 Enhanced Branch Analysis for Universal App Store"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Create analysis output directory
mkdir -p .branch-analysis
ANALYSIS_DIR=".branch-analysis"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="$ANALYSIS_DIR/branch_analysis_$TIMESTAMP.md"

# Initialize report
cat > "$REPORT_FILE" << EOF
# Branch Analysis Report - $TIMESTAMP

## Executive Summary
This report analyzes all unmerged branches for the Universal App Store project and provides systematic conflict resolution strategies.

## Methodology
1. **Branch Discovery**: Identify all remote branches
2. **Conflict Analysis**: Analyze potential file conflicts
3. **Priority Assessment**: Rank branches by Universal App Store impact
4. **Resolution Strategy**: Provide specific merge strategies

---

EOF

# Function to analyze branch conflicts
analyze_branch_conflicts() {
    local branch=$1
    local base_branch=${2:-main}

    echo "🔬 Analyzing conflicts for: $branch"

    # Check if branch exists
    if ! git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        echo "❌ Branch not found: $branch"
        return 1
    fi

    # Get changed files
    CHANGED_FILES=$(git diff --name-only "$base_branch"..."origin/$branch" 2>/dev/null || echo "")

    # Calculate conflict potential using merge-tree
    CONFLICT_POTENTIAL=0
    if git merge-tree "$base_branch" "origin/$branch" >/dev/null 2>&1; then
        CONFLICT_OUTPUT=$(git merge-tree "$base_branch" "origin/$branch" 2>/dev/null || echo "")
        CONFLICT_POTENTIAL=$(echo "$CONFLICT_OUTPUT" | grep -c "<<<<<<< " || echo "0")
    fi

    # Critical files that might cause conflicts
    CRITICAL_FILES=(
        "install.py"
        "openwebui_installer/cli.py"
        "openwebui_installer/installer.py"
        "openwebui_installer/gui.py"
        "README.md"
        "pyproject.toml"
        "requirements.txt"
        "OpenWebUI-Desktop/OpenWebUI-Desktop/OpenWebUIApp.swift"
        "OpenWebUI-Desktop/OpenWebUI-Desktop/ContentView.swift"
    )

    # Analyze impact
    CRITICAL_IMPACT=0
    AFFECTED_CRITICAL=()

    for file in "${CRITICAL_FILES[@]}"; do
        if echo "$CHANGED_FILES" | grep -q "^$file$"; then
            CRITICAL_IMPACT=$((CRITICAL_IMPACT + 1))
            AFFECTED_CRITICAL+=("$file")
        fi
    done

    # Write to report
    cat >> "$REPORT_FILE" << EOF
### Branch: \`$branch\`

**Conflict Analysis:**
- **Changed Files**: $(echo "$CHANGED_FILES" | wc -w)
- **Critical Files Affected**: $CRITICAL_IMPACT
- **Conflict Potential**: $CONFLICT_POTENTIAL markers detected

**Critical Files Modified:**
EOF

    for file in "${AFFECTED_CRITICAL[@]}"; do
        echo "- \`$file\`" >> "$REPORT_FILE"
    done

    # Determine resolution strategy
    if [[ $CRITICAL_IMPACT -eq 0 ]]; then
        STRATEGY="AUTO_MERGE"
        PRIORITY="LOW"
        echo "- **Resolution Strategy**: Auto-merge (no critical conflicts)" >> "$REPORT_FILE"
    elif [[ $CRITICAL_IMPACT -le 2 && $CONFLICT_POTENTIAL -eq 0 ]]; then
        STRATEGY="GUIDED_MERGE"
        PRIORITY="MEDIUM"
        echo "- **Resolution Strategy**: Guided merge with validation" >> "$REPORT_FILE"
    else
        STRATEGY="MANUAL_MERGE"
        PRIORITY="HIGH"
        echo "- **Resolution Strategy**: Manual conflict resolution required" >> "$REPORT_FILE"
    fi

    echo "- **Priority**: $PRIORITY" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    # Return analysis results
    echo "$branch|$STRATEGY|$PRIORITY|$CRITICAL_IMPACT|$CONFLICT_POTENTIAL"
}

# Function to categorize branches by Universal App Store relevance
categorize_branch_relevance() {
    local branch=$1

    # Universal App Store high-impact patterns
    if [[ "$branch" == *"app-store"* ]] || [[ "$branch" == *"swift"* ]] || [[ "$branch" == *"universal"* ]]; then
        echo "CRITICAL"
    elif [[ "$branch" == *"container"* ]] || [[ "$branch" == *"multi"* ]] || [[ "$branch" == *"catalog"* ]]; then
        echo "HIGH"
    elif [[ "$branch" == *"feature"* ]] || [[ "$branch" == *"enhance"* ]] || [[ "$branch" == *"improve"* ]]; then
        echo "MEDIUM"
    elif [[ "$branch" == *"fix"* ]] || [[ "$branch" == *"bug"* ]] || [[ "$branch" == *"patch"* ]]; then
        echo "LOW"
    else
        echo "UNKNOWN"
    fi
}

# Main analysis execution
echo "📊 Discovering branches..."
git fetch --all --quiet 2>/dev/null || echo "Note: Some remotes may not be accessible"

# Get all remote branches except main/master
ALL_BRANCHES=$(git branch -r 2>/dev/null | grep -v -E "(HEAD|main|master)" | sed 's/origin\///' | tr -d ' ' | sort -u || echo "")
TOTAL_BRANCHES=$(echo "$ALL_BRANCHES" | wc -l)

if [[ -z "$ALL_BRANCHES" || "$TOTAL_BRANCHES" -eq 0 ]]; then
    echo "⚠️  No remote branches found. This may be a local-only repository."
    echo "Creating mock analysis for demonstration..."

    # Create demonstration data
    TOTAL_BRANCHES=5
    ALL_BRANCHES="codex/enhance-cli
codex/swift-integration
feature/multi-container
codex/documentation-update
codex/bug-fixes"
fi

echo "📋 Found $TOTAL_BRANCHES branches to analyze"
echo ""

# Analysis containers
AUTO_MERGE=()
GUIDED_MERGE=()
MANUAL_MERGE=()
CRITICAL_BRANCHES=()
HIGH_PRIORITY=()
MEDIUM_PRIORITY=()
LOW_PRIORITY=()

# Analyze each branch
COUNTER=0
for branch in $ALL_BRANCHES; do
    COUNTER=$((COUNTER + 1))
    echo -e "${BLUE}[$COUNTER/$TOTAL_BRANCHES]${NC} Analyzing: $branch"

    # Skip problematic branches from smart_merge.sh
    SKIP_PATTERNS=(
        "codex/new-task"
        "codex/find-and-fix-a-bug-in-the-codebase"
        "codex/investigate-empty-openwebui-installer-folder"
        "codex/delete-.ds_store-from-repository"
        "codex/remove-tracked-.ds_store-and-.snapshots"
        "codex/remove-multi-platform-claims-and-update-docs"
    )

    SKIP_BRANCH=false
    for pattern in "${SKIP_PATTERNS[@]}"; do
        if [[ "$branch" == *"$pattern"* ]]; then
            echo -e "  ${YELLOW}⏭️  Skipping (problematic)${NC}"
            SKIP_BRANCH=true
            break
        fi
    done

    if [[ "$SKIP_BRANCH" == true ]]; then
        continue
    fi

    # Check if already merged
    if git merge-base --is-ancestor "origin/$branch" HEAD 2>/dev/null; then
        echo -e "  ${GREEN}✅ Already merged${NC}"
        continue
    fi

    # Analyze conflicts and categorize
    if ANALYSIS_RESULT=$(analyze_branch_conflicts "$branch" 2>/dev/null); then
        IFS='|' read -r branch_name strategy priority critical_impact conflict_potential <<< "$ANALYSIS_RESULT"
    else
        # Handle analysis failure gracefully
        strategy="MANUAL_MERGE"
        priority="HIGH"
        echo -e "  ${YELLOW}⚠️  Analysis failed, defaulting to manual merge${NC}"
    fi

    # Categorize by Universal App Store relevance
    RELEVANCE=$(categorize_branch_relevance "$branch")

    # Sort into categories
    case $strategy in
        "AUTO_MERGE") AUTO_MERGE+=("$branch|$RELEVANCE") ;;
        "GUIDED_MERGE") GUIDED_MERGE+=("$branch|$RELEVANCE") ;;
        "MANUAL_MERGE") MANUAL_MERGE+=("$branch|$RELEVANCE") ;;
    esac

    case $RELEVANCE in
        "CRITICAL") CRITICAL_BRANCHES+=("$branch|$strategy") ;;
        "HIGH") HIGH_PRIORITY+=("$branch|$strategy") ;;
        "MEDIUM") MEDIUM_PRIORITY+=("$branch|$strategy") ;;
        "LOW") LOW_PRIORITY+=("$branch|$strategy") ;;
    esac

    echo -e "  ${PURPLE}Strategy: $strategy | Relevance: $RELEVANCE${NC}"
done

# Generate comprehensive report
cat >> "$REPORT_FILE" << EOF

## Analysis Summary

### By Merge Strategy
- **Auto-Merge Candidates**: ${#AUTO_MERGE[@]}
- **Guided Merge Required**: ${#GUIDED_MERGE[@]}
- **Manual Resolution Required**: ${#MANUAL_MERGE[@]}

### By Universal App Store Relevance
- **Critical (App Store Core)**: ${#CRITICAL_BRANCHES[@]}
- **High Priority (Supporting Features)**: ${#HIGH_PRIORITY[@]}
- **Medium Priority (Enhancements)**: ${#MEDIUM_PRIORITY[@]}
- **Low Priority (Fixes/Cleanup)**: ${#LOW_PRIORITY[@]}

---

## Recommended Merge Order

### Phase 1: Critical Universal App Store Branches
EOF

for branch_info in "${CRITICAL_BRANCHES[@]}"; do
    IFS='|' read -r branch strategy <<< "$branch_info"
    echo "1. \`$branch\` - Strategy: $strategy" >> "$REPORT_FILE"
done

cat >> "$REPORT_FILE" << EOF

### Phase 2: High Priority Supporting Features
EOF

for branch_info in "${HIGH_PRIORITY[@]}"; do
    IFS='|' read -r branch strategy <<< "$branch_info"
    echo "1. \`$branch\` - Strategy: $strategy" >> "$REPORT_FILE"
done

# Print summary to console
echo ""
echo -e "${GREEN}📊 Analysis Complete!${NC}"
echo -e "${BLUE}====================${NC}"
echo -e "Auto-merge candidates: ${GREEN}${#AUTO_MERGE[@]}${NC}"
echo -e "Guided merge required: ${YELLOW}${#GUIDED_MERGE[@]}${NC}"
echo -e "Manual resolution required: ${RED}${#MANUAL_MERGE[@]}${NC}"
echo ""
echo -e "Critical branches: ${PURPLE}${#CRITICAL_BRANCHES[@]}${NC}"
echo -e "High priority: ${BLUE}${#HIGH_PRIORITY[@]}${NC}"
echo -e "Medium priority: ${YELLOW}${#MEDIUM_PRIORITY[@]}${NC}"
echo -e "Low priority: ${GREEN}${#LOW_PRIORITY[@]}${NC}"
echo ""
echo -e "📄 Detailed report: ${BLUE}$REPORT_FILE${NC}"

# Export results for merge scripts
cat > "$ANALYSIS_DIR/merge_candidates.txt" << EOF
# Auto-merge candidates (safe to merge automatically)
EOF

for branch_info in "${AUTO_MERGE[@]}"; do
    IFS='|' read -r branch relevance <<< "$branch_info"
    echo "$branch" >> "$ANALYSIS_DIR/merge_candidates.txt"
done

cat > "$ANALYSIS_DIR/critical_branches.txt" << EOF
# Critical Universal App Store branches (merge first)
EOF

for branch_info in "${CRITICAL_BRANCHES[@]}"; do
    IFS='|' read -r branch strategy <<< "$branch_info"
    echo "$branch" >> "$ANALYSIS_DIR/critical_branches.txt"
done

echo ""
echo -e "${GREEN}🎯 Next Steps:${NC}"
echo "1. Review the analysis report: $REPORT_FILE"
echo "2. Run auto-merge for safe candidates: ./scripts/auto_merge_safe.sh"
echo "3. Process critical branches: ./scripts/merge_critical_branches.sh"
echo "4. Handle manual conflicts: ./scripts/post_merge_validation.sh"
echo ""
echo -e "${BLUE}Ready to execute the merge process!${NC}"
