#!/bin/bash

# Repository Restructuring Script
# This script helps categorize and move files to minimize public surface area

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PUBLIC_REPO_DIR="${PWD}"
PRIVATE_REPO_NAME="openwebui-installer-internal"
PRIVATE_REPO_DIR="../${PRIVATE_REPO_NAME}"
BACKUP_DIR="${PUBLIC_REPO_DIR}/.repo-backup-$(date +%Y%m%d-%H%M%S)"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to create directory if it doesn't exist
ensure_dir() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi
}

# Function to move files/directories to private repo
move_to_private() {
    local source=$1
    local dest_dir=$2
    local item_name=$(basename "$source")

    if [ -e "$source" ]; then
        ensure_dir "${PRIVATE_REPO_DIR}/${dest_dir}"
        print_status "$YELLOW" "Moving: $source -> ${PRIVATE_REPO_DIR}/${dest_dir}/${item_name}"
        mv "$source" "${PRIVATE_REPO_DIR}/${dest_dir}/"
        echo "$source" >> "${BACKUP_DIR}/moved_files.txt"
    else
        print_status "$RED" "Not found: $source"
    fi
}

# Main execution
main() {
    print_status "$BLUE" "=== Repository Restructuring Script ==="
    print_status "$BLUE" "Public Repo: ${PUBLIC_REPO_DIR}"
    print_status "$BLUE" "Private Repo: ${PRIVATE_REPO_DIR}"

    # Create backup directory
    ensure_dir "$BACKUP_DIR"
    print_status "$GREEN" "Created backup directory: $BACKUP_DIR"

    # Check if private repo directory exists
    if [ ! -d "$PRIVATE_REPO_DIR" ]; then
        print_status "$YELLOW" "Private repo directory not found. Creating it..."
        mkdir -p "$PRIVATE_REPO_DIR"
        cd "$PRIVATE_REPO_DIR"
        git init
        cd "$PUBLIC_REPO_DIR"
    fi

    # Create categorized lists
    print_status "$BLUE" "\n=== Phase 1: Categorizing Files ==="

    # Files to move to private repo
    cat > "${BACKUP_DIR}/files_to_move.txt" << 'EOF'
# Branch Analysis and Management
.branch-analysis/
# auto-pr-merge workflow is public
.github/workflows/auto-pr-merge.yml
scripts/branch_maintenance.sh
scripts/enhanced_branch_analyzer.sh
scripts/merge_critical_branches.sh
scripts/merge_safe_branches.sh
.github/workflows/ci.yml
scripts/systematic_branch_review.sh
smart_merge.sh
BRANCH_ANALYSIS_FIXES.md
BRANCH_ANALYSIS_IMPROVEMENTS.md
BRANCH_MANAGEMENT.md
BRANCH_MANAGEMENT_SUMMARY.md

# Internal Development Files
.zed/
.env.dev
..bfg-report/
dev.sh

# Internal Documentation
AUTOMATED_TEST_SUITE_UPDATES.md
CODEBASE_EVALUATION.md
CODEX_SETUP.md
DEVELOPMENT_TEAM_GUIDE.md
DEV_ENVIRONMENT.md
DOCKER_ABSTRACTION_STRATEGY.md
LICENSE_ANALYSIS.md
NATIVE_WRAPPER_ANALYSIS.md
ONE_CLICK_REQUIREMENTS.md
QA_REVIEW_SUMMARY.md
UNIVERSAL_ROADMAP.md
WORKING_SETUP.md
appstore.md
prd.md
example-private-repo-release.yml
private-repo-setup/
homebrew-tap-template/
codex-setup.sh
setup-codex.sh

# Non-essential GitHub workflows
.github/workflows/branch-cleanup.yml
.github/workflows/docs.yml
.github/workflows/pr-branch-check.yml
.github/BRANCH_PROTECTION_SETUP.md

# Development Scripts
scripts/create_feature_branch.sh
scripts/diagnose-network.sh
scripts/test_installation.sh
EOF

    # Files to keep in public repo
    cat > "${BACKUP_DIR}/files_to_keep.txt" << 'EOF'
# Core Installer
openwebui_installer/
install.py
setup.py
setup.sh
pyproject.toml
requirements.txt
requirements-container.txt

# Essential Config
.dockerignore
.gitignore
.env.example
Dockerfile.*
.codexrc

# CI/CD
.github/workflows/ci.yml
.github/workflows/release.yml
.github/dependabot.yml

# User Documentation
README.md
LICENSE
CHANGELOG.md
GETTING_STARTED.md

# Distribution
helm-chart/
homebrew-tap/
kubernetes/
terraform/

# Native App (if public)
OpenWebUI-Desktop/
EOF

    print_status "$GREEN" "File categorization complete"

    # Phase 2: Move files
    print_status "$BLUE" "\n=== Phase 2: Moving Files to Private Repo ==="

    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue

        # Determine destination directory based on category
        if [[ "$line" =~ branch|merge ]]; then
            dest_dir="branch-management"
        elif [[ "$line" =~ \.md$ ]] && [[ ! "$line" =~ README|LICENSE|CHANGELOG|GETTING_STARTED ]]; then
            dest_dir="internal-docs"
        elif [[ "$line" =~ ^scripts/ ]]; then
            dest_dir="scripts"
        elif [[ "$line" =~ ^\.github/ ]]; then
            dest_dir="github"
        else
            dest_dir="misc"
        fi

        move_to_private "$line" "$dest_dir"
    done < "${BACKUP_DIR}/files_to_move.txt"

    # Phase 3: Update .gitignore
    print_status "$BLUE" "\n=== Phase 3: Updating .gitignore ==="

    cat >> .gitignore << 'EOF'

# Internal development files (moved to private repo)
.branch-analysis/
.internal/
*.bak
.env.dev
.zed/
..bfg-report/

# Internal scripts
*branch*.sh
*merge*.sh

# Internal documentation
*BRANCH*.md
*INTERNAL*.md
DEVELOPMENT_TEAM_GUIDE.md
DEV_ENVIRONMENT.md
EOF

    print_status "$GREEN" "Updated .gitignore"

    # Phase 4: Create migration report
    print_status "$BLUE" "\n=== Phase 4: Creating Migration Report ==="

    cat > "${BACKUP_DIR}/migration_report.md" << EOF
# Repository Restructuring Report
Date: $(date)

## Summary
- Files moved to private repo: $(wc -l < "${BACKUP_DIR}/moved_files.txt" 2>/dev/null || echo 0)
- Backup location: ${BACKUP_DIR}

## Next Steps
1. Review moved files in: ${PRIVATE_REPO_DIR}
2. Commit changes in public repo
3. Push private repo to GitHub
4. Update CI/CD pipelines
5. Update team documentation

## Commands to finalize:
\`\`\`bash
# In public repo
cd ${PUBLIC_REPO_DIR}
git add .
git commit -m "Restructure: Move internal tools to private repository"
git push

# In private repo
cd ${PRIVATE_REPO_DIR}
git add .
git commit -m "Initial commit: Internal tools from public repo"
git remote add origin git@github.com:YOUR_ORG/${PRIVATE_REPO_NAME}.git
git push -u origin main
\`\`\`
EOF

    print_status "$GREEN" "Migration report created: ${BACKUP_DIR}/migration_report.md"

    # Phase 5: Create README for private repo
    cat > "${PRIVATE_REPO_DIR}/README.md" << 'EOF'
# OpenWebUI Installer - Internal Tools

This private repository contains internal development tools, scripts, and documentation for the OpenWebUI Installer project.

## Repository Structure

```
├── branch-management/    # Branch analysis and management tools
├── scripts/             # Development and utility scripts
├── internal-docs/       # Internal documentation
├── github/              # GitHub-specific configs and workflows
└── misc/                # Miscellaneous internal files
```

## Usage

These tools are for internal development use only. They are not required for end-users to install or use OpenWebUI.

### Branch Management Tools
- Tools for analyzing and managing Git branches
- Automated merge scripts
- Branch cleanup utilities

### Development Scripts
- Testing utilities
- Build helpers
- Diagnostic tools

## Security

This repository is private. Do not share its contents publicly or include them in the public installer repository.
EOF

    print_status "$GREEN" "Created README for private repo"

    # Final summary
    print_status "$BLUE" "\n=== Restructuring Complete ==="
    print_status "$GREEN" "✓ Files categorized and moved"
    print_status "$GREEN" "✓ .gitignore updated"
    print_status "$GREEN" "✓ Migration report created"
    print_status "$GREEN" "✓ Private repo README created"

    print_status "$YELLOW" "\nNext steps:"
    print_status "$YELLOW" "1. Review the migration report: ${BACKUP_DIR}/migration_report.md"
    print_status "$YELLOW" "2. Check moved files in: ${PRIVATE_REPO_DIR}"
    print_status "$YELLOW" "3. Commit and push changes to both repositories"
    print_status "$YELLOW" "4. Update CI/CD pipelines if needed"
}

# Run main function
main
