#!/usr/bin/env bash
# auto_merge_safe.sh - Automatically merge safe branches into a target branch.
# Works on macOS and Linux.

set -euo pipefail

TARGET_BRANCH="main"
BRANCH_PREFIX="safe/"

usage() {
    cat <<USAGE
Usage: $0 [-b base_branch] [-p prefix] [branch1 branch2 ...]

Automatically merge safe branches into the target branch. If no branches are
specified, all branches matching the given prefix will be merged.

Options:
  -b <branch>  Target branch to merge into (default: main)
  -p <prefix>  Branch prefix to select when none are provided (default: safe/)
  -h           Show this help message
USAGE
    exit 0
}

while getopts ":b:p:h" opt; do
    case "$opt" in
        b) TARGET_BRANCH="$OPTARG" ;;
        p) BRANCH_PREFIX="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done
shift $((OPTIND-1))

if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: must run inside a git repository" >&2
    exit 1
fi

# Fetch latest from origin
git fetch --all --quiet

BRANCHES="$*"
if [[ -z "$BRANCHES" ]]; then
    BRANCHES=$(git branch --list "${BRANCH_PREFIX}*" | sed 's/^..//')
fi

if [[ -z "$BRANCHES" ]]; then
    echo "No branches to merge" >&2
    exit 0
fi

# Ensure target branch is up to date
git checkout "$TARGET_BRANCH"
 git pull --ff-only origin "$TARGET_BRANCH"

for b in $BRANCHES; do
    echo "Merging $b into $TARGET_BRANCH"
    if git merge --no-ff "origin/$b" -m "Automated merge of $b"; then
        echo "Merged $b successfully"
    else
        echo "Merge conflict with $b, aborting" >&2
        git merge --abort || true
    fi
done

git push origin "$TARGET_BRANCH"

