#!/usr/bin/env bash
<<<<<<< codex/search-and-handle-auto_merge_safe.sh-script
# auto_merge_safe.sh - Automatically merge safe branches into a target branch.
=======
# Auto merge safe branches into a target branch.
>>>>>>> main
# Works on macOS and Linux.

set -euo pipefail

<<<<<<< codex/search-and-handle-auto_merge_safe.sh-script
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
=======
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

usage() {
    echo "Usage: $0 [-b base-branch] branch1 [branch2 ...]" >&2
    exit 1
}

BASE_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
while getopts ":b:h" opt; do
    case "${opt}" in
        b) BASE_BRANCH="${OPTARG}" ;;
>>>>>>> main
        h) usage ;;
        *) usage ;;
    esac
done
<<<<<<< codex/search-and-handle-auto_merge_safe.sh-script
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

=======
shift $((OPTIND -1))

[ $# -lt 1 ] && usage

# Fetch latest information
if git rev-parse --git-dir >/dev/null 2>&1; then
    git fetch --all --quiet
fi

for BRANCH in "$@"; do
    echo -e "${YELLOW}==> Merging '$BRANCH' into '$BASE_BRANCH'...${NC}"
    if ! git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
        echo -e "${RED}Remote branch not found: $BRANCH${NC}"
        continue
    fi

    git checkout "$BASE_BRANCH" >/dev/null 2>&1

    if git merge-base --is-ancestor "origin/$BRANCH" "$BASE_BRANCH" >/dev/null 2>&1; then
        echo -e "${GREEN}Already merged: $BRANCH${NC}"
        continue
    fi

    if git merge --no-commit --no-ff "origin/$BRANCH" >/dev/null 2>&1; then
        git commit -m "Auto merge $BRANCH" >/dev/null 2>&1
        git push origin "$BASE_BRANCH" >/dev/null 2>&1
        echo -e "${GREEN}Merged '$BRANCH' successfully${NC}"
    else
        echo -e "${RED}Conflicts detected for '$BRANCH'. Aborting merge.${NC}"
        git merge --abort >/dev/null 2>&1 || true
    fi
    echo
done
>>>>>>> main
