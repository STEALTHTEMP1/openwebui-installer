#!/usr/bin/env bash

# Manual conflict resolution helper
# Usage: manual_merge_branch.sh <branch>
# Creates a merge branch from origin/<branch>, merges main, and guides
# the user through resolving conflicts. Works on macOS and Linux.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <branch>" >&2
  exit 1
fi

BRANCH="$1"
MERGE_BRANCH="merge-${BRANCH//\//-}"

# Ensure remote branch exists
if ! git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
  echo "Remote branch origin/$BRANCH not found" >&2
  exit 1
fi

# Fetch latest branch data
git fetch origin "$BRANCH"

# Prevent overwriting existing merge branch
if git show-ref --verify --quiet "refs/heads/$MERGE_BRANCH"; then
  echo "Local branch $MERGE_BRANCH already exists" >&2
  exit 1
fi

# Create merge branch from remote
git checkout -b "$MERGE_BRANCH" "origin/$BRANCH"

# Attempt to merge main
if git merge --no-ff main; then
  echo "Merge completed without conflicts."
else
  echo "Conflicts detected. Resolve them manually, then run:"
  echo "  git add <files>"
  echo "  git merge --continue"
fi

echo "Run ./scripts/post_merge_validation.sh to verify the merge." 
echo "When satisfied, push with: git push origin $MERGE_BRANCH" 

