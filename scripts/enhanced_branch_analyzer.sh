#!/bin/bash

# Enhanced Branch Analysis for Universal App Store
# Systematically identifies conflicts and provides resolution strategies

# Load utility libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/error_handling.sh"
source "$SCRIPT_DIR/lib/resource_manager.sh"
source "$SCRIPT_DIR/lib/lock_manager.sh"
source "$SCRIPT_DIR/lib/dependency_checker.sh"
source "$SCRIPT_DIR/lib/git_cache.sh"
source "$SCRIPT_DIR/lib/parallel_processor.sh"
source "$SCRIPT_DIR/lib/input_sanitizer.sh"

# Check dependencies
check_dependencies

# Acquire lock for this operation
if ! acquire_lock "branch_analysis"; then
    log_error "Another branch analysis is already running"
    exit 1
fi
auto_release_lock "branch_analysis"

echo "🔍 Enhanced Branch Analysis for Universal App Store"
echo "=================================================="
echo ""

# Create analysis output directory
ensure_directory ".branch-analysis"
ANALYSIS_DIR=".branch-analysis"
TIMESTAMP=$(timestamp)
REPORT_FILE="$ANALYSIS_DIR/branch_analysis_$TIMESTAMP.md"
register_temp_file "$REPORT_FILE"

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
    local base_branch=${2:-$(git_main_branch)}

    log_debug "Analyzing conflicts for: $branch"

    # Sanitize branch name
    branch=$(sanitize_branch_name "$branch" true)

    # Check if branch exists
    if ! safe_git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        log_error "Branch not found: $branch"
        return 1
    fi

    # Get changed files using cache
    CHANGED_FILES=$(get_cached_changed_files "$base_branch" "origin/$branch")

    # Calculate conflict potential using merge-tree
    CONFLICT_POTENTIAL=0
    if safe_git merge-tree "$base_branch" "origin/$branch" >/dev/null 2>&1; then
        CONFLICT_OUTPUT=$(safe_git merge-tree "$base_branch" "origin/$branch" 2>/dev/null || echo "")
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
cached_remote_update

# Get all remote branches except main/master
ALL_BRANCHES=$(get_cached_branches "remote" | grep -v -E "(HEAD|main|master)" | sort -u || echo "")
ALL_BRANCHES=$(validate_branch_list "$ALL_BRANCHES")
TOTAL_BRANCHES=$(echo "$ALL_BRANCHES" | wc -l)

if [[ -z "$ALL_BRANCHES" || "$TOTAL_BRANCHES" -eq 0 ]]; then
    log_warn "No remote branches found. This may be a local-only repository."
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

# Start timing
start_timer "branch_analysis"

# Analysis containers
AUTO_MERGE=()
GUIDED_MERGE=()
MANUAL_MERGE=()
CRITICAL_BRANCHES=()
HIGH_PRIORITY=()
MEDIUM_PRIORITY=()
LOW_PRIORITY=()

# Use parallel processing if more than 10 branches
if [[ $TOTAL_BRANCHES -gt 10 ]]; then
    log_info "Using parallel processing for $TOTAL_BRANCHES branches"

    # Convert branches to array
    BRANCHES_ARRAY=()
    while IFS= read -r branch; do
        [[ -n "$branch" ]] && BRANCHES_ARRAY+=("$branch")
    done <<< "$ALL_BRANCHES"

    # Process in parallel
    process_branches_parallel "${BRANCHES_ARRAY[@]}"
else
    # Sequential processing for small number of branches
    log_info "Using sequential processing for $TOTAL_BRANCHES branches"

    # Analyze each branch
    COUNTER=0
    for branch in $ALL_BRANCHES; do
        COUNTER=$((COUNTER + 1))
        show_progress $COUNTER $TOTAL_BRANCHES "Analyzing branches"

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
                log_debug "Skipping problematic branch: $branch"
                SKIP_BRANCH=true
                break
            fi
        done

        if [[ "$SKIP_BRANCH" == true ]]; then
            continue
        fi

        # Check if already merged
        if safe_git merge-base --is-ancestor "origin/$branch" HEAD 2>/dev/null; then
            log_debug "Branch already merged: $branch"
            continue
        fi

        # Analyze conflicts and categorize
        if ANALYSIS_RESULT=$(analyze_branch_conflicts "$branch" 2>/dev/null); then
            IFS='|' read -r branch_name strategy priority critical_impact conflict_potential <<< "$ANALYSIS_RESULT"
        else
            # Handle analysis failure gracefully
            strategy="MANUAL_MERGE"
            priority="HIGH"
            log_warn "Analysis failed for $branch, defaulting to manual merge"
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

        log_debug "Branch $branch: Strategy=$strategy, Relevance=$RELEVANCE"
    done
fi

# End timing
ANALYSIS_DURATION=$(end_timer "branch_analysis")

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
echo -e "Analysis completed in: ${BLUE}${ANALYSIS_DURATION}s${NC}"
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

# Clean up resources automatically on exit (handled by resource_manager.sh)
