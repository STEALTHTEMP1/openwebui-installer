#!/usr/bin/env bash

# Centralized error handling for branch analysis scripts
set -euo pipefail

# Error codes
readonly E_GIT_ERROR=10
readonly E_NETWORK_ERROR=11
# shellcheck disable=SC2034
readonly E_PERMISSION_ERROR=12  # Reserved for permission-related errors
# shellcheck disable=SC2034
readonly E_DEPENDENCY_ERROR=13  # Reserved for dependency resolution errors

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
    exit "$error_code"
}

# Safe Git command wrapper
safe_git() {
    local git_command="$*"
    local output
    local exit_code

    if output=$(git "$git_command" 2>&1); then
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
        rm -f "$TEMP_FILES" 2>/dev/null || true
    fi
}

# Trap errors
trap 'handle_error $? "Unexpected error" $LINENO "${FUNCNAME[0]}"' ERR

