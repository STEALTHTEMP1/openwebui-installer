#!/usr/bin/env bash
# git_workflow.sh - Automate add, commit, push and optional merge via GitHub CLI
# Works on macOS and Linux.

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat <<USAGE
Usage: $0 -m <commit-message> [-b <base-branch>]

Automates common git workflow steps:
 1. git add -A
 2. git commit -m <message>
 3. git push origin <current-branch>
 4. Create pull request via gh (if available)
 5. Merge the pull request (requires gh and token)

Options:
 -m  Commit message (required)
 -b  Base branch for PR merge (default: main)
 -h  Show this help
USAGE
    exit 0
}

COMMIT_MSG=""
BASE_BRANCH="main"

while getopts ":m:b:h" opt; do
    case "$opt" in
        m) COMMIT_MSG="$OPTARG" ;;
        b) BASE_BRANCH="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

if [[ -z "$COMMIT_MSG" ]]; then
    echo "Commit message required." >&2
    usage
fi

if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Not a git repository." >&2
    exit 1
fi

if ! git config remote.origin.url >/dev/null 2>&1; then
    echo "Remote 'origin' not configured. Use 'git remote add origin <url>'." >&2
    exit 1
fi

CURRENT_BRANCH=$(git symbolic-ref --short HEAD)

echo -e "${BLUE}Adding changes...${NC}"
git add -A

echo -e "${BLUE}Committing...${NC}"
git commit -m "$COMMIT_MSG"

echo -e "${BLUE}Pushing to origin/${CURRENT_BRANCH}...${NC}"
git push origin "$CURRENT_BRANCH"

if command -v gh >/dev/null 2>&1; then
    echo -e "${BLUE}Creating pull request...${NC}"
    if gh pr view "$CURRENT_BRANCH" >/dev/null 2>&1; then
        echo -e "${YELLOW}Pull request already exists.${NC}"
    else
        gh pr create --fill --base "$BASE_BRANCH" || true
    fi

    echo -e "${BLUE}Attempting to merge...${NC}"
    gh pr merge "$CURRENT_BRANCH" --squash --delete-branch || true
else
    echo -e "${YELLOW}GitHub CLI not found. Skipping PR creation and merge.${NC}"
fi

echo -e "${GREEN}Workflow complete.${NC}"
