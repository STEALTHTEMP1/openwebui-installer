#!/bin/bash

# Ongoing Branch Maintenance Script
# Provides comprehensive branch management for OpenWebUI Installer repository

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MAINTENANCE_LOG=".branch-analysis/maintenance.log"

# Ensure we're in the repo root
cd "$REPO_ROOT"

# Create maintenance log if it doesn't exist
mkdir -p .branch-analysis
touch "$MAINTENANCE_LOG"

log_action() {
    local action="$1"
    local details="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $action: $details" >> "$MAINTENANCE_LOG"
    echo -e "${BLUE}[$timestamp]${NC} $action: $details"
}

show_help() {
    cat << EOF
🔧 Branch Maintenance Tool - OpenWebUI Installer

USAGE:
    $0 [COMMAND] [OPTIONS]

COMMANDS:
    status      Show current branch status and health
    cleanup     Run interactive branch cleanup
    audit       Audit branch history and patterns
    protect     Show branch protection recommendations
    stale       Find and review stale branches
    stats       Show detailed repository statistics
    sync        Sync and prune remote references
    help        Show this help message

OPTIONS:
    --dry-run   Show what would be done without executing
    --force     Skip confirmation prompts
    --verbose   Show detailed output

EXAMPLES:
    $0 status                    # Show current status
    $0 cleanup --dry-run         # Preview cleanup actions
    $0 audit --verbose           # Detailed audit report
    $0 stale                     # Find stale branches
    $0 stats                     # Repository statistics

AUTOMATION:
    This script is designed to be run weekly as part of repository maintenance.
    It integrates with the existing branch analysis tools and GitHub Actions.
EOF
}

show_status() {
    echo "📊 Repository Branch Status"
    echo "=========================="

    # Update remote references
    git remote update origin --prune >/dev/null 2>&1 || true

    # Basic statistics
    local total_remote=$(git branch -r | grep -v HEAD | wc -l)
    local total_local=$(git branch | wc -l)
    local merged_count=$(git branch -r --merged main | grep -v 'main\|master\|HEAD' | wc -l)
    local unmerged_count=$((total_remote - merged_count - 1)) # -1 for main

    echo -e "🌐 Remote branches: ${BLUE}$total_remote${NC}"
    echo -e "💻 Local branches: ${BLUE}$total_local${NC}"
    echo -e "✅ Merged branches: ${GREEN}$merged_count${NC}"
    echo -e "🔄 Unmerged branches: ${YELLOW}$unmerged_count${NC}"

    # Branch categories
    echo ""
    echo "📋 Branch Categories:"
    local codex_count=$(git branch -r | grep -c 'codex/' || echo 0)
    local dependabot_count=$(git branch -r | grep -c 'dependabot/' || echo 0)
    local feature_count=$(git branch -r | grep -c 'feature/' || echo 0)

    echo -e "   🤖 Codex branches: ${PURPLE}$codex_count${NC}"
    echo -e "   🔄 Dependabot branches: ${CYAN}$dependabot_count${NC}"
    echo -e "   ✨ Feature branches: ${GREEN}$feature_count${NC}"

    # Health indicators
    echo ""
    echo "🏥 Repository Health:"
    if [[ $total_remote -lt 50 ]]; then
        echo -e "   Branch count: ${GREEN}Healthy${NC} ($total_remote < 50)"
    elif [[ $total_remote -lt 100 ]]; then
        echo -e "   Branch count: ${YELLOW}Moderate${NC} ($total_remote branches)"
    else
        echo -e "   Branch count: ${RED}High${NC} ($total_remote branches - cleanup recommended)"
    fi

    if [[ $merged_count -gt 10 ]]; then
        echo -e "   Merged branches: ${YELLOW}$merged_count ready for cleanup${NC}"
    else
        echo -e "   Merged branches: ${GREEN}Clean${NC} ($merged_count)"
    fi

    # Recent activity
    echo ""
    echo "📈 Recent Activity (last 7 days):"
    local recent_branches=$(git for-each-ref --format='%(refname:short)' --sort=-committerdate refs/remotes/origin | head -5)
    while IFS= read -r branch; do
        if [[ "$branch" != "origin/main" && "$branch" != "origin/master" ]]; then
            local last_commit=$(git log -1 --format='%ar' "$branch" 2>/dev/null || echo "unknown")
            echo -e "   ${CYAN}${branch#origin/}${NC} - $last_commit"
        fi
    done <<< "$recent_branches"

    log_action "STATUS" "Branch status check completed"
}

run_cleanup() {
    local dry_run=${1:-false}
    local force=${2:-false}

    echo "🧹 Branch Cleanup"
    echo "================="

    if [[ "$dry_run" == "true" ]]; then
        echo -e "${YELLOW}🧪 DRY RUN MODE - No changes will be made${NC}"
    fi

    # Update remote references
    echo "🔄 Updating remote references..."
    git remote update origin --prune >/dev/null 2>&1 || true

    # Find merged branches
    local merged_branches=$(git branch -r --merged main | grep -v 'main\|master\|HEAD' | sed 's/origin\///' | tr -d ' ')
    local safe_branches=()

    while IFS= read -r branch; do
        [[ -z "$branch" ]] && continue

        # Only include safe patterns
        if [[ "$branch" =~ ^(codex/|dependabot/|feature/|bugfix/|hotfix/|[a-z0-9]+-codex/) ]]; then
            safe_branches+=("$branch")
        fi
    done <<< "$merged_branches"

    if [[ ${#safe_branches[@]} -eq 0 ]]; then
        echo -e "${GREEN}✨ No merged branches found to cleanup${NC}"
        return 0
    fi

    echo -e "Found ${#safe_branches[@]} merged branches to cleanup:"
    for branch in "${safe_branches[@]}"; do
        echo -e "  ${YELLOW}$branch${NC}"
    done

    if [[ "$force" != "true" && "$dry_run" != "true" ]]; then
        echo ""
        read -p "Continue with cleanup? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "❌ Cleanup cancelled"
            return 1
        fi
    fi

    # Perform cleanup
    local deleted_count=0
    local failed_count=0

    for branch in "${safe_branches[@]}"; do
        if [[ "$dry_run" == "true" ]]; then
            echo -e "🧪 Would delete: ${YELLOW}$branch${NC}"
            ((deleted_count++))
        else
            if git push origin --delete "$branch" >/dev/null 2>&1; then
                echo -e "✅ Deleted: ${GREEN}$branch${NC}"
                ((deleted_count++))
            else
                echo -e "❌ Failed: ${RED}$branch${NC}"
                ((failed_count++))
            fi
        fi
    done

    echo ""
    echo "📊 Cleanup Summary:"
    echo -e "✅ Processed: ${GREEN}$deleted_count${NC}"
    if [[ $failed_count -gt 0 ]]; then
        echo -e "❌ Failed: ${RED}$failed_count${NC}"
    fi

    log_action "CLEANUP" "Processed $deleted_count branches, $failed_count failed"
}

audit_branches() {
    local verbose=${1:-false}

    echo "🔍 Branch Audit"
    echo "==============="

    # Create audit report
    local audit_file=".branch-analysis/audit_$(date +%Y%m%d_%H%M%S).md"

    cat > "$audit_file" << EOF
# Branch Audit Report

**Date**: $(date)
**Repository**: OpenWebUI Installer
**Auditor**: $(git config user.name || echo "Unknown")

## Summary
EOF

    # Analyze branch patterns
    echo "📋 Analyzing branch patterns..."

    local all_branches=$(git branch -r | grep -v HEAD | sed 's/origin\///' | tr -d ' ')
    local patterns=()
    local pattern_counts=()

    # Count patterns
    while IFS= read -r branch; do
        [[ -z "$branch" ]] && continue

        local pattern=""
        if [[ "$branch" =~ ^codex/ ]]; then
            pattern="codex/*"
        elif [[ "$branch" =~ ^[a-z0-9]+-codex/ ]]; then
            pattern="user-codex/*"
        elif [[ "$branch" =~ ^dependabot/ ]]; then
            pattern="dependabot/*"
        elif [[ "$branch" =~ ^feature/ ]]; then
            pattern="feature/*"
        else
            pattern="other/*"
        fi

        # Count occurrences
        local found=false
        for i in "${!patterns[@]}"; do
            if [[ "${patterns[$i]}" == "$pattern" ]]; then
                pattern_counts[$i]=$((${pattern_counts[$i]} + 1))
                found=true
                break
            fi
        done

        if [[ "$found" == "false" ]]; then
            patterns+=("$pattern")
            pattern_counts+=(1)
        fi
    done <<< "$all_branches"

    # Display patterns
    echo "🏷️ Branch Patterns:"
    for i in "${!patterns[@]}"; do
        echo -e "   ${patterns[$i]}: ${BLUE}${pattern_counts[$i]}${NC} branches"
        echo "- **${patterns[$i]}**: ${pattern_counts[$i]} branches" >> "$audit_file"
    done

    # Find anomalies
    echo ""
    echo "🚨 Potential Issues:"

    # Very old branches
    local old_branches=$(git for-each-ref --format='%(refname:short) %(committerdate:relative)' refs/remotes/origin | grep -E 'months? ago|years? ago' | head -5)
    if [[ -n "$old_branches" ]]; then
        echo -e "   ${YELLOW}Old branches detected:${NC}"
        while IFS= read -r line; do
            echo -e "     $line"
        done <<< "$old_branches"
    fi

    # Duplicate-looking branches
    local duplicate_patterns=$(git branch -r | sed 's/origin\///' | grep -E '^[a-z0-9]+-codex/' | sed 's/^[a-z0-9]*-codex\///' | sort | uniq -d)
    if [[ -n "$duplicate_patterns" ]]; then
        echo -e "   ${YELLOW}Potential duplicates:${NC}"
        while IFS= read -r pattern; do
            echo -e "     Similar: $pattern"
        done <<< "$duplicate_patterns"
    fi

    # Large number of branches by same author
    echo ""
    echo "👥 Top Branch Creators:"
    git for-each-ref --format='%(authorname)' refs/remotes/origin | sort | uniq -c | sort -nr | head -3 | while read count author; do
        echo -e "   ${CYAN}$author${NC}: $count branches"
    done

    if [[ "$verbose" == "true" ]]; then
        echo ""
        echo "📊 Detailed Branch List:"
        git for-each-ref --format='%(refname:short) %(authorname) %(committerdate:relative)' refs/remotes/origin | sort
    fi

    echo ""
    echo -e "📄 Detailed audit saved to: ${PURPLE}$audit_file${NC}"

    log_action "AUDIT" "Branch audit completed, report saved to $audit_file"
}

find_stale_branches() {
    echo "🕐 Stale Branch Analysis"
    echo "======================="

    local thirty_days_ago=$(date -d '30 days ago' +%s 2>/dev/null || date -v-30d +%s 2>/dev/null || echo "0")
    local stale_branches=()

    echo "🔍 Scanning for branches older than 30 days..."

    while IFS= read -r branch; do
        [[ -z "$branch" ]] && continue
        [[ "$branch" =~ ^(main|master)$ ]] && continue

        local last_commit_date=$(git log -1 --format="%ct" "origin/$branch" 2>/dev/null || echo "0")

        if [[ "$last_commit_date" -lt "$thirty_days_ago" && "$last_commit_date" != "0" ]]; then
            local relative_date=$(git log -1 --format="%ar" "origin/$branch" 2>/dev/null || echo "unknown")
            local author=$(git log -1 --format="%an" "origin/$branch" 2>/dev/null || echo "unknown")
            stale_branches+=("$branch|$relative_date|$author")
        fi
    done <<< "$(git branch -r | sed 's/origin\///' | tr -d ' ')"

    if [[ ${#stale_branches[@]} -eq 0 ]]; then
        echo -e "${GREEN}✨ No stale branches found${NC}"
        return 0
    fi

    echo -e "Found ${RED}${#stale_branches[@]}${NC} stale branches:"
    echo ""

    for branch_info in "${stale_branches[@]}"; do
        IFS='|' read -r branch date author <<< "$branch_info"
        echo -e "  ${YELLOW}$branch${NC}"
        echo -e "    Last commit: $date by $author"

        # Check if merged
        if git merge-base --is-ancestor "origin/$branch" HEAD 2>/dev/null; then
            echo -e "    Status: ${GREEN}Merged (safe to delete)${NC}"
        else
            echo -e "    Status: ${RED}Unmerged (review needed)${NC}"
        fi
        echo ""
    done

    log_action "STALE_SCAN" "Found ${#stale_branches[@]} stale branches"
}

show_stats() {
    echo "📊 Repository Statistics"
    echo "======================="

    # Basic stats
    local total_commits=$(git rev-list --all --count 2>/dev/null || echo "0")
    local contributors=$(git shortlog -sn | wc -l)
    local repo_size=$(du -sh .git 2>/dev/null | cut -f1 || echo "unknown")

    echo -e "📈 Repository Overview:"
    echo -e "   Total commits: ${BLUE}$total_commits${NC}"
    echo -e "   Contributors: ${BLUE}$contributors${NC}"
    echo -e "   Repository size: ${BLUE}$repo_size${NC}"

    # Branch statistics
    echo ""
    echo -e "🌿 Branch Statistics:"
    local remote_branches=$(git branch -r | grep -v HEAD | wc -l)
    local local_branches=$(git branch | wc -l)
    local merged_branches=$(git branch -r --merged main | grep -v 'main\|master\|HEAD' | wc -l)

    echo -e "   Remote branches: ${BLUE}$remote_branches${NC}"
    echo -e "   Local branches: ${BLUE}$local_branches${NC}"
    echo -e "   Merged branches: ${BLUE}$merged_branches${NC}"
    echo -e "   Cleanup potential: ${YELLOW}$merged_branches branches${NC}"

    # Activity statistics
    echo ""
    echo -e "📅 Activity Statistics:"
    local commits_last_week=$(git rev-list --count --since='1 week ago' HEAD 2>/dev/null || echo "0")
    local commits_last_month=$(git rev-list --count --since='1 month ago' HEAD 2>/dev/null || echo "0")

    echo -e "   Commits last week: ${GREEN}$commits_last_week${NC}"
    echo -e "   Commits last month: ${GREEN}$commits_last_month${NC}"

    # Top contributors (last 30 days)
    echo ""
    echo -e "👥 Top Contributors (last 30 days):"
    git shortlog -sn --since='30 days ago' | head -5 | while IFS= read -r line; do
        echo -e "   ${CYAN}$line${NC}"
    done

    # Maintenance history
    if [[ -f "$MAINTENANCE_LOG" ]]; then
        echo ""
        echo -e "🔧 Recent Maintenance:"
        tail -5 "$MAINTENANCE_LOG" | while IFS= read -r line; do
            echo -e "   ${PURPLE}$line${NC}"
        done
    fi

    log_action "STATS" "Repository statistics displayed"
}

sync_remotes() {
    echo "🔄 Syncing Remote References"
    echo "============================"

    echo "🌐 Fetching from origin..."
    if git remote update origin --prune; then
        echo -e "${GREEN}✅ Remote sync successful${NC}"
    else
        echo -e "${RED}❌ Remote sync failed${NC}"
        return 1
    fi

    # Show what was pruned
    echo ""
    echo "🧹 Cleanup Summary:"
    local pruned_count=$(git remote prune origin --dry-run 2>/dev/null | wc -l || echo "0")
    if [[ "$pruned_count" -gt 0 ]]; then
        echo -e "   Pruned references: ${YELLOW}$pruned_count${NC}"
    else
        echo -e "   No references to prune: ${GREEN}Clean${NC}"
    fi

    log_action "SYNC" "Remote references synchronized"
}

# Main execution
main() {
    local command=${1:-"help"}
    local dry_run=false
    local force=false
    local verbose=false

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run=true
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            --verbose)
                verbose=true
                shift
                ;;
            -*)
                echo "Unknown option: $1"
                exit 1
                ;;
            *)
                break
                ;;
        esac
    done

    # Execute command
    case $command in
        status)
            show_status
            ;;
        cleanup)
            run_cleanup "$dry_run" "$force"
            ;;
        audit)
            audit_branches "$verbose"
            ;;
        protect)
            echo "📋 Branch protection setup guide:"
            echo "See .github/BRANCH_PROTECTION_SETUP.md for detailed instructions"
            ;;
        stale)
            find_stale_branches
            ;;
        stats)
            show_stats
            ;;
        sync)
            sync_remotes
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "Unknown command: $command"
            echo "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
