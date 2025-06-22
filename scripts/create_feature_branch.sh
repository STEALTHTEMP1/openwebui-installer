#!/bin/bash
# Create a feature branch from the active phase or develop branch
# Usage: create_feature_branch.sh <feature-name>
# The script checks for a local phase branch (phase*). If found, the
# feature branch is created from that; otherwise, develop is used.
set -euo pipefail

FEATURE_NAME="${1:-}"
if [[ -z "$FEATURE_NAME" ]]; then
  echo "Usage: $0 <feature-name>" >&2
  exit 1
fi

BASE_BRANCH="develop"
PHASE_BRANCH=$(git branch --list 'phase*' | head -n 1 | awk '{print $1}')
if [[ -n "$PHASE_BRANCH" ]]; then
  BASE_BRANCH="$PHASE_BRANCH"
fi

echo "Creating feature branch '$FEATURE_NAME' from '$BASE_BRANCH'"
git fetch origin "$BASE_BRANCH"
git checkout -b "$FEATURE_NAME" "origin/$BASE_BRANCH"
echo "Branch '$FEATURE_NAME' created."
