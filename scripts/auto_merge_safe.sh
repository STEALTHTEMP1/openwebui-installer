#!/bin/bash

# Auto-merge safe branches with no conflicts
# Uses the analysis from enhanced_branch_analyzer.sh

# Load utility libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/error_handling.sh"
source "$SCRIPT_DIR/lib/resource_manager.sh"
source "$SCRIPT_DIR/lib/lock_manager.sh"
source "$SCRIPT_DIR/lib/dependency_checker.sh"
source "$SCRIPT_DIR/lib/git_cache.sh"
source "$SCRIPT_DIR/lib/input_sanitizer.sh"

# Check dependencies
check_dependencies

# Acquire lock for this operation
if ! acquire_lock "auto_merge"; then
    log_error "Another auto-merge is already running"
    exit 1
fi
auto_release_lock "auto_merge"

echo "🤖 Auto-Merge Safe Branches"
echo "============================"

# Check if analysis exists
if [[ ! -f ".branch-analysis/merge_candidates.txt" ]]; then
    log_error "No analysis found. Run enhanced_branch_analyzer.sh first."
    exit 1
fi

# Create backup branch
BACKUP_BRANCH="backup-before-auto-merge-$(timestamp)"
log_info "Creating backup branch: $BACKUP_BRANCH"
safe_git checkout -b "$BACKUP_BRANCH" 2>/dev/null || log_warn "Already on a branch"
register_branch "$BACKUP_BRANCH"

# Ensure we're on the main branch
git_ensure_main_branch

echo ""

# Read safe merge candidates
SAFE_BRANCHES=()
while IFS= read -r line; do
    if [[ "$line" =~ ^[^#] && -n "$line" ]]; then
        # Validate branch name before adding
        if branch=$(sanitize_branch_name "$line" true 2>/dev/null); then
            SAFE_BRANCHES+=("$branch")
        else
            log_warn "Skipping invalid branch name: $line"
        fi
    fi
done < ".branch-analysis/merge_candidates.txt"

echo "📋 Found ${#SAFE_BRANCHES[@]} safe merge candidates"
echo ""

MERGED_COUNT=0
FAILED_COUNT=0
FAILED_BRANCHES=()

# Start timing
start_timer "auto_merge_operation"

# Process branches
for i in "${!SAFE_BRANCHES[@]}"; do
    branch="${SAFE_BRANCHES[$i]}"
    show_progress $((i + 1)) ${#SAFE_BRANCHES[@]} "Merging branches"

    log_info "Merging: $branch"

    # Check if branch exists
    if ! safe_git show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null; then
        log_error "Branch not found: $branch"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_BRANCHES+=("$branch (not found)")
        continue
    fi

    # Check if already merged
    if safe_git merge-base --is-ancestor "origin/$branch" HEAD 2>/dev/null; then
        log_info "Already merged: $branch"
        MERGED_COUNT=$((MERGED_COUNT + 1))
        continue
    fi

    # Attempt merge
    if safe_git merge "origin/$branch" --no-edit -m "Auto-merge safe branch: $branch" 2>/dev/null; then
        log_info "Successfully merged: $branch"
        MERGED_COUNT=$((MERGED_COUNT + 1))
    else
        log_error "Failed to merge: $branch"
        safe_git merge --abort 2>/dev/null || true
        FAILED_COUNT=$((FAILED_COUNT + 1))
        FAILED_BRANCHES+=("$branch")
    fi
done

# End timing
MERGE_DURATION=$(end_timer "auto_merge_operation")

# Summary
echo ""
echo "📊 Auto-Merge Summary:"
echo "======================"
echo -e "✅ Successfully merged: ${GREEN}$MERGED_COUNT${NC}"
echo -e "❌ Failed merges: ${RED}$FAILED_COUNT${NC}"
echo -e "⏱️  Duration: ${BLUE}${MERGE_DURATION}s${NC}"

if [[ ${#FAILED_BRANCHES[@]} -gt 0 ]]; then
    echo ""
    echo "Failed branches (need manual review):"
    for branch in "${FAILED_BRANCHES[@]}"; do
        echo "  - $branch"
    done

    # Write failed branches to file for manual processing
    {
        echo "# Failed auto-merge branches"
        echo "# Generated: $(iso_timestamp)"
        echo ""
        for branch in "${FAILED_BRANCHES[@]}"; do
            echo "$branch"
        done
    } > ".branch-analysis/failed_auto_merge.txt"
    echo ""
    log_warn "Failed branches written to: .branch-analysis/failed_auto_merge.txt"
fi

echo ""
if [[ $MERGED_COUNT -gt 0 ]]; then
    log_info "Auto-merge phase complete! ($MERGED_COUNT branches merged)"
    echo "Next: Run merge_critical_branches.sh for high-priority merges"
else
    log_warn "No branches were auto-merged."
    echo "This may indicate that all branches require manual attention."
fi

echo ""
log_info "Backup available at: $BACKUP_BRANCH"

# Clean up resources automatically on exit (handled by resource_manager.sh)
