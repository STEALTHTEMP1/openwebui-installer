# Branch Analysis Script - Implementation Plan for Issues 1-16

## Overview
This document provides detailed implementation plans to address critical issues, performance problems, security concerns, and maintainability challenges in the Branch Analysis Script system.

---

## Issue 1: Error Handling & Robustness

### Problem
Scripts use `set -euo pipefail` but many Git commands can fail silently, leading to crashes or incorrect analysis results.

### Solution
```bash
# Create shared error handling utilities
# File: scripts/lib/error_handling.sh

#!/bin/bash

# Centralized error handling for branch analysis scripts
set -euo pipefail

# Error codes
readonly E_GIT_ERROR=10
readonly E_NETWORK_ERROR=11
readonly E_PERMISSION_ERROR=12
readonly E_DEPENDENCY_ERROR=13

# Error handling function
handle_error() {
    local error_code=$1
    local error_message=$2
    local line_number=${3:-"unknown"}
    local function_name=${4:-"main"}
    
    echo "ERROR [$error_code] in $function_name at line $line_number: $error_message" >&2
    
    # Log to analysis directory if available
    if [[ -d ".branch-analysis" ]]; then
        echo "[$(date)] ERROR [$error_code] $function_name:$line_number - $error_message" >> .branch-analysis/error.log
    fi
    
    # Cleanup on error
    cleanup_on_error
    exit $error_code
}

# Safe Git command wrapper
safe_git() {
    local git_command="$*"
    local output
    local exit_code
    
    if output=$(git $git_command 2>&1); then
        echo "$output"
        return 0
    else
        exit_code=$?
        case $exit_code in
            128) handle_error $E_GIT_ERROR "Git repository error: $output" $LINENO "${FUNCNAME[1]}" ;;
            1) handle_error $E_GIT_ERROR "Git command failed: $git_command - $output" $LINENO "${FUNCNAME[1]}" ;;
            *) handle_error $E_GIT_ERROR "Unknown git error ($exit_code): $output" $LINENO "${FUNCNAME[1]}" ;;
        esac
    fi
}

# Network operation wrapper
safe_network_operation() {
    local operation="$1"
    local max_retries=3
    local retry_count=0
    
    while [[ $retry_count -lt $max_retries ]]; do
        if eval "$operation" 2>/dev/null; then
            return 0
        else
            retry_count=$((retry_count + 1))
            echo "Network operation failed, retry $retry_count/$max_retries..." >&2
            sleep $((retry_count * 2))
        fi
    done
    
    handle_error $E_NETWORK_ERROR "Network operation failed after $max_retries retries: $operation" $LINENO "${FUNCNAME[1]}"
}

# Cleanup function
cleanup_on_error() {
    if [[ -n "${BACKUP_BRANCH:-}" ]]; then
        git checkout main 2>/dev/null || true
        echo "Backup branch available: $BACKUP_BRANCH"
    fi
    
    if [[ -n "${TEMP_FILES:-}" ]]; then
        rm -f $TEMP_FILES 2>/dev/null || true
    fi
}

# Trap errors
trap 'handle_error $? "Unexpected error" $LINENO "${FUNCNAME[0]}"' ERR
```

### Implementation Steps
1. Create `scripts/lib/error_handling.sh`
2. Update all scripts to source this library
3. Replace direct git calls with `safe_git` wrapper
4. Add network operation wrappers for `git fetch/remote update`

---

## Issue 2: Resource Management

### Problem
No cleanup of temporary branches/files on script failure, leading to repository pollution.

### Solution
```bash
# File: scripts/lib/resource_manager.sh

#!/bin/bash

# Resource management for branch analysis scripts
source "$(dirname "${BASH_SOURCE[0]}")/error_handling.sh"

# Global resource tracking
declare -a CREATED_BRANCHES=()
declare -a TEMP_FILES=()
declare -a ANALYSIS_DIRS=()

# Register resources for cleanup
register_branch() {
    local branch_name="$1"
    CREATED_BRANCHES+=("$branch_name")
    echo "Registered branch for cleanup: $branch_name"
}

register_temp_file() {
    local file_path="$1"
    TEMP_FILES+=("$file_path")
}

register_analysis_dir() {
    local dir_path="$1"
    ANALYSIS_DIRS+=("$dir_path")
}

# Cleanup function
cleanup_resources() {
    local force_cleanup=${1:-false}
    
    echo "🧹 Cleaning up resources..."
    
    # Cleanup temporary branches
    if [[ ${#CREATED_BRANCHES[@]} -gt 0 ]]; then
        echo "Cleaning up ${#CREATED_BRANCHES[@]} temporary branches..."
        for branch in "${CREATED_BRANCHES[@]}"; do
            if git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
                if [[ "$force_cleanup" == "true" ]]; then
                    git branch -D "$branch" 2>/dev/null || echo "Failed to delete branch: $branch"
                else
                    echo "Temporary branch preserved: $branch (use --force-cleanup to remove)"
                fi
            fi
        done
    fi
    
    # Cleanup temporary files
    if [[ ${#TEMP_FILES[@]} -gt 0 ]]; then
        echo "Cleaning up ${#TEMP_FILES[@]} temporary files..."
        for file in "${TEMP_FILES[@]}"; do
            rm -f "$file" 2>/dev/null || echo "Failed to remove file: $file"
        done
    fi
    
    # Cleanup old analysis directories (keep last 5)
    if [[ -d ".branch-analysis" ]]; then
        local old_dirs=($(ls -t .branch-analysis/cleanup-* 2>/dev/null | tail -n +6))
        if [[ ${#old_dirs[@]} -gt 0 ]]; then
            echo "Cleaning up ${#old_dirs[@]} old analysis directories..."
            rm -rf "${old_dirs[@]}" 2>/dev/null || true
        fi
    fi
}

# Exit handler
cleanup_on_exit() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo "Script failed with exit code $exit_code, preserving resources for debugging"
        cleanup_resources false
    else
        cleanup_resources true
    fi
    exit $exit_code
}

# Register exit handler
trap cleanup_on_exit EXIT
```

### Implementation Steps
1. Create centralized data management system
2. Implement JSON-based structured storage
3. Add incremental update capabilities
4. Generate legacy files for backward compatibility

---

## Issue 8: Backup Strategy Limitations

### Problem
Only creates single backup branch before auto-merge with no rollback mechanism for complex merge sequences.

### Solution
```bash
# File: scripts/lib/backup_manager.sh

#!/bin/bash

# Comprehensive backup and rollback system
source "$(dirname "${BASH_SOURCE[0]}")/error_handling.sh"
source "$(dirname "${BASH_SOURCE[0]}")/resource_manager.sh"

readonly BACKUP_DIR=".branch-analysis/backups"
readonly MAX_BACKUPS=10

# Initialize backup system
init_backup_system() {
    mkdir -p "$BACKUP_DIR"
    
    # Create backup registry
    if [[ ! -f "$BACKUP_DIR/registry.json" ]]; then
        cat > "$BACKUP_DIR/registry.json" << 'EOF'
{
  "version": "1.0",
  "backups": []
}
EOF
    fi
}

# Create comprehensive backup
create_backup() {
    local operation_type="$1"
    local description="$2"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_id="backup_${operation_type}_${timestamp}"
    local backup_path="$BACKUP_DIR/$backup_id"
    
    init_backup_system
    
    echo "🔒 Creating backup: $backup_id"
    mkdir -p "$backup_path"
    
    # Backup current state
    local current_branch=$(git branch --show-current)
    local current_commit=$(git rev-parse HEAD)
    local working_tree_clean=true
    
    if ! git diff --quiet; then
        working_tree_clean=false
    fi
    
    # Create state snapshot
    cat > "$backup_path/state.json" << EOF
{
  "backup_id": "$backup_id",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "operation_type": "$operation_type",
  "description": "$description",
  "git_state": {
    "current_branch": "$current_branch",
    "current_commit": "$current_commit",
    "working_tree_clean": $working_tree_clean,
    "staged_files": $(git diff --cached --name-only | jq -R . | jq -s .),
    "modified_files": $(git diff --name-only | jq -R . | jq -s .)
  }
}
EOF
    
    # Create backup branch
    local backup_branch="backup/${backup_id}"
    git checkout -b "$backup_branch" >/dev/null 2>&1
    register_branch "$backup_branch"
    
    # Stash working changes if any
    if [[ "$working_tree_clean" == "false" ]]; then
        git stash push -m "Backup stash for $backup_id" --include-untracked
        echo "stash_created: true" >> "$backup_path/state.json"
    fi
    
    # Return to original branch
    git checkout "$current_branch" >/dev/null 2>&1
    
    # Update backup registry
    local temp_file=$(mktemp)
    register_temp_file "$temp_file"
    
    jq ".backups += [{
        \"backup_id\": \"$backup_id\",
        \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
        \"operation_type\": \"$operation_type\",
        \"description\": \"$description\",
        \"backup_branch\": \"$backup_branch\",
        \"original_branch\": \"$current_branch\",
        \"original_commit\": \"$current_commit\"
    }]" "$BACKUP_DIR/registry.json" > "$temp_file" && mv "$temp_file" "$BACKUP_DIR/registry.json"
    
    # Clean old backups
    cleanup_old_backups
    
    echo "✓ Backup created: $backup_id"
    echo "$backup_id"
}

# Rollback to backup
rollback_to_backup() {
    local backup_id="$1"
    local force_rollback=${2:-false}
    local backup_path="$BACKUP_DIR/$backup_id"
    
    if [[ ! -d "$backup_path" ]]; then
        handle_error $E_GIT_ERROR "Backup not found: $backup_id" $LINENO "${FUNCNAME[0]}"
    fi
    
    echo "🔄 Rolling back to backup: $backup_id"
    
    # Load backup state
    local backup_state
    backup_state=$(cat "$backup_path/state.json")
    
    local original_branch
    original_branch=$(echo "$backup_state" | jq -r '.git_state.current_branch')
    
    local original_commit
    original_commit=$(echo "$backup_state" | jq -r '.git_state.current_commit')
    
    local backup_branch
    backup_branch=$(echo "$backup_state" | jq -r '.backup_branch // "backup/'$backup_id'"')
    
    # Confirm rollback if not forced
    if [[ "$force_rollback" != "true" ]]; then
        echo "This will reset your repository to the state from backup $backup_id"
        echo "Original branch: $original_branch"
        echo "Original commit: $original_commit"
        read -p "Continue with rollback? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Rollback cancelled"
            return 1
        fi
    fi
    
    # Perform rollback
    git checkout "$original_branch" >/dev/null 2>&1 || {
        echo "Failed to checkout original branch, using backup branch"
        git checkout "$backup_branch" >/dev/null 2>&1
        git checkout -b "$original_branch" >/dev/null 2>&1
    }
    
    # Reset to original commit
    git reset --hard "$original_commit" >/dev/null 2>&1
    
    # Restore stashed changes if any
    local stash_created
    stash_created=$(echo "$backup_state" | jq -r '.stash_created // false')
    
    if [[ "$stash_created" == "true" ]]; then
        if git stash list | grep -q "Backup stash for $backup_id"; then
            echo "Restoring stashed changes..."
            git stash pop >/dev/null 2>&1 || echo "Warning: Could not restore stashed changes"
        fi
    fi
    
    echo "✅ Rollback complete to backup: $backup_id"
}

# List available backups
list_backups() {
    local show_details=${1:-false}
    
    if [[ ! -f "$BACKUP_DIR/registry.json" ]]; then
        echo "No backups found"
        return 0
    fi
    
    echo "📋 Available backups:"
    echo "===================="
    
    if [[ "$show_details" == "true" ]]; then
        jq -r '.backups[] | "\(.backup_id) - \(.timestamp) - \(.operation_type) - \(.description)"' "$BACKUP_DIR/registry.json"
    else
        jq -r '.backups[] | "\(.backup_id) - \(.operation_type) - \(.description)"' "$BACKUP_DIR/registry.json"
    fi
}

# Cleanup old backups
cleanup_old_backups() {
    local backup_count
    backup_count=$(jq '.backups | length' "$BACKUP_DIR/registry.json" 2>/dev/null || echo 0)
    
    if [[ $backup_count -gt $MAX_BACKUPS ]]; then
        local excess=$((backup_count - MAX_BACKUPS))
        echo "Cleaning up $excess old backups..."
        
        # Get oldest backups to remove
        local old_backups
        old_backups=$(jq -r ".backups | sort_by(.timestamp) | .[:$excess] | .[].backup_id" "$BACKUP_DIR/registry.json")
        
        for backup_id in $old_backups; do
            rm -rf "$BACKUP_DIR/$backup_id" 2>/dev/null || true
            
            # Remove backup branch
            local backup_branch="backup/$backup_id"
            git branch -D "$backup_branch" 2>/dev/null || true
        done
        
        # Update registry
        local temp_file=$(mktemp)
        register_temp_file "$temp_file"
        
        jq ".backups |= sort_by(.timestamp) | .backups |= .[$excess:]" "$BACKUP_DIR/registry.json" > "$temp_file" && mv "$temp_file" "$BACKUP_DIR/registry.json"
    fi
}

# Validate backup integrity
validate_backup() {
    local backup_id="$1"
    local backup_path="$BACKUP_DIR/$backup_id"
    
    if [[ ! -d "$backup_path" ]]; then
        echo "❌ Backup directory not found: $backup_id"
        return 1
    fi
    
    if [[ ! -f "$backup_path/state.json" ]]; then
        echo "❌ Backup state file missing: $backup_id"
        return 1
    fi
    
    # Check if backup branch exists
    local backup_branch="backup/$backup_id"
    if ! git show-ref --verify --quiet "refs/heads/$backup_branch" 2>/dev/null; then
        echo "❌ Backup branch missing: $backup_branch"
        return 1
    fi
    
    echo "✅ Backup valid: $backup_id"
    return 0
}
```

### Implementation Steps
1. Create comprehensive backup system with metadata
2. Implement multi-point rollback capability
3. Add backup validation and integrity checks
4. Integrate with existing scripts

---

## Issue 9: Branch Name Injection

### Problem
Branch names used directly in shell commands without sanitization, creating potential security vulnerabilities.

### Solution
```bash
# File: scripts/lib/input_sanitizer.sh

#!/bin/bash

# Input sanitization and validation
source "$(dirname "${BASH_SOURCE[0]}")/error_handling.sh"

# Sanitize branch name
sanitize_branch_name() {
    local branch_name="$1"
    local strict_mode=${2:-false}
    
    # Basic validation
    if [[ -z "$branch_name" ]]; then
        handle_error $E_GIT_ERROR "Empty branch name" $LINENO "${FUNCNAME[0]}"
    fi
    
    # Check for dangerous characters
    local dangerous_chars='[;&|`$(){}[\]<>*?!]'
    if [[ "$branch_name" =~ $dangerous_chars ]]; then
        handle_error $E_GIT_ERROR "Branch name contains dangerous characters: $branch_name" $LINENO "${FUNCNAME[0]}"
    fi
    
    # Check for command injection patterns
    local injection_patterns=(
        "rm -"
        "sudo"
        "chmod"
        "eval"
        "exec"
        "bash"
        "sh"
        "/bin/"
        "/usr/"
        "/etc/"
    )
    
    for pattern in "${injection_patterns[@]}"; do
        if [[ "$branch_name" == *"$pattern"* ]]; then
            handle_error $E_GIT_ERROR "Branch name contains suspicious pattern: $branch_name" $LINENO "${FUNCNAME[0]}"
        fi
    done
    
    # Strict mode additional checks
    if [[ "$strict_mode" == "true" ]]; then
        # Only allow alphanumeric, hyphens, underscores, forward slashes
        if [[ ! "$branch_name" =~ ^[a-zA-Z0-9/_-]+$ ]]; then
            handle_error $E_GIT_ERROR "Branch name contains invalid characters (strict mode): $branch_name" $LINENO "${FUNCNAME[0]}"
        fi
        
        # Check length
        if [[ ${#branch_name} -gt 100 ]]; then
            handle_error $E_GIT_ERROR "Branch name too long (max 100 chars): $branch_name" $LINENO "${FUNCNAME[0]}"
        fi
    fi
    
    # Return sanitized name (for now, just return original if it passed validation)
    echo "$branch_name"
}

# Safe command execution with branch names
safe_git_with_branch() {
    local git_command="$1"
    local branch_name="$2"
    local additional_args=("${@:3}")
    
    # Sanitize branch name
    local safe_branch
    safe_branch=$(sanitize_branch_name "$branch_name" true)
    
    # Escape branch name for shell safety
    local escaped_branch
    escaped_branch=$(printf '%q' "$safe_branch")
    
    # Execute git command safely
    safe_git "$git_command" "$escaped_branch" "${additional_args[@]}"
}

# Validate file path
validate_file_path() {
    local file_path="$1"
    local allow_relative=${2:-true}
    
    if [[ -z "$file_path" ]]; then
        handle_error $E_GIT_ERROR "Empty file path" $LINENO "${FUNCNAME[0]}"
    fi
    
    # Check for directory traversal
    if [[ "$file_path" == *".."* ]]; then
        handle_error $E_GIT_ERROR "File path contains directory traversal: $file_path" $LINENO "${FUNCNAME[0]}"
    fi
    
    # Check for absolute paths if not allowed
    if [[ "$allow_relative" == "false" && "$file_path" == "/"* ]]; then
        handle_error $E_GIT_ERROR "Absolute paths not allowed: $file_path" $LINENO "${FUNCNAME[0]}"
    fi
    
    # Check for dangerous file patterns
    local dangerous_patterns=(
        "/etc/"
        "/bin/"
        "/usr/bin/"
        "/sbin/"
        "/root/"
        ".ssh/"
        ".git/config"
    )
    
    for pattern in "${dangerous_patterns[@]}"; do
        if [[ "$file_path" == *"$pattern"* ]]; then
            handle_error $E_GIT_ERROR "File path contains dangerous pattern: $file_path" $LINENO "${FUNCNAME[0]}"
        fi
    done
    
    echo "$file_path"
}

# Sanitize command line arguments
sanitize_args() {
    local args=("$@")
    local sanitized_args=()
    
    for arg in "${args[@]}"; do
        # Basic sanitization - escape special characters
        local sanitized_arg
        sanitized_arg=$(printf '%q' "$arg")
        sanitized_args+=("$sanitized_arg")
    done
    
    printf '%s\n' "${sanitized_args[@]}"
}

# Validate branch list from git command
validate_branch_list() {
    local branch_list="$1"
    local validated_branches=()
    
    while IFS= read -r branch; do
        [[ -z "$branch" ]] && continue
        
        # Skip empty lines and comments
        [[ "$branch" =~ ^[[:space:]]*$ ]] && continue
        [[ "$branch" =~ ^[[:space:]]*# ]] && continue
        
        # Clean up whitespace
        branch=$(echo "$branch" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        
        # Remove origin/ prefix if present
        branch=${branch#origin/}
        
        # Remove asterisk prefix if present (current branch marker)
        branch=${branch#\*}
        branch=$(echo "$branch" | sed 's/^[[:space:]]*//')
        
        # Skip main/master branches in validation lists
        [[ "$branch" == "main" || "$branch" == "master" ]] && continue
        
        # Validate the branch name
        if sanitize_branch_name "$branch" true >/dev/null 2>&1; then
            validated_branches+=("$branch")
        else
            echo "WARNING: Skipping invalid branch name: $branch" >&2
        fi
    done <<< "$branch_list"
    
    printf '%s\n' "${validated_branches[@]}"
}
```

### Implementation Steps
1. Create input sanitization library
2. Add branch name validation with strict mode
3. Implement safe command execution wrappers
4. Update all scripts to use sanitized inputs

---

## Issue 10: Insufficient Validation Before Destructive Operations

### Problem
Auto-merge proceeds with minimal validation, risking incompatible code merges.

### Solution
```bash
# File: scripts/lib/merge_validator.sh

#!/bin/bash

# Comprehensive merge validation system
source "$(dirname "${BASH_SOURCE[0]}")/error_handling.sh"
source "$(dirname "${BASH_SOURCE[0]}")/input_sanitizer.sh"

readonly VALIDATION_CACHE=".branch-analysis/validation-cache"

# Initialize validation system
init_validation_system() {
    mkdir -p "$VALIDATION_CACHE"
}

# Pre-merge validation
validate_merge_safety() {
    local branch="$1"
    local base_branch="${2:-main}"
    local validation_level="${3:-standard}"  # minimal, standard, strict
    
    init_validation_system
    
    echo "🔍 Validating merge safety for: $branch"
    
    local validation_results=()
    local validation_passed=true
    
    # Level 1: Basic validation (always performed)
    if ! validate_branch_exists "$branch"; then
        validation_results+=("FAIL: Branch does not exist")
        validation_passed=false
    fi
    
    if ! validate_branch_accessible "$branch"; then
        validation_results+=("FAIL: Branch not accessible")
        validation_passed=false
    fi
    
    if validate_already_merged "$branch" "$base_branch"; then
        validation_results+=("INFO: Branch already merged")
        echo "✓ Branch already merged: $branch"
        return 0
    fi
    
    # Level 2: Standard validation
    if [[ "$validation_level" != "minimal" ]]; then
        if ! validate_no_conflicts "$branch" "$base_branch"; then
            validation_results+=("FAIL: Merge conflicts detected")
            validation_passed=false
        fi
        
        if ! validate_critical_files "$branch" "$base_branch"; then
            validation_results+=("FAIL: Critical file conflicts")
            validation_passed=false
        fi
        
        if ! validate_python_syntax "$branch"; then
            validation_results+=("FAIL: Python syntax errors")
            validation_passed=false
        fi
        
        if ! validate_no_large_files "$branch"; then
            validation_results+=("WARN: Large files detected")
        fi
    fi
    
    # Level 3: Strict validation
    if [[ "$validation_level" == "strict" ]]; then
        if ! validate_tests_pass "$branch"; then
            validation_results+=("FAIL: Tests do not pass")
            validation_passed=false
        fi
        
        if ! validate_code_quality "$branch"; then
            validation_results+=("WARN: Code quality issues")
        fi
        
        if ! validate_documentation "$branch"; then
            validation_results+=("WARN: Documentation incomplete")
        fi
        
        if ! validate_security_scan "$branch"; then
            validation_results+=("FAIL: Security vulnerabilities")
            validation_passed=false
        fi
    fi
    
    # Report results
    echo "Validation results for $branch:"
    for result in "${validation_results[@]}"; do
        echo "  $result"
    done
    
    if [[ "$validation_passed" == "true" ]]; then
        echo "✅ Merge validation passed for: $branch"
        cache_validation_result "$branch" "PASS" "${validation_results[*]}"
        return 0
    else
        echo "❌ Merge validation failed for: $branch"
        cache_validation_result "$branch" "FAIL" "${validation_results[*]}"
        return 1
    fi
}

# Individual validation functions
validate_branch_exists() {
    local branch="$1"
    git show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null
}

validate_branch_accessible() {
    local branch="$1"
    git log -1 "origin/$branch" >/dev/null 2>&1
}

validate_already_merged() {
    local branch="$1"
    local base_branch="$2"
    git merge-base --is-ancestor "origin/$branch" "$base_branch" 2>/dev/null
}

validate_no_conflicts() {
    local branch="$1"
    local base_branch="$2"
    
    # Use merge-tree to check for conflicts without actually merging
    local merge_result
    merge_result=$(git merge-tree "$base_branch" "origin/$branch" 2>/dev/null)
    
    # Check for conflict markers
    if echo "$merge_result" | grep -q "<<<<<<< "; then
        return 1
    fi
    
    return 0
}

validate_critical_files() {
    local branch="$1"
    local base_branch="$2"
    
    local critical_files=(
        "install.py"
        "openwebui_installer/cli.py"
        "openwebui_installer/installer.py"
        "pyproject.toml"
        "requirements.txt"
    )
    
    local changed_files
    changed_files=$(git diff --name-only "$base_branch"..."origin/$branch" 2>/dev/null)
    
    for critical_file in "${critical_files[@]}"; do
        if echo "$changed_files" | grep -q "^$critical_file$"; then
            # Check if this critical file has conflicts
            local file_merge_result
            file_merge_result=$(git merge-tree "$base_branch" "origin/$branch" -- "$critical_file" 2>/dev/null)
            
            if echo "$file_merge_result" | grep -q "<<<<<<< "; then
                echo "Critical file conflict: $critical_file"
                return 1
            fi
        fi
    done
    
    return 0
}

validate_python_syntax() {
    local branch="$1"
    local temp_dir=$(mktemp -d)
    register_temp_file "$temp_dir"
    
    # Create a temporary working tree
    git worktree add "$temp_dir" "origin/$branch" >/dev/null 2>&1 || return 1
    
    local syntax_errors=0
    
    # Check Python files in the temporary working tree
    while IFS= read -r -d '' py_file; do
        if ! python3 -m py_compile "$py_file" 2>/dev/null; then
            echo "Python syntax error in: ${py_file#$temp_dir/}"
            syntax_errors=$((syntax_errors + 1))
        fi
    done < <(find "$temp_dir" -name "*.py" -not -path "*/.git/*" -print0 2>/dev/null)
    
    # Cleanup
    git worktree remove "$temp_dir" >/dev/null 2>&1 || true
    
    return $([[ $syntax_errors -eq 0 ]])
}

validate_no_large_files() {
    local branch="$1"
    local max_size=$((10 * 1024 * 1024))  # 10MB
    
    local large_files
    large_files=$(git ls-tree -r --long "origin/$branch" | awk '$4 > '$max_size' {print $5}')
    
    if [[ -n "$large_files" ]]; then
        echo "Large files detected:"
        echo "$large_files"
        return 1
    fi
    
    return 0
}

validate_tests_pass() {
    local branch="$1"
    local temp_dir=$(mktemp -d)
    register_temp_file "$temp_dir"
    
    # Create temporary working tree
    git worktree add "$temp_dir" "origin/$branch" >/dev/null 2>&1 || return 1
    
    local test_result=0
    
    # Run tests if test directory exists
    if [[ -d "$temp_dir/tests" ]]; then
        (
            cd "$temp_dir"
            if [[ -f "requirements.txt" ]]; then
                python3 -m pip install -r requirements.txt >/dev/null 2>&1 || true
            fi
            
            # Run pytest if available
            if command -v pytest >/dev/null 2>&1; then
                pytest tests/ >/dev/null 2>&1
            else
                # Fallback to unittest
                python3 -m unittest discover tests >/dev/null 2>&1
            fi
        )
        test_result=$?
    fi
    
    # Cleanup
    git worktree remove "$temp_dir" >/dev/null 2>&1 || true
    
    return $test_result
}

validate_code_quality() {
    local branch="$1"
    local temp_dir=$(mktemp -d)
    register_temp_file "$temp_dir"
    
    git worktree add "$temp_dir" "origin/$branch" >/dev/null 2>&1 || return 1
    
    local quality_issues=0
    
    # Run flake8 if available
    if command -v flake8 >/dev/null 2>&1; then
        if ! flake8 "$temp_dir" --count --statistics >/dev/null 2>&1; then
            quality_issues=$((quality_issues + 1))
        fi
    fi
    
    # Check for TODO/FIXME comments in new code
    local todos
    todos=$(git diff main..."origin/$branch" | grep -E "^\+.*\b(TODO|FIXME|XXX)\b" | wc -l)
    if [[ $todos -gt 5 ]]; then
        quality_issues=$((quality_issues + 1))
    fi
    
    git worktree remove "$temp_dir" >/dev/null 2>&1 || true
    
    return $([[ $quality_issues -eq 0 ]])
}

validate_documentation() {
    local branch="$1"
    
    # Check if README changes are documented in CHANGELOG
    local readme_changed
    readme_changed=$(git diff --name-only main..."origin/$branch" | grep -q "README.md" && echo "true" || echo "false")
    
    if [[ "$readme_changed" == "true" ]]; then
        local changelog_updated
        changelog_updated=$(git diff --name-only main..."origin/$branch" | grep -q "CHANGELOG.md" && echo "true" || echo "false")
        
        if [[ "$changelog_updated" != "true" ]]; then
            echo "README changed but CHANGELOG not updated"
            return 1
        fi
    fi
    
    return 0
}

validate_security_scan() {
    local branch="$1"
    local temp_dir=$(mktemp -d)
    register_temp_file "$temp_dir"
    
    git worktree add "$temp_dir" "origin/$branch" >/dev/null 2>&1 || return 1
    
    local security_issues=0

    # Example: Check for common security vulnerabilities (placeholder)
    # This would typically involve running static analysis tools like bandit for Python,
    # or linters for other languages, or even a basic secret scanner.
    if command -v bandit >/dev/null 2>&1; then
        if ! bandit -q -r \"$temp_dir\" >/dev/null 2>&1; then
            echo \"Bandit security issues detected\"
            security_issues=$((security_issues + 1))
        fi
    fi
    
    # Check for exposed API keys (simple grep example)
    local exposed_secrets=$(grep -rE \'(API_KEY|SECRET_KEY|PASSWORD|TOKEN)=\'[[:alnum:]]{16,}\' \"$temp_dir\" | wc -l)
    if [[ $exposed_secrets -gt 0 ]]; then
        echo \"Potential secrets exposed: $exposed_secrets instances\"
        security_issues=$((security_issues + 1))
    fi

    git worktree remove \"$temp_dir\" >/dev/null 2>&1 || true
    
    return $([[ $security_issues -eq 0 ]])
}\n
# Cache validation result
cache_validation_result() {\
    local branch=\"$1\"\
    local status=\"$2\"\
    local details=\"$3\"\
    local cache_file=\"$VALIDATION_CACHE/${branch//\\//_}.json\"\
    local timestamp=$(iso_timestamp)\
    
    cat > \"$cache_file\" << EOF\n{\
      \"branch\": \"$branch\",\
      \"timestamp\": \"$timestamp\",\
      \"status\": \"$status\",\
      \"details\": \"$details\"\
    }\nEOF\
}\n
# Read cached validation result
read_cached_validation_result() {\
    local branch=\"$1\"\
    local cache_file=\"$VALIDATION_CACHE/${branch//\\//_}.json\"\
    
    if [[ -f \"$cache_file\" ]]; then\
        cat \"$cache_file\"\
    else\
        echo \"{}\" # Return empty JSON if not found\
    fi\
}\n
```

### Implementation Steps
1. Create comprehensive validation engine with configurable levels
2. Implement syntax, import, and conflict validation
3. Add test execution and integration validation
4. Update merge scripts to use validation engine

---\n

---

## Issue 3: Concurrency & Lock Management

### Problem
No locking mechanism to prevent concurrent executions causing Git state conflicts.

### Solution
```bash
# File: scripts/lib/lock_manager.sh

#!/bin/bash

# Lock management for branch analysis scripts
readonly LOCK_DIR=".branch-analysis/locks"
readonly LOCK_TIMEOUT=1800  # 30 minutes

# Create lock directory
init_lock_system() {
    mkdir -p "$LOCK_DIR"
}

# Acquire lock
acquire_lock() {
    local lock_name="$1"
    local lock_file="$LOCK_DIR/$lock_name.lock"
    local timeout=${2:-$LOCK_TIMEOUT}
    local wait_time=0
    
    init_lock_system
    
    # Check for existing lock
    while [[ -f "$lock_file" ]]; do
        local lock_pid=$(cat "$lock_file" 2>/dev/null || echo "")
        local lock_time=$(stat -c %Y "$lock_file" 2>/dev/null || echo "0")
        local current_time=$(date +%s)
        local age=$((current_time - lock_time))
        
        # Check if process is still running
        if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
            if [[ $age -gt $timeout ]]; then
                echo "Lock timeout exceeded, removing stale lock"
                rm -f "$lock_file"
                break
            fi
            
            if [[ $wait_time -ge 300 ]]; then  # 5 minutes
                echo "ERROR: Lock held by process $lock_pid for ${age}s (max wait reached)"
                return 1
            fi
            
            echo "Waiting for lock (held by process $lock_pid for ${age}s)..."
            sleep 10
            wait_time=$((wait_time + 10))
        else
            echo "Removing stale lock (process $lock_pid no longer running)"
            rm -f "$lock_file"
            break
        fi
    done
    
    # Create lock
    echo $$ > "$lock_file"
    
    # Verify lock
    if [[ "$(cat "$lock_file")" == "$$" ]]; then
        echo "Lock acquired: $lock_name"
        return 0
    else
        echo "Failed to acquire lock: $lock_name"
        return 1
    fi
}

# Release lock
release_lock() {
    local lock_name="$1"
    local lock_file="$LOCK_DIR/$lock_name.lock"
    
    if [[ -f "$lock_file" ]]; then
        local lock_pid=$(cat "$lock_file" 2>/dev/null || echo "")
        if [[ "$lock_pid" == "$$" ]]; then
            rm -f "$lock_file"
            echo "Lock released: $lock_name"
        else
            echo "WARNING: Lock not owned by current process"
        fi
    fi
}

# Auto-release lock on exit
auto_release_lock() {
    local lock_name="$1"
    trap "release_lock '$lock_name'" EXIT
}
```

### Implementation Steps
1. Create lock management system
2. Add locks to all main scripts
3. Implement timeout and stale lock cleanup
4. Add lock status monitoring

---

## Issue 4: Dependency Validation

### Problem
Scripts assume tools are available without validation, causing silent failures.

### Solution
```bash
# File: scripts/lib/dependency_checker.sh

#!/bin/bash

# Dependency validation for branch analysis scripts
source "$(dirname "${BASH_SOURCE[0]}")/error_handling.sh"

# Required tools with versions
declare -A REQUIRED_TOOLS=(
    ["git"]="2.0.0"
    ["python3"]="3.7.0"
    ["bash"]="4.0.0"
)

# Optional tools
declare -A OPTIONAL_TOOLS=(
    ["xcrun"]=""
    ["docker"]=""
    ["podman"]=""
)

# Version comparison function
version_ge() {
    local version1="$1"
    local version2="$2"
    
    # Simple version comparison (works for most cases)
    printf '%s\n%s\n' "$version2" "$version1" | sort -V | head -n1 | grep -q "^$version2$"
}

# Check single tool
check_tool() {
    local tool="$1"
    local required_version="$2"
    local optional="${3:-false}"
    
    if ! command -v "$tool" >/dev/null 2>&1; then
        if [[ "$optional" == "false" ]]; then
            handle_error $E_DEPENDENCY_ERROR "Required tool not found: $tool" $LINENO "${FUNCNAME[1]}"
        else
            echo "Optional tool not available: $tool"
            return 1
        fi
    fi
    
    # Check version if specified
    if [[ -n "$required_version" ]]; then
        local current_version
        case "$tool" in
            "git")
                current_version=$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
                ;;
            "python3")
                current_version=$(python3 --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
                ;;
            "bash")
                current_version=${BASH_VERSION%%.*}
                ;;
            *)
                echo "Version check not implemented for: $tool"
                return 0
                ;;
        esac
        
        if [[ -n "$current_version" ]] && ! version_ge "$current_version" "$required_version"; then
            if [[ "$optional" == "false" ]]; then
                handle_error $E_DEPENDENCY_ERROR "Tool $tool version $current_version < required $required_version" $LINENO "${FUNCNAME[1]}"
            else
                echo "Optional tool $tool version $current_version < recommended $required_version"
                return 1
            fi
        fi
    fi
    
    echo "✓ $tool available" $(if [[ -n "${current_version:-}" ]]; then echo "(version $current_version)"; fi)
    return 0
}

# Check all dependencies
check_dependencies() {
    local fail_fast=${1:-true}
    local failed_tools=()
    
    echo "🔍 Checking dependencies..."
    
    # Check required tools
    for tool in "${!REQUIRED_TOOLS[@]}"; do
        if ! check_tool "$tool" "${REQUIRED_TOOLS[$tool]}" false; then
            failed_tools+=("$tool")
            if [[ "$fail_fast" == "true" ]]; then
                return 1
            fi
        fi
    done
    
    # Check optional tools
    for tool in "${!OPTIONAL_TOOLS[@]}"; do
        check_tool "$tool" "${OPTIONAL_TOOLS[$tool]}" true || true
    done
    
    # Git-specific checks
    check_git_config
    
    if [[ ${#failed_tools[@]} -gt 0 ]]; then
        handle_error $E_DEPENDENCY_ERROR "Failed dependency checks: ${failed_tools[*]}" $LINENO "${FUNCNAME[0]}"
    fi
    
    echo "✅ All required dependencies available"
}

# Check Git configuration
check_git_config() {
    echo "🔍 Checking Git configuration..."
    
    # Check if we're in a Git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        handle_error $E_GIT_ERROR "Not in a Git repository" $LINENO "${FUNCNAME[0]}"
    fi
    
    # Check for basic Git config
    if ! git config user.name >/dev/null 2>&1; then
        echo "WARNING: Git user.name not configured"
    fi
    
    if ! git config user.email >/dev/null 2>&1; then
        echo "WARNING: Git user.email not configured"
    fi
    
    # Check remote access
    if ! git ls-remote origin HEAD >/dev/null 2>&1; then
        echo "WARNING: Cannot access Git remote 'origin'"
    fi
    
    echo "✓ Git configuration OK"
}

# Python-specific checks
check_python_environment() {
    echo "🔍 Checking Python environment..."
    
    # Check for virtual environment
    if [[ -n "${VIRTUAL_ENV:-}" ]]; then
        echo "✓ Virtual environment active: $VIRTUAL_ENV"
    else
        echo "WARNING: No virtual environment detected"
    fi
    
    # Check critical Python modules
    local required_modules=("sys" "os" "subprocess" "argparse")
    for module in "${required_modules[@]}"; do
        if ! python3 -c "import $module" 2>/dev/null; then
            handle_error $E_DEPENDENCY_ERROR "Python module not available: $module" $LINENO "${FUNCNAME[0]}"
        fi
    done
    
    echo "✓ Python environment OK"
}
```

### Implementation Steps
1. Create comprehensive dependency checker
2. Add version validation for critical tools
3. Implement environment validation
4. Add dependency installation guides

---

## Issue 5: Inefficient Git Operations

### Problem
Multiple redundant `git fetch --all` and `git remote update` calls slow down execution.

### Solution
```bash
# File: scripts/lib/git_cache.sh

#!/bin/bash

# Git operation caching and optimization
source "$(dirname "${BASH_SOURCE[0]}")/error_handling.sh"

readonly GIT_CACHE_DIR=".branch-analysis/git-cache"
readonly CACHE_EXPIRY=300  # 5 minutes

# Initialize cache
init_git_cache() {
    mkdir -p "$GIT_CACHE_DIR"
}

# Check if cache is valid
is_cache_valid() {
    local cache_file="$1"
    local max_age="${2:-$CACHE_EXPIRY}"
    
    if [[ ! -f "$cache_file" ]]; then
        return 1
    fi
    
    local file_age=$(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0) ))
    [[ $file_age -lt $max_age ]]
}

# Cached remote update
cached_remote_update() {
    local force_update=${1:-false}
    local cache_file="$GIT_CACHE_DIR/remote_update.cache"
    
    init_git_cache
    
    if [[ "$force_update" == "true" ]] || ! is_cache_valid "$cache_file"; then
        echo "🔄 Updating remote references..."
        if safe_network_operation "git remote update origin --prune"; then
            touch "$cache_file"
            echo "✓ Remote references updated"
        else
            echo "WARNING: Failed to update remote references"
            return 1
        fi
    else
        echo "✓ Using cached remote references"
    fi
}

# Cached branch list
get_cached_branches() {
    local branch_type="$1"  # "remote" or "local"
    local cache_file="$GIT_CACHE_DIR/${branch_type}_branches.cache"
    
    init_git_cache
    
    if ! is_cache_valid "$cache_file"; then
        case "$branch_type" in
            "remote")
                safe_git branch -r | grep -v HEAD | sed 's/origin\///' | sed 's/^[[:space:]]*//' | sort > "$cache_file"
                ;;
            "local")
                safe_git branch | sed 's/^[[:space:]]*//' | sed 's/^\*//' | sed 's/^[[:space:]]*//' | sort > "$cache_file"
                ;;
        esac
    fi
    
    cat "$cache_file"
}

# Cached merge base check
get_cached_merge_base() {
    local branch1="$1"
    local branch2="$2"
    local cache_file="$GIT_CACHE_DIR/merge_base_${branch1//\//_}_${branch2//\//_}.cache"
    
    init_git_cache
    
    if ! is_cache_valid "$cache_file" 86400; then  # 24 hour cache for merge bases
        if safe_git merge-base "$branch1" "$branch2" > "$cache_file" 2>/dev/null; then
            echo "Merge base cached for $branch1..$branch2"
        else
            echo "no-merge-base" > "$cache_file"
        fi
    fi
    
    local result=$(cat "$cache_file")
    if [[ "$result" == "no-merge-base" ]]; then
        return 1
    else
        echo "$result"
    fi
}

# Batch Git operations
batch_git_operations() {
    local operations=("$@")
    local temp_script=$(mktemp)
    register_temp_file "$temp_script"
    
    echo "#!/bin/bash" > "$temp_script"
    echo "set -euo pipefail" >> "$temp_script"
    
    for op in "${operations[@]}"; do
        echo "git $op" >> "$temp_script"
    done
    
    chmod +x "$temp_script"
    bash "$temp_script"
}

# Clear cache
clear_git_cache() {
    rm -rf "$GIT_CACHE_DIR"
    echo "Git cache cleared"
}
```

### Implementation Steps
1. Implement Git operation caching
2. Add batch operation support
3. Update scripts to use cached operations
4. Add cache management commands

---

## Issue 6: Sequential Branch Processing

### Problem
Branch analysis processes one branch at a time, making large repositories slow to analyze.

### Solution
```bash
# File: scripts/lib/parallel_processor.sh

#!/bin/bash

# Parallel processing for branch analysis
source "$(dirname "${BASH_SOURCE[0]}")/error_handling.sh"

readonly MAX_PARALLEL_JOBS=8
readonly PARALLEL_WORK_DIR=".branch-analysis/parallel"

# Initialize parallel processing
init_parallel_processing() {
    mkdir -p "$PARALLEL_WORK_DIR"
    rm -f "$PARALLEL_WORK_DIR"/*.{lock,result,error} 2>/dev/null || true
}

# Process branches in parallel
process_branches_parallel() {
    local branches=("$@")
    local total_branches=${#branches[@]}
    local jobs_running=0
    local completed=0
    local failed=0
    
    echo "🚀 Processing $total_branches branches in parallel (max $MAX_PARALLEL_JOBS jobs)"
    
    init_parallel_processing
    
    # Create job queue
    local job_queue=()
    for branch in "${branches[@]}"; do
        job_queue+=("$branch")
    done
    
    # Process jobs
    while [[ ${#job_queue[@]} -gt 0 ]] || [[ $jobs_running -gt 0 ]]; do
        # Start new jobs if queue not empty and under limit
        while [[ ${#job_queue[@]} -gt 0 ]] && [[ $jobs_running -lt $MAX_PARALLEL_JOBS ]]; do
            local branch="${job_queue[0]}"
            job_queue=("${job_queue[@]:1}")  # Remove first element
            
            start_branch_analysis_job "$branch" &
            jobs_running=$((jobs_running + 1))
        done
        
        # Check for completed jobs
        local new_jobs_running=0
        for job_pid in $(jobs -p); do
            if kill -0 "$job_pid" 2>/dev/null; then
                new_jobs_running=$((new_jobs_running + 1))
            else
                # Job completed, check result
                wait "$job_pid"
                local exit_code=$?
                if [[ $exit_code -eq 0 ]]; then
                    completed=$((completed + 1))
                else
                    failed=$((failed + 1))
                fi
                
                # Update progress
                local total_processed=$((completed + failed))
                echo "Progress: $total_processed/$total_branches (✓$completed ✗$failed)"
            fi
        done
        jobs_running=$new_jobs_running
        
        # Brief pause to prevent busy waiting
        sleep 0.5
    done
    
    echo "🏁 Parallel processing complete: $completed succeeded, $failed failed"
    
    # Collect results
    collect_parallel_results
}

# Start individual branch analysis job
start_branch_analysis_job() {
    local branch="$1"
    local job_id="${branch//\//_}"
    local result_file="$PARALLEL_WORK_DIR/${job_id}.result"
    local error_file="$PARALLEL_WORK_DIR/${job_id}.error"
    
    {
        # Individual branch analysis logic
        analyze_single_branch "$branch" > "$result_file" 2> "$error_file"
    } || {
        echo "FAILED: $branch" > "$error_file"
        return 1
    }
}

# Analyze single branch (to be called by parallel jobs)
analyze_single_branch() {
    local branch="$1"
    
    # This function should contain the core branch analysis logic
    # extracted from the main script, made thread-safe
    
    # Check if branch exists
    if ! git show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null; then
        echo "ERROR: Branch not found: $branch"
        return 1
    fi
    
    # Get changed files (using cached operations)
    local changed_files
    changed_files=$(git diff --name-only main..."origin/$branch" 2>/dev/null || echo "")
    
    # Calculate conflict potential
    local conflict_potential=0
    if git merge-tree main "origin/$branch" >/dev/null 2>&1; then
        conflict_output=$(git merge-tree main "origin/$branch" 2>/dev/null || echo "")
        conflict_potential=$(echo "$conflict_output" | grep -c "<<<<<<< " || echo "0")
    fi
    
    # Analyze critical files
    local critical_files=(
        "install.py"
        "openwebui_installer/cli.py"
        "openwebui_installer/installer.py"
        "openwebui_installer/gui.py"
        "README.md"
        "pyproject.toml"
    )
    
    local critical_impact=0
    local affected_critical=()
    
    for file in "${critical_files[@]}"; do
        if echo "$changed_files" | grep -q "^$file$"; then
            critical_impact=$((critical_impact + 1))
            affected_critical+=("$file")
        fi
    done
    
    # Output results in structured format
    echo "BRANCH:$branch"
    echo "CHANGED_FILES:$(echo "$changed_files" | wc -w)"
    echo "CRITICAL_IMPACT:$critical_impact"
    echo "CONFLICT_POTENTIAL:$conflict_potential"
    echo "AFFECTED_FILES:${affected_critical[*]}"
    
    # Determine strategy
    if [[ $critical_impact -eq 0 ]]; then
        echo "STRATEGY:AUTO_MERGE"
        echo "PRIORITY:LOW"
    elif [[ $critical_impact -le 2 && $conflict_potential -eq 0 ]]; then
        echo "STRATEGY:GUIDED_MERGE"
        echo "PRIORITY:MEDIUM"
    else
        echo "STRATEGY:MANUAL_MERGE"
        echo "PRIORITY:HIGH"
    fi
}

# Collect and merge parallel results
collect_parallel_results() {
    local auto_merge=()
    local guided_merge=()
    local manual_merge=()
    
    echo "📊 Collecting parallel results..."
    
    for result_file in "$PARALLEL_WORK_DIR"/*.result; do
        [[ -f "$result_file" ]] || continue
        
        local branch=""
        local strategy=""
        local priority=""
        
        while IFS=':' read -r key value; do
            case "$key" in
                "BRANCH") branch="$value" ;;
                "STRATEGY") strategy="$value" ;;
                "PRIORITY") priority="$value" ;;
            esac
        done < "$result_file"
        
        case "$strategy" in
            "AUTO_MERGE") auto_merge+=("$branch|$priority") ;;
            "GUIDED_MERGE") guided_merge+=("$branch|$priority") ;;
            "MANUAL_MERGE") manual_merge+=("$branch|$priority") ;;
        esac
    done
    
    # Write consolidated results
    echo "# Auto-merge candidates" > .branch-analysis/merge_candidates.txt
    for branch_info in "${auto_merge[@]}"; do
        echo "${branch_info%|*}" >> .branch-analysis/merge_candidates.txt
    done
    
    echo "Auto-merge candidates: ${#auto_merge[@]}"
    echo "Guided merge required: ${#guided_merge[@]}"
    echo "Manual resolution required: ${#manual_merge[@]}"
}
```

### Implementation Steps
1. Create parallel processing framework
2. Extract thread-safe analysis functions
3. Implement job queue and progress tracking
4. Update main script to use parallel processing

---

## Issue 7: Redundant File I/O

### Problem
Multiple scripts read/write similar analysis files inefficiently.

### Solution
```bash
# File: scripts/lib/data_manager.sh

#!/bin/bash

# Centralized data management for branch analysis
source "$(dirname "${BASH_SOURCE[0]}")/error_handling.sh"

readonly DATA_VERSION="1.0"
readonly ANALYSIS_SCHEMA=".branch-analysis/schema.json"

# Data structure definitions
init_data_structures() {
    cat > "$ANALYSIS_SCHEMA" << 'EOF'
{
  "version": "1.0",
  "timestamp": "",
  "branches": {
    "branch_name": {
      "analysis": {
        "changed_files": [],
        "critical_impact": 0,
        "conflict_potential": 0,
        "affected_critical": [],
        "strategy": "",
        "priority": "",
        "relevance": ""
      },
      "metadata": {
        "last_commit": "",
        "author": "",
        "commit_date": "",
        "merge_base": ""
      },
      "status": {
        "exists": true,
        "merged": false,
        "stale": false,
        "safe_to_delete": false
      }
    }
  },
  "summary": {
    "total_branches": 0,
    "auto_merge": 0,
    "guided_merge": 0,
    "manual_merge": 0,
    "critical_branches": 0
  }
}
EOF
}

# Load analysis data
load_analysis_data() {
    local data_file=".branch-analysis/analysis_data.json"
    
    if [[ -f "$data_file" ]]; then
        # Validate version compatibility
        local file_version
        file_version=$(jq -r '.version' "$data_file" 2>/dev/null || echo "unknown")
        
        if [[ "$file_version" != "$DATA_VERSION" ]]; then
            echo "Data version mismatch, regenerating..."
            init_analysis_data
        else
            echo "✓ Loaded existing analysis data"
        fi
    else
        init_analysis_data
    fi
}

# Initialize new analysis data
init_analysis_data() {
    local data_file=".branch-analysis/analysis_data.json"
    
    mkdir -p .branch-analysis
    
    cat > "$data_file" << EOF
{
  "version": "$DATA_VERSION",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "branches": {},
  "summary": {
    "total_branches": 0,
    "auto_merge": 0,
    "guided_merge": 0,
    "manual_merge": 0,
    "critical_branches": 0
  }
}
EOF
    
    echo "✓ Initialized new analysis data"
}

# Update branch data
update_branch_data() {
    local branch="$1"
    local field="$2"
    local value="$3"
    local data_file=".branch-analysis/analysis_data.json"
    
    # Ensure data file exists
    [[ -f "$data_file" ]] || init_analysis_data
    
    # Create branch entry if it doesn't exist
    if ! jq -e ".branches[\"$branch\"]" "$data_file" >/dev/null 2>&1; then
        local temp_file=$(mktemp)
        register_temp_file "$temp_file"
        
        jq ".branches[\"$branch\"] = {
            \"analysis\": {
                \"changed_files\": [],
                \"critical_impact\": 0,
                \"conflict_potential\": 0,
                \"affected_critical\": [],
                \"strategy\": \"\",
                \"priority\": \"\",
                \"relevance\": \"\"
            },
            \"metadata\": {
                \"last_commit\": \"\",
                \"author\": \"\",
                \"commit_date\": \"\",
                \"merge_base\": \"\"
            },
            \"status\": {
                \"exists\": true,
                \"merged\": false,
                \"stale\": false,
                \"safe_to_delete\": false
            }
        }" "$data_file" > "$temp_file" && mv "$temp_file" "$data_file"
    fi
    
    # Update specific field
    local temp_file=$(mktemp)
    register_temp_file "$temp_file"
    
    jq ".branches[\"$branch\"].$field = \"$value\"" "$data_file" > "$temp_file" && mv "$temp_file" "$data_file"
}

# Get branch data
get_branch_data() {
    local branch="$1"
    local field="$2"
    local data_file=".branch-analysis/analysis_data.json"
    
    if [[ -f "$data_file" ]]; then
        jq -r ".branches[\"$branch\"].$field // \"\"" "$data_file" 2>/dev/null || echo ""
    fi
}

# Bulk update summary
update_summary() {
    local data_file=".branch-analysis/analysis_data.json"
    local temp_file=$(mktemp)
    register_temp_file "$temp_file"
    
    # Count different categories
    local auto_merge_count=$(jq '[.branches[] | select(.analysis.strategy == "AUTO_MERGE")] | length' "$data_file")
    local guided_merge_count=$(jq '[.branches[] | select(.analysis.strategy == "GUIDED_MERGE")] | length' "$data_file")
    local manual_merge_count=$(jq '[.branches[] | select(.analysis.strategy == "MANUAL_MERGE")] | length' "$data_file")
    local critical_count=$(jq '[.branches[] | select(.analysis.relevance == "CRITICAL")] | length' "$data_file")
    local total_count=$(jq '.branches | length' "$data_file")
    
    jq ".summary = {
        \"total_branches\": $total_count,
        \"auto_merge\": $auto_merge_count,
        \"guided_merge\": $guided_merge_count,
        \"manual_merge\": $manual_merge_count,
        \"critical_branches\": $critical_count,
        \"last_updated\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
    }" "$data_file" > "$temp_file" && mv "$temp_file" "$data_file"
}

# Export data to legacy format
export_legacy_format() {
    local data_file=".branch-analysis/analysis_data.json"
    
    # Export merge candidates
    jq -r '.branches[] | select(.analysis.strategy == "AUTO_MERGE") | .analysis.branch_name' "$data_file" > .branch-analysis/merge_candidates.txt
    
    # Export critical branches
    jq -r '.branches[] | select(.analysis.relevance == "CRITICAL") | .analysis.branch_name' "$data_file" > .branch-analysis/critical_branches.txt
    
    echo "✓ Exported data to legacy format"
}
```

### Implementation Steps
1. Create centralized data management system
2. Implement JSON-based data storage with schema validation
3. Add incremental update capabilities
4. Migrate existing scripts to use centralized data

---

## Issue 8: Backup Strategy Limitations

### Problem
Only creates single backup branch before auto-merge with no rollback mechanism for complex merge sequences.

### Solution
```bash
# File: scripts/lib/backup_manager.sh

#!/bin/bash

# Comprehensive backup management for branch operations
source "$(dirname "${BASH_SOURCE[0]}")/error_handling.sh"
source "$(dirname "${BASH_SOURCE[0]}")/resource_manager.sh"

readonly BACKUP_DIR=".branch-analysis/backups"
readonly MAX_BACKUPS=10

# Initialize backup system
init_backup_system() {
    mkdir -p "$BACKUP_DIR"
    
    # Create backup index if it doesn't exist
    if [[ ! -f "$BACKUP_DIR/backup_index.json" ]]; then
        cat > "$BACKUP_DIR/backup_index.json" << 'EOF'
{
    "backups": [],
    "active_backup": null,
    "created": ""
}
EOF
    fi
}

# Create comprehensive backup
create_backup() {
    local backup_name="${1:-auto-backup-$(date +%Y%m%d_%H%M%S)}"
    local description="${2:-Automatic backup before merge operations}"
    
    init_backup_system
    
    echo "🔒 Creating backup: $backup_name"
    
    local backup_id="backup_$(date +%Y%m%d_%H%M%S)"
    local backup_path="$BACKUP_DIR/$backup_id"
    
    mkdir -p "$backup_path"
    
    # Get current state
    local current_branch=$(git branch --show-current)
    local current_commit=$(git rev-parse HEAD)
    local current_status=$(git status --porcelain)
    
    # Create backup metadata
    cat > "$backup_path/metadata.json" << EOF
{
    "backup_id": "$backup_id",
    "name": "$backup_name",
    "description": "$description",
    "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "branch": "$current_branch",
    "commit": "$current_commit",
    "has_uncommitted_changes": $(if [[ -n "$current_status" ]]; then echo "true"; else echo "false"; fi)
}
EOF
    
    # Create branch backup
    local backup_branch="backup/${backup_id}"
    git branch "$backup_branch" HEAD
    register_branch "$backup_branch"
    
    # Save uncommitted changes if any
    if [[ -n "$current_status" ]]; then
        echo "💾 Saving uncommitted changes..."
        git stash push -m "Backup stash for $backup_id" --include-untracked
        echo "$(git stash list | head -1 | cut -d: -f1)" > "$backup_path/stash_ref.txt"
    fi
    
    # Save branch state
    git branch -a > "$backup_path/branches.txt"
    git log --oneline -10 > "$backup_path/recent_commits.txt"
    
    # Update backup index
    local temp_file=$(mktemp)
    register_temp_file "$temp_file"
    
    jq ".backups += [{
        \"id\": \"$backup_id\",
        \"name\": \"$backup_name\",
        \"description\": \"$description\",
        \"created\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
        \"branch\": \"$current_branch\",
        \"commit\": \"$current_commit\"
    }] | .active_backup = \"$backup_id\"" "$BACKUP_DIR/backup_index.json" > "$temp_file"
    
    mv "$temp_file" "$BACKUP_DIR/backup_index.json"
    
    # Cleanup old backups
    cleanup_old_backups
    
    echo "✅ Backup created: $backup_id"
    echo "   Branch: $backup_branch"
    echo "   Path: $backup_path"
    
    echo "$backup_id"
}

# Restore from backup
restore_backup() {
    local backup_id="$1"
    local force_restore=${2:-false}
    
    init_backup_system
    
    local backup_path="$BACKUP_DIR/$backup_id"
    
    if [[ ! -d "$backup_path" ]]; then
        handle_error $E_GIT_ERROR "Backup not found: $backup_id" $LINENO "${FUNCNAME[0]}"
    fi
    
    echo "🔄 Restoring backup: $backup_id"
    
    # Load backup metadata
    local backup_branch=$(jq -r '.branch' "$backup_path/metadata.json")
    local backup_commit=$(jq -r '.commit' "$backup_path/metadata.json")
    local has_stash=$(jq -r '.has_uncommitted_changes' "$backup_path/metadata.json")
    
    # Confirm restoration if not forced
    if [[ "$force_restore" != "true" ]]; then
        echo "This will restore to:"
        echo "  Branch: $backup_branch"
        echo "  Commit: $backup_commit"
        echo "  Timestamp: $(jq -r '.created' "$backup_path/metadata.json")"
        echo ""
        read -p "Continue with restoration? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Restoration cancelled"
            return 1
        fi
    fi
    
    # Save current state before restore
    local pre_restore_backup
    pre_restore_backup=$(create_backup "pre-restore-$(date +%Y%m%d_%H%M%S)" "Backup before restoring $backup_id")
    
    # Restore branch state
    git checkout "$backup_branch" 2>/dev/null || {
        # If backup branch doesn't exist, checkout the commit directly
        git checkout "$backup_commit"
        git checkout -b "$backup_branch"
    }
    
    # Restore stashed changes if they exist
    if [[ "$has_stash" == "true" ]] && [[ -f "$backup_path/stash_ref.txt" ]]; then
        local stash_ref=$(cat "$backup_path/stash_ref.txt")
        if git stash list | grep -q "$stash_ref"; then
            echo "🔄 Restoring uncommitted changes..."
            git stash pop "$stash_ref" || echo "Warning: Could not restore stashed changes"
        fi
    fi
    
    echo "✅ Backup restored: $backup_id"
    echo "   Pre-restore backup created: $pre_restore_backup"
}

# List available backups
list_backups() {
    init_backup_system
    
    echo "📋 Available Backups"
    echo "===================="
    
    local backups=$(jq -r '.backups[] | "\(.id)|\(.name)|\(.created)|\(.branch)"' "$BACKUP_DIR/backup_index.json")
    
    if [[ -z "$backups" ]]; then
        echo "No backups found"
        return
    fi
    
    printf "%-25s %-30s %-20s %-15s\n" "ID" "NAME" "CREATED" "BRANCH"
    printf "%-25s %-30s %-20s %-15s\n" "----" "----" "-------" "------"
    
    while IFS='|' read -r id name created branch; do
        printf "%-25s %-30s %-20s %-15s\n" "$id" "$name" "$created" "$branch"
    done <<< "$backups"
    
    echo ""
    local active_backup=$(jq -r '.active_backup' "$BACKUP_DIR/backup_index.json")
    if [[ "$active_backup" != "null" ]]; then
        echo "Active backup: $active_backup"
    fi
}

# Cleanup old backups
cleanup_old_backups() {
    local backup_count=$(jq '.backups | length' "$BACKUP_DIR/backup_index.json")
    
    if [[ $backup_count -gt $MAX_BACKUPS ]]; then
        echo "🧹 Cleaning up old backups (keeping $MAX_BACKUPS)..."
        
        # Get old backup IDs
        local old_backups=($(jq -r ".backups | sort_by(.created) | .[0:$((backup_count - MAX_BACKUPS))] | .[].id" "$BACKUP_DIR/backup_index.json"))
        
        for backup_id in "${old_backups[@]}"; do
            echo "  Removing backup: $backup_id"
            rm -rf "$BACKUP_DIR/$backup_id"
            
            # Remove backup branch if it exists
            local backup_branch="backup/$backup_id"
            if git show-ref --verify --quiet "refs/heads/$backup_branch" 2>/dev/null; then
                git branch -D "$backup_branch" 2>/dev/null || true
            fi
        done
        
        # Update index
        local temp_file=$(mktemp)
        register_temp_file "$temp_file"
        
        jq ".backups = (.backups | sort_by(.created) | .[$((backup_count - MAX_BACKUPS)):])" "$BACKUP_DIR/backup_index.json" > "$temp_file"
        mv "$temp_file" "$BACKUP_DIR/backup_index.json"
    fi
}

# Verify backup integrity
verify_backup() {
    local backup_id="$1"
    local backup_path="$BACKUP_DIR/$backup_id"
    
    if [[ ! -d "$backup_path" ]]; then
        echo "❌ Backup directory not found: $backup_id"
        return 1
    fi
    
    if [[ ! -f "$backup_path/metadata.json" ]]; then
        echo "❌ Backup metadata missing: $backup_id"
        return 1
    fi
    
    local backup_branch="backup/$backup_id"
    if ! git show-ref --verify --quiet "refs/heads/$backup_branch" 2>/dev/null; then
        echo "❌ Backup branch missing: $backup_branch"
        return 1
    fi
    
    echo "✅ Backup verification passed: $backup_id"
    return 0
}
```

### Implementation Steps
1. Create comprehensive backup system with metadata
2. Implement rollback mechanisms for complex operations
3. Add backup verification and integrity checks
4. Integrate with all merge operations

---

## Issue 9: Branch Name Injection

### Problem
Branch names used directly in shell commands without sanitization, creating potential security vulnerabilities.

### Solution
```bash
# File: scripts/lib/security_utils.sh

#!/bin/bash

# Security utilities for branch analysis scripts
source "$(dirname "${BASH_SOURCE[0]}")/error_handling.sh"

# Sanitize branch name for shell usage
sanitize_branch_name() {
    local branch_name="$1"
    
    # Remove dangerous characters and patterns
    local sanitized=$(echo "$branch_name" | sed 's/[;&|`$(){}[\]\\]//g')
    
    # Validate branch name format
    if ! validate_branch_name "$sanitized"; then
        handle_error $E_GIT_ERROR "Invalid branch name format: $branch_name" $LINENO "${FUNCNAME[1]}"
    fi
    
    echo "$sanitized"
}

# Validate branch name against Git naming rules
validate_branch_name() {
    local branch_name="$1"
    
    # Git branch naming rules
    if [[ -z "$branch_name" ]]; then
        return 1
    fi
    
    # Cannot start or end with /
    if [[ "$branch_name" =~ ^/ ]] || [[ "$branch_name" =~ /$ ]]; then
        return 1
    fi
    
    # Cannot contain consecutive slashes
    if [[ "$branch_name" =~ // ]]; then
        return 1
    fi
    
    # Cannot contain dangerous characters
    if [[ "$branch_name" =~ [[:space:]\~\^:\?\*\[\]] ]]; then
        return 1
    fi
    
    # Cannot be . or ..
    if [[ "$branch_name" == "." ]] || [[ "$branch_name" == ".." ]]; then
        return 1
    fi
    
    # Cannot contain control characters
    if [[ "$branch_name" =~ $'\001'-$'\037' ]]; then
        return 1
    fi
    
    return 0
}

# Safe Git command execution with branch name validation
safe_git_with_branch() {
    local git_command="$1"
    local branch_name="$2"
    shift 2
    local additional_args=("$@")
    
    # Sanitize branch name
    local safe_branch
    safe_branch=$(sanitize_branch_name "$branch_name")
    
    # Execute git command with sanitized branch name
    safe_git "$git_command" "$safe_branch" "${additional_args[@]}"
}

# Escape branch name for use in regex patterns
escape_branch_for_regex() {
    local branch_name="$1"
    
    # Escape special regex characters
    echo "$branch_name" | sed 's/[[\.*^$()+?{|]/\\&/g'
}

# Validate file path to prevent directory traversal
validate_file_path() {
    local file_path="$1"
    local base_dir="${2:-.}"
    
    # Resolve path and check if it's within base directory
    local resolved_path
    resolved_path=$(realpath "$file_path" 2>/dev/null || echo "$file_path")
    local resolved_base
    resolved_base=$(realpath "$base_dir" 2>/dev/null || echo "$base_dir")
    
    # Check if resolved path starts with base directory
    if [[ "$resolved_path" != "$resolved_base"* ]]; then
        handle_error $E_PERMISSION_ERROR "Path traversal attempt detected: $file_path" $LINENO "${FUNCNAME[1]}"
    fi
    
    echo "$resolved_path"
}

# Safe file operations
safe_write_file() {
    local file_path="$1"
    local content="$2"
    local base_dir="${3:-.branch-analysis}"
    
    # Validate file path
    local safe_path
    safe_path=$(validate_file_path "$file_path" "$base_dir")
    
    # Ensure directory exists
    local dir_path
    dir_path=$(dirname "$safe_path")
    mkdir -p "$dir_path"
    
    # Write content safely
    echo "$content" > "$safe_path"
}

# Input validation for user-provided data
validate_user_input() {
    local input="$1"
    local input_type="$2"  # "branch", "file", "command", etc.
    local max_length="${3:-255}"
    
    # Check length
    if [[ ${#input} -gt $max_length ]]; then
        handle_error $E_GIT_ERROR "Input too long (${#input} > $max_length): $input_type" $LINENO "${FUNCNAME[1]}"
    fi
    
    # Type-specific validation
    case "$input_type" in
        "branch")
            validate_branch_name "$input" || handle_error $E_GIT_ERROR "Invalid branch name: $input" $LINENO "${FUNCNAME[1]}"
            ;;
        "file")
            validate_file_path "$input" >/dev/null
            ;;
        "command")
            # Basic command injection prevention
            if [[ "$input" =~ [;&|`\$\(\)] ]]; then
                handle_error $E_GIT_ERROR "Potentially dangerous command characters: $input" $LINENO "${FUNCNAME[1]}"
            fi
            ;;
    esac
    
    echo "$input"
}

# Create secure temporary directory
create_secure_temp_dir() {
    local temp_dir
    temp_dir=$(mktemp -d -t branch_analysis.XXXXXX)
    
    # Set restrictive permissions
    chmod 700 "$temp_dir"
    
    # Register for cleanup
    register_temp_file "$temp_dir"
    
    echo "$temp_dir"
}
```

### Implementation Steps
1. Create security utilities for input validation
2. Implement branch name sanitization
3. Add safe command execution wrappers
4. Update all scripts to use secure functions

---

## Issue 10: Insufficient Validation Before Destructive Operations

### Problem
Auto-merge proceeds with minimal validation, potentially merging incompatible code.

### Solution
```bash
# File: scripts/lib/validation_engine.sh

#!/bin/bash

# Comprehensive validation engine for merge operations
source "$(dirname "${BASH_SOURCE[0]}")/error_handling.sh"
source "$(dirname "${BASH_SOURCE[0]}")/security_utils.sh"

readonly VALIDATION_CONFIG=".branch-analysis/validation_config.json"

# Initialize validation system
init_validation_system() {
    if [[ ! -f "$VALIDATION_CONFIG" ]]; then
        create_default_validation_config
    fi
}

# Create default validation configuration
create_default_validation_config() {
    cat > "$VALIDATION_CONFIG" << 'EOF'
{
    "validation_levels": {
        "AUTO_MERGE": ["syntax", "imports", "conflicts", "critical_files"],
        "GUIDED_MERGE": ["syntax", "imports", "conflicts", "critical_files", "tests"],
        "MANUAL_MERGE": ["syntax", "imports", "conflicts", "critical_files", "tests", "integration"]
    },
    "critical_files": [
        "install.py",
        "openwebui_installer/cli.py",
        "openwebui_installer/installer.py",
        "openwebui_installer/gui.py",
        "pyproject.toml",
        "requirements.txt",
        "README.md"
    ],
    "test_commands": [
        "python3 -m py_compile {file}",
        "python3 -c \"import {module}\"",
        "python3 -m pytest tests/ --collect-only"
    ],
    "thresholds": {
        "max_changed_files": 20,
        "max_critical_files": 3,
        "max_conflict_potential": 0
    }
}
EOF
}

# Pre-merge validation
validate_before_merge() {
    local branch="$1"
    local merge_strategy="$2"
    local base_branch="${3:-main}"
    
    init_validation_system
    
    echo "🔍 Pre-merge validation for: $branch (strategy: $merge_strategy)"
    
    local validation_levels
    validation_levels=($(jq -r ".validation_levels[\"$merge_strategy\"][]" "$VALIDATION_CONFIG"))
    
    local validation_results=()
    local validation_passed=true
    
    for level in "${validation_levels[@]}"; do
        echo "  Validating: $level"
        
        case "$level" in
            "syntax")
                validate_syntax "$branch" "$base_branch"
                ;;
            "imports")
                validate_imports "$branch" "$base_branch"
                ;;
            "conflicts")
                validate_conflicts "$branch" "$base_branch"
                ;;
            "critical_files")
                validate_critical_files "$branch" "$base_branch"
                ;;
            "tests")
                validate_tests "$branch" "$base_branch"
                ;;
            "integration")
                validate_integration "$branch" "$base_branch"
                ;;
        esac
        
        local result=$?
        validation_results+=("$level:$result")
        
        if [[ $result -ne 0 ]]; then
            validation_passed=false
            echo "    ❌ $level validation failed"
        else
            echo "    ✅ $level validation passed"
        fi
    done
    
    # Generate validation report
    generate_validation_report "$branch" "$merge_strategy" "${validation_results[@]}"
    
    if [[ "$validation_passed" == "true" ]]; then
        echo "✅ All validations passed for $branch"
        return 0
    else
        echo "❌ Validation failed for $branch"
        return 1
    fi
}

# Syntax validation
validate_syntax() {
    local branch="$1"
    local base_branch="$2"
    
    # Get changed Python files
    local changed_python_files
    changed_python_files=($(git diff --name-only "$base_branch"..."origin/$branch" | grep '\.py$' || true))
    
    if [[ ${#changed_python_files[@]} -eq 0 ]]; then
        return 0
    fi
    
    # Create temporary merge to test syntax
    local temp_branch="temp-syntax-check-$(date +%s)"
    git checkout -b "$temp_branch" "$base_branch" >/dev/null 2>&1
    
    local syntax_errors=()
    
    if git merge "origin/$branch" --no-commit --no-ff >/dev/null 2>&1; then
        for py_file in "${changed_python_files[@]}"; do
            if [[ -f "$py_file" ]]; then
                if ! python3 -m py_compile "$py_file" 2>/dev/null; then
                    syntax_errors+=("$py_file")
                fi
            fi
        done
        git merge --abort >/dev/null 2>&1 || true
    else
        git merge --abort >/dev/null 2>&1 || true
        git checkout "$base_branch" >/dev/null 2>&1
        git branch -D "$temp_branch" >/dev/null 2>&1
        return 1
    fi
    
    git checkout "$base_branch" >/dev/null 2>&1
    git branch -D "$temp_branch" >/dev/null 2>&1
    
    if [[ ${#syntax_errors[@]} -gt 0 ]]; then
        echo "    Syntax errors in: ${syntax_errors[*]}"
        return 1
    fi
    
    return 0
}

# Import validation
validate_imports() {
    local branch="$1"
    local base_branch="$2"
    
    # Get changed Python files
    local changed_python_files
    changed_python_files=($(git diff --name-only "$base_branch"..."origin/$branch" | grep '\.py$' || true))
    
    if [[ ${#changed_python_files[@]} -eq 0 ]]; then
        return 0
    fi
    
    # Create temporary merge to test imports
    local temp_branch="temp-import-check-$(date +%s)"
    git checkout -b "$temp_branch" "$base_branch" >/dev/null 2>&1
    
    local import_errors=()
    
    if git merge "origin/$branch" --no-commit --no-ff >/dev/null 2>&1; then
        # Test critical imports
        local import_tests=(
            "from openwebui_installer.cli import main"
            "from openwebui_installer.installer import Installer"
            "import openwebui_installer"
        )
        
        for import_test in "${import_tests[@]}"; do
            if ! python3 -c "$import_test" 2>/dev/null; then
                import_errors+=("$import_test")
            fi
        done
        
        git merge --abort >/dev/null 2>&1 || true
    else
        git merge --abort >/dev/null 2>&1 || true
        git checkout "$base_branch" >/dev/null 2>&1
        git branch -D "$temp_branch" >/dev/null 2>&1
        return 1
    fi
    
    git checkout "$base_branch" >/dev/null 2>&1
    git branch -D "$temp_branch" >/dev/null 2>&1
    
    if [[ ${#import_errors[@]} -gt 0 ]]; then
        echo "    Import errors: ${import_errors[*]}"
        return 1
    fi
    
    return 0
}

# Conflict validation
validate_conflicts() {
    local branch="$1"
    local base_branch="$2"
    
    # Use git merge-tree to detect conflicts
    local merge_tree_output
    merge_tree_output=$(git merge-tree "$base_branch" "origin/$branch" 2>/dev/null || echo "")
    
    if echo "$merge_tree_output" | grep -q "<<<<<<< "; then
        local conflict_count
        conflict_count=$(echo "$merge_tree_output" | grep -c "<<<<<<< " || echo "0")
        echo "    Detected $conflict_count merge conflicts"
        return 1
    fi
    
    # Additional conflict detection using diff
    local changed_files
    changed_files=($(git diff --name-only "$base_branch"..."origin/$branch" || true))
    
    local potential_conflicts=()
    for file in "${changed_files[@]}"; do
        # Check if file was also modified in base branch recently
        local base_changes
        base_changes=$(git log --oneline --since="7 days ago" "$base_branch" -- "$file" | wc -l)
        
        if [[ $base_changes -gt 0 ]]; then
            potential_conflicts+=("$file")
        fi
    done
    
    if [[ ${#potential_conflicts[@]} -gt 3 ]]; then
        echo "    High conflict potential: ${#potential_conflicts[@]} files recently modified"
        return 1
    fi
    
    return 0
}

# Critical files validation
validate_critical_files() {
    local branch="$1"
    local base_branch="$2"
    
    local critical_files
    critical_files=($(jq -r '.critical_files[]' "$VALIDATION_CONFIG"))
    
    local changed_files
    changed_files=($(git diff --name-only "$base_branch"..."origin/$branch" || true))
    
    local affected_critical=()
    for file in "${critical_files[@]}"; do
        if printf '%s\n' "${changed_files[@]}" | grep -q "^$file$"; then
            affected_critical+=("$file")
        fi
    done
    
    local max_critical
    max_critical=$(jq -r '.thresholds.max_critical_files' "$VALIDATION_CONFIG")
    
    if [[ ${#affected_critical[@]} -gt $max_critical ]]; then
        echo "    Too many critical files affected: ${#affected_critical[@]} > $max_critical"
        echo "    Critical files: ${affected_critical[*]}"
        return 1
    fi
    
    return 0
}

# Test validation
validate_tests() {
    local branch="$1"
    local base_branch="$2"
    
    # Create temporary merge to run tests
    local temp_branch="temp-test-check-$(date +%s)"
    git checkout -b "$temp_branch" "$base_branch" >/dev/null 2>&1
    
    if git merge "origin/$branch" --no-commit --no-ff >/dev/null 2>&1; then
        # Run basic test collection
        if command -v pytest >/dev/null 2>&1; then
            if ! python3 -m pytest tests/ --collect-only >/dev/null 2>&1; then
                git merge --abort >/dev/null 2>&1 || true
                git checkout "$base_branch" >/dev/null 2>&1
                git branch -D "$temp_branch" >/dev/null 2>&1
                return 1
            fi
        fi
        
        git merge --abort >/dev/null 2>&1 || true
    else
        git merge --abort >/dev/null 2>&1 || true
        git checkout "$base_branch" >/dev/null 2>&1
        git branch -D "$temp_branch" >/dev/null 2>&1
        return 1
    fi
    
    git checkout "$base_branch" >/dev/null 2>&1
    git branch -D "$temp_branch" >/dev/null 2>&1
    
    return 0
}

# Integration validation
validate_integration() {
    local branch="$1"
    local base_branch="$2"
    
    # Create temporary merge for integration tests
    local temp_branch="temp-integration-check-$(date +%s)"
    git checkout -b "$temp_branch" "$base_branch" >/dev/null 2>&1
    
    if git merge "origin/$branch" --no-commit --no-ff >/dev/null 2>&1; then
        # Test CLI functionality
        if ! python3 -c "
import sys
sys.path.insert(0, '.')
from openwebui_installer.cli import cli
sys.argv = ['cli', '--help']
try:
    cli()
except SystemExit as e:
    if e.code != 0:
        exit(1)
" 2>/dev/null; then
            git merge --abort >/dev/null 2>&1 || true
            git checkout "$base_branch" >/dev/null 2>&1
            git branch -D "$temp_branch" >/dev/null 2>&1
            return 1
        fi
        
        git merge --abort >/dev/null 2>&1 || true
    else
        git merge --abort >/dev/null 2>&1 || true
        git checkout "$base_branch" >/dev/null 2>&1
        git branch -D "$temp_branch" >/dev/null 2>&1
        return 1
    fi
    
    git checkout "$base_branch" >/dev/null 2>&1
    git branch -D "$temp_branch" >/dev/null 2>&1
    
    return 0
}

# Generate validation report
generate_validation_report() {
    local branch="$1"
    local merge_strategy="$2"
    shift 2
    local validation_results=("$@")
    
    local report_file=".branch-analysis/validation_${branch//\//_}_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# Validation Report: $branch

**Strategy**: $merge_strategy
**Timestamp**: $(date)
**Branch**: $branch

## Results

EOF
    
    for result in "${validation_results[@]}"; do
        IFS=':' read -r test_name test_result <<< "$result"
        if [[ $test_result -eq 0 ]]; then
            echo "- ✅ $test_name: PASSED" >> "$report_file"
        else
            echo "- ❌ $test_name: FAILED" >> "$report_file"
        fi
    done
    
    echo "" >> "$report_file"
    echo "Report generated: $report_file"
}
```

### Implementation Steps
1. Create comprehensive validation engine with configurable levels
2. Implement syntax, import, and conflict validation
3. Add test execution and integration validation
4. Update merge scripts to use validation engine

---

## Issue 11: Code Duplication

### Problem
Color definitions, logging functions, and Git operations repeated across scripts, causing maintenance overhead.

### Solution
```bash
# File: scripts/lib/common.sh

#!/bin/bash

# Common utilities for branch analysis scripts
# Single source of truth for shared functionality

# Version and metadata
readonly COMMON_LIB_VERSION="1.0.0"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[1]}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors (consistent across all scripts)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Logging levels
readonly LOG_DEBUG=0
readonly LOG_INFO=1
readonly LOG_WARN=2
readonly LOG_ERROR=3

# Current log level (can be overridden)
LOG_LEVEL=${LOG_LEVEL:-$LOG_INFO}

# Standardized logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local color=""
    local level_name=""
    
    case "$level" in
        "$LOG_DEBUG")
            [[ $LOG_LEVEL -gt $LOG_DEBUG ]] && return
            level_name="DEBUG"
            color="$BLUE"
            ;;
        "$LOG_INFO")
            [[ $LOG_LEVEL -gt $LOG_INFO ]] && return
            level_name="INFO"
            color="$GREEN"
            ;;
        "$LOG_WARN")
            [[ $LOG_LEVEL -gt $LOG_WARN ]] && return
            level_name="WARN"
            color="$YELLOW"
            ;;
        "$LOG_ERROR")
            [[ $LOG_LEVEL -gt $LOG_ERROR ]] && return
            level_name="ERROR"
            color="$RED"
            ;;
    esac
    
    echo -e "${color}[$timestamp] [$level_name] $SCRIPT_NAME: $message${NC}" >&2
    
    # Also log to file if analysis directory exists
    if [[ -d ".branch-analysis" ]]; then
        echo "[$timestamp] [$level_name] $SCRIPT_NAME: $message" >> .branch-analysis/script.log
    fi
}

# Convenience logging functions
log_debug() { log $LOG_DEBUG "$1"; }
log_info() { log $LOG_INFO "$1"; }
log_warn() { log $LOG_WARN "$1"; }
log_error() { log $LOG_ERROR "$1"; }

# Progress indicator
show_progress() {
    local current="$1"
    local total="$2"
    local task="${3:-Processing}"
    local width=50
    
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r${BLUE}$task: [${GREEN}"
    printf "%${filled}s" | tr ' ' '='
    printf "${NC}${YELLOW}"
    printf "%${empty}s" | tr ' ' '-'
    printf "${BLUE}] ${WHITE}%d%%${NC} (%d/%d)" "$percentage" "$current" "$total"
    
    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

# Spinner for long operations
show_spinner() {
    local pid="$1"
    local message="${2:-Processing...}"
    local spinstr='|/-\'
    
    echo -n "$message "
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf "[%c]" "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep 0.1
        printf "\b\b\b"
    done
    echo "✓"
}

# Confirmation prompt
confirm() {
    local message="$1"
    local default="${2:-n}"
    local prompt
    
    if [[ "$default" == "y" ]]; then
        prompt="$message (Y/n): "
    else
        prompt="$message (y/N): "
    fi
    
    while true; do
        read -p "$prompt" -n 1 -r reply
        echo
        
        if [[ -z "$reply" ]]; then
            reply="$default"
        fi
        
        case "$reply" in
            [Yy]) return 0 ;;
            [Nn]) return 1 ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

# Common Git operations
git_current_branch() {
    git branch --show-current 2>/dev/null || echo "HEAD"
}

git_main_branch() {
    if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
        echo "main"
    elif git show-ref --verify --quiet refs/heads/master 2>/dev/null; then
        echo "master"
    else
        echo "main"  # Default assumption
    fi
}

git_ensure_main_branch() {
    local main_branch
    main_branch=$(git_main_branch)
    local current_branch
    current_branch=$(git_current_branch)
    
    if [[ "$current_branch" != "$main_branch" ]]; then
        log_info "Switching to $main_branch branch"
        git checkout "$main_branch" || {
            log_error "Failed to switch to $main_branch"
            return 1
        }
    fi
}

# File operations
ensure_directory() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        log_debug "Created directory: $dir"
    fi
}

# Time operations
timestamp() {
    date +"%Y%m%d_%H%M%S"
}

iso_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Array operations
array_contains() {
    local element="$1"
    shift
    local array=("$@")
    
    for item in "${array[@]}"; do
        if [[ "$item" == "$element" ]]; then
            return 0
        fi
    done
    return 1
}

array_unique() {
    local array=("$@")
    local unique_array=()
    
    for item in "${array[@]}"; do
        if ! array_contains "$item" "${unique_array[@]}"; then
            unique_array+=("$item")
        fi
    done
    
    echo "${unique_array[@]}"
}

# String operations
trim() {
    local str="$1"
    # Remove leading whitespace
    str="${str#"${str%%[![:space:]]*}"}"
    # Remove trailing whitespace
    str="${str%"${str##*[![:space:]]}"}"
    echo "$str"
}

# Initialize common library
init_common_lib() {
    # Ensure we're in the repository root
    cd "$REPO_ROOT" || {
        log_error "Failed to change to repository root: $REPO_ROOT"
        exit 1
    }
    
    # Create analysis directory if it doesn't exist
    ensure_directory ".branch-analysis"
    
    log_debug "Common library initialized (version $COMMON_LIB_VERSION)"
}

# Call initialization
init_common_lib
```

### Implementation Steps
1. Create centralized common utilities library
2. Extract shared code from all scripts
3. Update all scripts to source common library
4. Remove duplicated code and standardize interfaces

---

## Issue 12: Configuration Management

### Problem
Hardcoded paths, branch names, and file patterns make scripts difficult to adapt for different repositories.

### Solution
```bash
# File: scripts/lib/config_manager.sh

#!/bin/bash

# Configuration management for branch analysis scripts
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

readonly CONFIG_FILE=".branch-analysis/config.json"
readonly DEFAULT_CONFIG_FILE="scripts/config/default_config.json"

# Initialize configuration system
init_config_system() {
    ensure_directory ".branch-analysis"
    ensure_directory "scripts/config"
    
    # Create default configuration if it doesn't exist
    if [[ ! -f "$DEFAULT_CONFIG_FILE" ]]; then
        create_default_config
    fi
    
    # Create user configuration if it doesn't exist
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_info "Creating configuration file from defaults"
        cp "$DEFAULT_CONFIG_FILE" "$CONFIG_FILE"
    fi
    
    # Validate configuration
    validate_config
}

# Create default configuration
create_default_config() {
    cat > "$DEFAULT_CONFIG_FILE" << 'EOF'
{
    "version": "1.0",
    "repository": {
        "main_branch": "main",
        "fallback_branch": "master",
        "remote_name": "origin"
    },
    "analysis": {
        "max_parallel_jobs": 8,
        "cache_expiry_seconds": 300,
        "max_backups": 10,
        "skip_patterns": [
            "codex/new-task",
            "codex/find-and-fix-a-bug-in-the-codebase",
            "codex/investigate-empty-openwebui-installer-folder",
            "codex/delete-.ds_store-from-repository",
            "codex/remove-tracked-.ds_store-and-.snapshots",
            "codex/remove-multi-platform-claims-and-update-docs"
        ]
    },
    "critical_files": [
        "install.py",
        "openwebui_installer/cli.py",
        "openwebui_installer/installer.py",
        "openwebui_installer/gui.py",
        "README.md",
        "pyproject.toml",
        "requirements.txt",
        "OpenWebUI-Desktop/OpenWebUI-Desktop/OpenWebUIApp.swift",
        "OpenWebUI-Desktop/OpenWebUI-Desktop/ContentView.swift"
    ],
    "branch_patterns": {
        "critical": [
            "*app-store*",
            "*swift*",
            "*universal*"
        ],
        "high": [
            "*container*",
            "*multi*",
            "*catalog*"
        ],
        "medium": [
            "*feature*",
            "*enhance*",
            "*improve*"
        ],
        "low": [
            "*fix*",
            "*bug*",
            "*patch*"
        ]
    },
    "validation": {
        "AUTO_MERGE": {
            "max_changed_files": 10,
            "max_critical_files": 1,
            "max_conflict_potential": 0,
            "required_checks": ["syntax", "imports", "conflicts"]
        },
        "GUIDED_MERGE": {
            "max_changed_files": 20,
            "max_critical_files": 3,
            "max_conflict_potential": 2,
            "required_checks": ["syntax", "imports", "conflicts", "critical_files"]
        },
        "MANUAL_MERGE": {
            "max_changed_files": 100,
            "max_critical_files": 10,
            "max_conflict_potential": 10,
            "required_checks": ["syntax", "imports", "conflicts", "critical_files", "tests"]
        }
    },
    "paths": {
        "analysis_dir": ".branch-analysis",
        "backup_dir": ".branch-analysis/backups",
        "cache_dir": ".branch-analysis/cache",
        "logs_dir": ".branch-analysis/logs",
        "temp_dir": ".branch-analysis/temp"
    },
    "logging": {
        "level": "INFO",
        "max_log_files": 10,
        "max_log_size_mb": 10
    },
    "timeouts": {
        "git_operation": 300,
        "merge_operation": 600,
        "validation": 300,
        "lock_timeout": 1800
    }
}
EOF
    
    log_info "Created default configuration: $DEFAULT_CONFIG_FILE"
}

# Get configuration value
get_config() {
    local key="$1"
    local default_value="$2"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        init_config_system
    fi
    
    local value
    value=$(jq -r ".$key // empty" "$CONFIG_FILE" 2>/dev/null)
    
    if [[ -z "$value" || "$value" == "null" ]]; then
        echo "$default_value"
    else
        echo "$value"
    fi
}

# Get configuration array
get_config_array() {
    local key="$1"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        init_config_system
    fi
    
    jq -r ".$key[]? // empty" "$CONFIG_FILE" 2>/dev/null
}

# Set configuration value
set_config() {
    local key="$1"
    local value="$2"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        init_config_system
    fi
    
    local temp_file
    temp_file=$(mktemp)
    
    jq ".$key = \"$value\"" "$CONFIG_FILE" > "$temp_file" && mv "$temp_file" "$CONFIG_FILE"
    
    log_info "Updated configuration: $key = $value"
}

# Validate configuration
validate_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Configuration file not found: $CONFIG_FILE"
        return 1
    fi
    
    # Check if it's valid JSON
    if ! jq . "$CONFIG_FILE" >/dev/null 2>&1; then
        log_error "Invalid JSON in configuration file: $CONFIG_FILE"
        return 1
    fi
    
    # Check required fields
    local required_fields=(
        "version"
        "repository.main_branch"
        "critical_files"
        "paths.analysis_dir"
    )
    
    for field in "${required_fields[@]}"; do
        if ! jq -e ".$field" "$CONFIG_FILE" >/dev/null 2>&1; then
            log_error "Missing required configuration field: $field"
            return 1
        fi
    done
    
    log_debug "Configuration validation passed"
    return 0
}

# Environment-specific configuration
load_environment_config() {
    local env="${1:-development}"
    local env_config_file="scripts/config/${env}_config.json"
    
    if [[ -f "$env_config_file" ]]; then
        log_info "Loading environment configuration: $env"
        
        # Merge environment config with base config
        local temp_file
        temp_file=$(mktemp)
        
        jq -s '.[0] * .[1]' "$CONFIG_FILE" "$env_config_file" > "$temp_file" && mv "$temp_file" "$CONFIG_FILE"
        
        log_info "Environment configuration loaded: $env"
    else
        log_warn "Environment configuration not found: $env_config_file"
    fi
}

# Configuration helpers
get_main_branch() {
    get_config "repository.main_branch" "main"
}

get_remote_name() {
    get_config "repository.remote_name" "origin"
}

get_analysis_dir() {
    get_config "paths.analysis_dir" ".branch-analysis"
}

get_critical_files() {
    get_config_array "critical_files"
}

get_skip_patterns() {
    get_config_array "analysis.skip_patterns"
}

get_max_parallel_jobs() {
    get_config "analysis.max_parallel_jobs" "8"
}

get_cache_expiry() {
    get_config "analysis.cache_expiry_seconds" "300"
}

get_validation_config() {
    local strategy="$1"
    local field="$2"
    
    get_config "validation.${strategy}.${field}" ""
}

# Display current configuration
show_config() {
    echo "📋 Current Configuration"
    echo "======================="
    
    if [[ -f "$CONFIG_FILE" ]]; then
        echo "Configuration file: $CONFIG_FILE"
        echo ""
        jq . "$CONFIG_FILE"
    else
        echo "Configuration file not found: $CONFIG_FILE"
        echo "Run 'init_config_system' to create default configuration"
    fi
}
```

### Implementation Steps
1. Create flexible configuration management system
2. Extract all hardcoded values to configuration files
3. Add environment-specific configuration support
4. Update all scripts to use configuration values

---

## Issue 13: Limited Logging & Monitoring

### Problem
Basic logging without structured data or metrics makes debugging and performance tracking difficult.

### Solution
```bash
# File: scripts/lib/monitoring.sh

#!/bin/bash

# Monitoring and metrics collection for branch analysis scripts
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/config_manager.sh"

readonly METRICS_FILE=".branch-analysis/metrics.json"
readonly PERFORMANCE_LOG=".branch-analysis/performance.log"

# Initialize monitoring system
init_monitoring() {
    local logs_dir
    logs_dir=$(get_config "paths.logs_dir" ".branch-analysis/logs")
    ensure_directory "$logs_dir"
    
    # Initialize metrics file
    if [[ ! -f "$METRICS_FILE" ]]; then
        cat > "$METRICS_FILE" << 'EOF'
{
    "script_executions": {},
    "performance_metrics": {},
    "error_counts": {},
    "branch_statistics": {},
    "last_updated": ""
}
EOF
    fi
}

# Start timing an operation
start_timer() {
    local operation="$1"
    local start_time
    start_time=$(date +%s.%N)
    
    echo "$start_time" > "/tmp/timer_${operation//\//_}"
    log_debug "Started timer for: $operation"
}

# End timing and record metric
end_timer() {
    local operation="$1"
    local timer_file="/tmp/timer_${operation//\//_}"
    
    if [[ -f "$timer_file" ]]; then
        local start_time
        start_time=$(cat "$timer_file")
        local end_time
        end_time=$(date +%s.%N)
        local duration
        duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
        
        # Record performance metric
        record_performance_metric "$operation" "$duration"
        
        # Clean up timer file
        rm -f "$timer_file"
        
        log_debug "Completed timer for: $operation (${duration}s)"
        echo "$duration"
    else
        log_warn "Timer not found for operation: $operation"
        echo "0"
    fi
}

# Record performance metric
record_performance_metric() {
    local operation="$1"
    local duration="$2"
    local timestamp
    timestamp=$(iso_timestamp)
    
    init_monitoring
    
    # Update metrics file
    local temp_file
    temp_file=$(mktemp)
    
    jq ".performance_metrics[\"$operation\"] += [{
        \"timestamp\": \"$timestamp\",
        \"duration\": $duration,
        \"script\": \"$SCRIPT_NAME\"
    }] | .last_updated = \"$timestamp\"" "$METRICS_FILE" > "$temp_file" && mv "$temp_file" "$METRICS_FILE"
    
    # Also log to performance log
    echo "[$timestamp] $SCRIPT_NAME: $operation completed in ${duration}s" >> "$PERFORMANCE_LOG"
}

# Record script execution
record_script_execution() {
    local script_name="$1"
    local status="$2"  # "started", "completed", "failed"
    local details="${3:-}"
    
    init_monitoring
    
    local timestamp
    timestamp=$(iso_timestamp)
    
    local temp_file
    temp_file=$(mktemp)
    
    jq ".script_executions[\"$script_name\"] += [{
        \"timestamp\": \"$timestamp\",
        \"status\": \"$status\",
        \"details\": \"$details\",
        \"pid\": $$
    }] | .last_updated = \"$timestamp\"" "$METRICS_FILE" > "$temp_file" && mv "$temp_file" "$METRICS_FILE"
    
    log_info "Script execution recorded: $script_name - $status"
}

# Record error
record_error() {
    local error_type="$1"
    local error_message="$2"
    local context="${3:-}"
    
    init_monitoring
    
    local timestamp
    timestamp=$(iso_timestamp)
    
    local temp_file
    temp_file=$(mktemp)
    
    jq ".error_counts[\"$error_type\"] += 1 | 
        .error_counts[\"total\"] += 1 | 
        .last_updated = \"$timestamp\"" "$METRICS_FILE" > "$temp_file" && mv "$temp_file" "$METRICS_FILE"
    
    # Log error details
    log_error "[$error_type] $error_message ${context:+(context: $context)}"
}

# Record branch statistics
record_branch_stats() {
    local total_branches="$1"
    local auto_merge="$2"
    local guided_merge="$3"
    local manual_merge="$4"
    
    init_monitoring
    
    local timestamp
    timestamp=$(iso_timestamp)
    
    local temp_file
    temp_file=$(mktemp)
    
    jq ".branch_statistics = {
        \"timestamp\": \"$timestamp\",
        \"total_branches\": $total_branches,
        \"auto_merge\": $auto_merge,
        \"guided_merge\": $guided_merge,
        \"manual_merge\": $manual_merge,
        \"analysis_efficiency\": $(echo "scale=2; $auto_merge * 100 / $total_branches" | bc -l 2>/dev/null || echo "0")
    } | .last_updated = \"$timestamp\"" "$METRICS_FILE" > "$temp_file" && mv "$temp_file" "$METRICS_FILE"
}

# Generate performance report
generate_performance_report() {
    local report_file=".branch-analysis/performance_report_$(timestamp).md"
    
    init_monitoring
    
    cat > "$report_file" << EOF
# Performance Report

**Generated**: $(date)
**Period**: Last 30 days

## Script Performance

EOF
    
    # Get performance data
    local operations
    operations=$(jq -r '.performance_metrics | keys[]' "$METRICS_FILE" 2>/dev/null || echo "")
    
    for operation in $operations; do
        local avg_duration
        avg_duration=$(jq -r ".performance_metrics[\"$operation\"] | map(.duration) | add / length" "$METRICS_FILE" 2>/dev/null || echo "0")
        local count
        count=$(jq -r ".performance_metrics[\"$operation\"] | length" "$METRICS_FILE" 2>/dev/null || echo "0")
        
        cat >> "$report_file" << EOF
### $operation
- **Executions**: $count
- **Average Duration**: ${avg_duration}s
- **Total Time**: $(echo "$avg_duration * $count" | bc -l 2>/dev/null || echo "0")s

EOF
    done
    
    # Error statistics
    cat >> "$report_file" << EOF
## Error Statistics

EOF
    
    local error_types
    error_types=$(jq -r '.error_counts | keys[] | select(. != "total")' "$METRICS_FILE" 2>/dev/null || echo "")
    
    for error_type in $error_types; do
        local count
        count=$(jq -r ".error_counts[\"$error_type\"]" "$METRICS_FILE" 2>/dev/null || echo "0")
        echo "- **$error_type**: $count occurrences" >> "$report_file"
    done
    
    # Branch analysis efficiency
    cat >> "$report_file" << EOF

## Branch Analysis Efficiency

EOF
    
    local efficiency
    efficiency=$(jq -r '.branch_statistics.analysis_efficiency // 0' "$METRICS_FILE" 2>/dev/null || echo "0")
    
    cat >> "$report_file" << EOF
- **Auto-merge Rate**: ${efficiency}%
- **Last Analysis**: $(jq -r '.branch_statistics.timestamp // "Never"' "$METRICS_FILE" 2>/dev/null || echo "Never")

EOF
    
    echo "Performance report generated: $report_file"
}

# Health check
health_check() {
    echo "🏥 System Health Check"
    echo "====================="
    
    init_monitoring
    
    local health_status="HEALTHY"
    local issues=()
    
    # Check recent errors
    local total_errors
    total_errors=$(jq -r '.error_counts.total // 0' "$METRICS_FILE" 2>/dev/null || echo "0")
    
    if [[ $total_errors -gt 10 ]]; then
        health_status="DEGRADED"
        issues+=("High error count: $total_errors")
    fi
    
    # Check recent performance
    local recent_operations
    recent_operations=$(jq -r '.performance_metrics | to_entries[] | select(.value[-1].timestamp > (now - 3600 | todateiso8601)) | .key' "$METRICS_FILE" 2>/dev/null || echo "")
    
    if [[ -z "$recent_operations" ]]; then
        health_status="STALE"
        issues+=("No recent operations")
    fi
    
    # Check disk space
    local analysis_dir
    analysis_dir=$(get_analysis_dir)
    local disk_usage
    disk_usage=$(du -sm "$analysis_dir" 2>/dev/null | cut -f1 || echo "0")
    
    if [[ $disk_usage -gt 100 ]]; then
        health_status="WARNING"
        issues+=("High disk usage: ${disk_usage}MB")
    fi
    
    # Report health status
    case "$health_status" in
        "HEALTHY")
            echo -e "${GREEN}✅ System is healthy${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️ System has warnings${NC}"
            ;;
        "DEGRADED")
            echo -e "${YELLOW}⚠️ System performance is degraded${NC}"
            ;;
        "STALE")
            echo -e "${RED}❌ System appears stale${NC}"
            ;;
    esac
    
    if [[ ${#issues[@]} -gt 0 ]]; then
        echo ""
        echo "Issues found:"
        for issue in "${issues[@]}"; do
            echo "  - $issue"
        done
    fi
    
    echo ""
}
```

### Implementation Steps
1.  Implement comprehensive monitoring library (`scripts/lib/monitoring.sh`).
2.  Integrate `start_timer` and `end_timer` into long-running operations.
3.  Add `record_script_execution` calls at the beginning and end of each main script.
4.  Utilize `record_error` for all handled and unhandled error scenarios.
5.  Update main analysis script to use `record_branch_stats`.
6.  Add `generate_performance_report` to `branch_maintenance.sh` for regular reporting.
7.  Add a `health_check` command to `branch_maintenance.sh`.

---

## Issue 14: Branch Categorization Logic

### Problem
Simple pattern matching for branch relevance may misclassify branches with complex naming.

### Solution
```bash
# File: scripts/lib/branch_categorizer.sh

#!/bin/bash

# Enhanced branch categorization using configuration and potential future AI/ML integration
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/config_manager.sh"

# Function to categorize branches by Universal App Store relevance
categorize_branch_relevance() {
    local branch="$1"
    local relevance="UNKNOWN"

    # Get patterns from configuration
    local critical_patterns=($(get_config_array "branch_patterns.critical"))
    local high_patterns=($(get_config_array "branch_patterns.high"))
    local medium_patterns=($(get_config_array "branch_patterns.medium"))
    local low_patterns=($(get_config_array "branch_patterns.low"))

    # Apply patterns based on priority (critical first)
    for pattern in "${critical_patterns[@]}"; do
        if [[ "$branch" == $pattern ]]; then
            relevance="CRITICAL"
            break
        fi
    done

    if [[ "$relevance" == "UNKNOWN" ]]; then
        for pattern in "${high_patterns[@]}"; do
            if [[ "$branch" == $pattern ]]; then
                relevance="HIGH"
                break
            fi
        done
    fi

    if [[ "$relevance" == "UNKNOWN" ]]; then
        for pattern in "${medium_patterns[@]}"; do
            if [[ "$branch" == $pattern ]]; then
                relevance="MEDIUM"
                break
            fi
        done
    fi

    if [[ "$relevance" == "UNKNOWN" ]]; then
        for pattern in "${low_patterns[@]}"; do
            if [[ "$branch" == $pattern ]]; then
                relevance="LOW"
                break
            fi
        done
    fi

    echo "$relevance"
}

# Function to assess branch impact (could be expanded with more logic)
assess_branch_impact() {
    local branch="$1"
    local impact_score=0

    # Example: Increase score for branches touching core files
    local critical_files_touched=$(git diff --name-only main..."origin/$branch" 2>/dev/null | grep -c -E '^(install\.py|openwebui_installer/cli\.py|pyproject\.toml)')
    impact_score=$((impact_score + (critical_files_touched * 5)))

    # Example: Increase score for older branches (more potential for divergence)
    local commit_date=$(git log -1 --format="%ct" "origin/$branch" 2>/dev/null || echo 0)
    local current_date=$(date +%s)
    local days_old=$(((current_date - commit_date) / (60*60*24)))
    impact_score=$((impact_score + (days_old / 30))) # 1 point per month old

    echo "$impact_score"
}

# Future enhancement: Integration with external categorization service/AI
# categorize_branch_ai() {
#     local branch="$1"
#     # Call an external API or local ML model to categorize
#     # e.g., curl -s "http://ai.service/categorize?branch=$branch"
# }
```

### Implementation Steps
1.  Extract branch categorization logic into `scripts/lib/branch_categorizer.sh`.
2.  Update `enhanced_branch_analyzer.sh` to use `categorize_branch_relevance` and `assess_branch_impact`.
3.  Move branch patterns from `enhanced_branch_analyzer.sh` to `config.json`.
4.  Consider future integration with AI/ML services for more accurate categorization.

---

## Issue 15: Conflict Detection Accuracy

### Problem
Current conflict detection relies heavily on `git merge-tree`, which may not catch all types of conflicts or provide detailed enough information for "safe" auto-merges.

### Solution
```bash
# File: scripts/lib/conflict_detector.sh

#!/bin/bash

# Enhanced conflict detection for Git branches
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/config_manager.sh"

# Function to perform deep conflict analysis
analyze_deep_conflicts() {
    local branch="$1"
    local base_branch="${2:-main}"
    local conflict_details=""
    local conflict_count=0
    local critical_file_conflicts=0

    log_debug "Starting deep conflict analysis for: $branch against $base_branch"

    # Fetch latest before creating a temporary merge to ensure accuracy
    safe_network_operation "git fetch origin $branch"
    safe_network_operation "git fetch origin $base_branch"

    # Create a temporary merge commit without committing
    local temp_branch="temp-merge-check-$(timestamp)"
    local current_branch=$(git_current_branch)

    # Ensure we are on the base branch for the merge attempt
    safe_git checkout -b "$temp_branch" "origin/$base_branch"

    # Attempt a merge, capturing output and checking for conflicts
    local merge_output
    if merge_output=$(git merge "origin/$branch" --no-commit --no-ff 2>&1); then
        # Check if merge was clean (no conflict markers)
        if echo "$merge_output" | grep -q "Automatic merge failed"; then
            log_debug "Automatic merge failed for $branch. Conflicts detected."
            conflict_details="Automatic merge failed."
            conflict_count=$(echo "$merge_output" | grep -c "CONFLICT (content):")
            
            # Check for critical file conflicts
            local critical_files=($(get_critical_files))
            for file in "${critical_files[@]}"; do
                if echo "$merge_output" | grep -q "CONFLICT (content): Merge conflict in $file"; then
                    critical_file_conflicts=$((critical_file_conflicts + 1))
                fi
            done
        else
            log_debug "No conflicts detected by git merge-tree."
        fi
    else
        log_warn "Git merge command failed unexpectedly for $branch: $merge_output"
        conflict_details="Git merge command failed."
        conflict_count=999 # Indicate severe issue
    fi

    # Abort the merge to clean up the repository state
    git merge --abort >/dev/null 2>&1 || true

    # Return to the original branch
    safe_git checkout "$current_branch"
    safe_git branch -D "$temp_branch" # Delete the temporary branch

    # Output results in a structured format (e.g., JSON or key-value pairs)
    cat << EOF
{
  "conflict_count": $conflict_count,
  "critical_file_conflicts": $critical_file_conflicts,
  "conflict_details": "$conflict_details"
}
EOF
}

# Function to check if a branch would introduce new files that conflict
check_new_file_conflicts() {
    local branch="$1"
    local base_branch="${2:-main}"
    local new_file_conflicts=0

    local new_files_in_branch=$(git diff --name-only --diff-filter=A "origin/$base_branch" "origin/$branch" 2>/dev/null)
    
    for new_file in $new_files_in_branch; do
        # Check if the new file already exists in the base branch (untracked or otherwise)
        if git ls-files --error-unmatch -- "origin/$base_branch:$new_file" >/dev/null 2>&1; then
            log_debug "New file '$new_file' in branch '$branch' already exists in '$base_branch'"
            new_file_conflicts=$((new_file_conflicts + 1))
        fi
    done
    echo "$new_file_conflicts"
}
```

### Implementation Steps
1.  Create `scripts/lib/conflict_detector.sh` to centralize conflict logic.
2.  Modify `analyze_branch_conflicts` in `enhanced_branch_analyzer.sh` to call `analyze_deep_conflicts`.
3.  Utilize `git merge --no-commit --no-ff` to safely detect conflicts without altering history.
4.  Capture detailed conflict information, including specific files.
5.  Integrate `check_new_file_conflicts` to detect new file collisions.
6.  Update conflict potential assessment logic in `enhanced_branch_analyzer.sh` based on richer conflict data.

---

## Issue 16: Limited Integration Testing

### Problem
Post-merge validation tests basic syntax but not true integration or runtime functionality, risking silently broken merges.

### Solution
```bash
# File: scripts/lib/integration_tester.sh

#!/bin/bash

# Comprehensive integration testing and runtime validation
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/config_manager.sh"
source "$(dirname "${BASH_SOURCE[0]}")/resource_manager.sh"

# Function to run integration tests
run_integration_tests() {
    local branch="$1"
    local test_suite="${2:-default}" # e.g., "cli", "gui", "installer"
    local base_dir=""
    local test_result=true

    log_info "Running integration tests for branch: $branch (suite: $test_suite)"
    start_timer "integration_test_$branch"

    local temp_dir=$(mktemp -d -t branch_integration_XXXX)
    register_temp_file "$temp_dir"

    # Checkout the branch into a temporary worktree
    if ! safe_git worktree add "$temp_dir" "origin/$branch"; then
        log_error "Failed to create worktree for integration testing: $branch"
        return 1
    fi

    # Navigate to the worktree
    pushd "$temp_dir" >/dev/null || { log_error "Failed to enter temp directory"; return 1; }

    # Setup Python environment for tests
    if [[ -f "requirements.txt" ]]; then
        log_info "Installing Python dependencies..."
        if ! python3 -m pip install -r requirements.txt --quiet >/dev/null 2>&1; then
            log_warn "Failed to install Python requirements for integration tests."
            # Continue, as some tests might still run
        fi
    fi

    case "$test_suite" in
        "cli")
            # Test CLI basic functionality
            log_info "Executing CLI integration tests..."
            if ! python3 -c "import sys; sys.path.insert(0, '.'); from openwebui_installer.cli import cli; try: import click; from click.testing import CliRunner; runner = CliRunner(); result = runner.invoke(cli, ['--help']); sys.exit(result.exit_code);" >/dev/null 2>&1; then
                log_error "CLI --help test failed."
                test_result=false
            fi
            # Add more CLI tests here (e.g., install dry-run, version check)
            ;;
        "installer")
            # Test installer class instantiation and basic methods (without actual install)
            log_info "Executing Installer integration tests..."
            if ! python3 -c "import sys; sys.path.insert(0, '.'); from openwebui_installer.installer import Installer; try: Installer(runtime='docker'); Installer(runtime='podman'); sys.exit(0); except Exception as e: print(f'Installer init failed: {e}', file=sys.stderr); sys.exit(1);" >/dev/null 2>&1; then
                log_error "Installer instantiation test failed."
                test_result=false
            fi
            ;;
        "swift")
            # Test Swift/macOS app build and basic runtime checks (requires Xcode)
            if command -v xcodebuild >/dev/null 2>&1; then
                log_info "Executing Swift/macOS app build test..."
                if ! xcodebuild -project "OpenWebUI-Desktop/OpenWebUI-Desktop.xcodeproj" -scheme "OpenWebUI-Desktop" -configuration Release build >/dev/null 2>&1; then
                    log_error "Swift/macOS app build failed."
                    test_result=false
                fi
                # Further tests could involve running the app and interacting via UI automation tools
            else
                log_warn "Xcode is not installed. Skipping Swift/macOS app integration tests."
            fi
            ;;
        "default"|*)
            # Run a combination of tests
            run_integration_tests "$branch" "cli" || test_result=false
            run_integration_tests "$branch" "installer" || test_result=false
            # Only run swift tests if Xcode is present
            if command -v xcodebuild >/dev/null 2>&1; then
                 run_integration_tests "$branch" "swift" || test_result=false
            fi
            ;;
    esac

    popd >/dev/null || { log_error "Failed to return from temp directory"; return 1; }
    safe_git worktree remove "$temp_dir" >/dev/null 2>&1 || true

    end_timer "integration_test_$branch"
    if [[ "$test_result" == "true" ]]; then
        log_info "Integration tests for $branch PASSED."
        return 0
    else
        log_error "Integration tests for $branch FAILED."
        return 1
    fi
}
```

### Implementation Steps
1.  Create `scripts/lib/integration_tester.sh` to house comprehensive integration tests.
2.  Implement distinct test suites (e.g., CLI, installer logic, Swift app build/basic run).
3.  Use `git worktree` to create isolated environments for testing a branch.
4.  Integrate this into the CI workflow as a critical step.
5.  Add environment checks (e.g., for `xcodebuild`) to skip irrelevant tests gracefully.
6.  Expand the number and depth of runtime tests for Python and Swift components.

---