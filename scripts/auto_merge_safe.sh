#!/usr/bin/env bash
# Auto merge safe branches into a target branch.
# Works on macOS and Linux.

set -euo pipefail

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
        h) usage ;;
        *) usage ;;
    esac
done
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
