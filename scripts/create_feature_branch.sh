#!/usr/bin/env bash
# Create a feature branch from develop or the latest phase branch.
# Usage: create_feature_branch.sh <feature-name> [--base <branch>]
# Works on macOS and Linux.

set -euo pipefail

if [[ ${1:-} == "" || ${1:-} == "-h" || ${1:-} == "--help" ]]; then
    echo "Usage: $0 <feature-name> [--base <branch>]"
    exit 1
fi

FEATURE_NAME="$1"
shift || true
BASE_BRANCH=""
if [[ ${1:-""} == "--base" ]]; then
    BASE_BRANCH="${2:-}"
fi

# Fetch latest refs
if git rev-parse --git-dir >/dev/null 2>&1; then
    git fetch --all --quiet
fi

if [[ -z "$BASE_BRANCH" ]]; then
    if git show-ref --verify --quiet refs/remotes/origin/develop; then
        BASE_BRANCH="develop"
    else
        BASE_BRANCH=$(git branch -r | sed -n 's#origin/\(phase[-0-9A-Za-z_]*\)#\1#p' | sort | tail -n 1)
    fi
fi

if [[ -z "$BASE_BRANCH" ]]; then
    echo "Unable to determine base branch (develop or phase)." >&2
    exit 1
fi

git checkout -B "$FEATURE_NAME" "origin/$BASE_BRANCH"
echo "Created branch '$FEATURE_NAME' from '$BASE_BRANCH'"
