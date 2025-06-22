#!/bin/bash

# update-formula.sh
# Script to update the Homebrew formula with a new version

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FORMULA_FILE="Formula/openwebui-installer.rb"
REPO_URL="https://github.com/STEALTHTEMP1/openwebui-installer"

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    cat << EOF
Update Homebrew Formula Script

Usage: $0 [OPTIONS] <version>

Arguments:
  version     Version to update to (e.g., v1.0.0, 1.0.0)

Options:
  -h, --help     Show this help message
  -d, --dry-run  Show what would be changed without making changes
  -v, --verbose  Verbose output
  --no-commit    Don't create a git commit automatically

Examples:
  $0 v1.0.0
  $0 --dry-run v1.1.0
  $0 --no-commit v1.2.0

This script will:
1. Download the release archive from GitHub
2. Calculate the SHA256 hash
3. Update the formula file
4. Test the formula syntax
5. Optionally commit the changes
EOF
}

# Parse command line arguments
DRY_RUN=false
VERBOSE=false
NO_COMMIT=false
VERSION=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --no-commit)
            NO_COMMIT=true
            shift
            ;;
        -*)
            log_error "Unknown option $1"
            show_help
            exit 1
            ;;
        *)
            if [[ -z "$VERSION" ]]; then
                VERSION="$1"
            else
                log_error "Multiple versions specified"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [[ -z "$VERSION" ]]; then
    log_error "Version is required"
    show_help
    exit 1
fi

# Normalize version (add 'v' prefix if not present)
if [[ ! "$VERSION" =~ ^v ]]; then
    VERSION="v$VERSION"
fi

# Validate version format
if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
    log_error "Invalid version format. Expected: v1.2.3 or v1.2.3-beta"
    exit 1
fi

log_info "Updating formula to version: $VERSION"

# Check if formula file exists
if [[ ! -f "$FORMULA_FILE" ]]; then
    log_error "Formula file not found: $FORMULA_FILE"
    exit 1
fi

# Create URL for the release
RELEASE_URL="${REPO_URL}/archive/refs/tags/${VERSION}.tar.gz"
TEMP_FILE=$(mktemp)

log_info "Downloading release archive..."
if ! curl -L -f -o "$TEMP_FILE" "$RELEASE_URL" 2>/dev/null; then
    log_error "Failed to download release archive from: $RELEASE_URL"
    log_error "Make sure the release exists and is public"
    rm -f "$TEMP_FILE"
    exit 1
fi

log_success "Downloaded release archive"

# Calculate SHA256
log_info "Calculating SHA256 hash..."
if command -v shasum >/dev/null 2>&1; then
    SHA256=$(shasum -a 256 "$TEMP_FILE" | cut -d' ' -f1)
elif command -v sha256sum >/dev/null 2>&1; then
    SHA256=$(sha256sum "$TEMP_FILE" | cut -d' ' -f1)
else
    log_error "Neither shasum nor sha256sum found"
    rm -f "$TEMP_FILE"
    exit 1
fi

log_success "SHA256: $SHA256"

# Clean up temp file
rm -f "$TEMP_FILE"

# Show what will be changed
log_info "Current formula content:"
if [[ "$VERBOSE" == true ]]; then
    grep -E "(url|sha256)" "$FORMULA_FILE" | sed 's/^/  /'
fi

CURRENT_URL=$(grep 'url "' "$FORMULA_FILE" | head -1 | sed 's/.*url "\(.*\)".*/\1/')
CURRENT_SHA=$(grep 'sha256 "' "$FORMULA_FILE" | head -1 | sed 's/.*sha256 "\(.*\)".*/\1/')

echo "Changes to be made:"
echo "  URL: $CURRENT_URL -> $RELEASE_URL"
echo "  SHA256: $CURRENT_SHA -> $SHA256"

if [[ "$DRY_RUN" == true ]]; then
    log_warning "Dry run mode - no changes will be made"
    exit 0
fi

# Confirm changes
if [[ -t 0 ]]; then  # Only ask if running interactively
    echo -n "Continue with the update? [y/N] "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log_info "Update cancelled"
        exit 0
    fi
fi

# Create backup
BACKUP_FILE="${FORMULA_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$FORMULA_FILE" "$BACKUP_FILE"
log_info "Created backup: $BACKUP_FILE"

# Update the formula
log_info "Updating formula file..."

# Use sed to update URL and SHA256
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS sed
    sed -i '' "s|url \".*\"|url \"$RELEASE_URL\"|" "$FORMULA_FILE"
    sed -i '' "s|sha256 \".*\"|sha256 \"$SHA256\"|" "$FORMULA_FILE"
else
    # GNU sed
    sed -i "s|url \".*\"|url \"$RELEASE_URL\"|" "$FORMULA_FILE"
    sed -i "s|sha256 \".*\"|sha256 \"$SHA256\"|" "$FORMULA_FILE"
fi

log_success "Updated formula file"

# Test the formula syntax
log_info "Testing formula syntax..."
if command -v brew >/dev/null 2>&1; then
    if brew audit --strict "$FORMULA_FILE" >/dev/null 2>&1; then
        log_success "Formula syntax is valid"
    else
        log_error "Formula syntax check failed"
        log_info "Running brew audit for details:"
        brew audit --strict "$FORMULA_FILE"
        log_info "Restoring backup..."
        mv "$BACKUP_FILE" "$FORMULA_FILE"
        exit 1
    fi
else
    log_warning "Homebrew not found - skipping syntax check"
fi

# Show the changes
if [[ "$VERBOSE" == true ]]; then
    log_info "Updated formula content:"
    grep -E "(url|sha256)" "$FORMULA_FILE" | sed 's/^/  /'
fi

# Git operations
if command -v git >/dev/null 2>&1 && [[ -d .git ]]; then
    if [[ "$NO_COMMIT" == false ]]; then
        log_info "Creating git commit..."
        git add "$FORMULA_FILE"
        git commit -m "Update openwebui-installer to $VERSION

- Updated URL to $RELEASE_URL
- Updated SHA256 to $SHA256"
        log_success "Created git commit"

        log_info "You may want to push the changes:"
        log_info "  git push origin main"
    else
        log_info "Skipping git commit (--no-commit specified)"
        log_info "You can commit manually:"
        log_info "  git add $FORMULA_FILE"
        log_info "  git commit -m 'Update openwebui-installer to $VERSION'"
    fi
else
    if [[ ! -d .git ]]; then
        log_warning "Not a git repository - skipping git operations"
    else
        log_warning "Git not found - skipping git operations"
    fi
fi

# Clean up backup if everything succeeded
rm -f "$BACKUP_FILE"

log_success "Formula updated successfully to version $VERSION"

# Final instructions
echo ""
echo "Next steps:"
echo "1. Test the formula locally:"
echo "   brew uninstall openwebui-installer 2>/dev/null || true"
echo "   brew install --build-from-source $FORMULA_FILE"
echo ""
echo "2. If everything works, push your changes:"
echo "   git push origin main"
echo ""
echo "3. Test the installation from the tap:"
echo "   brew uninstall openwebui-installer"
echo "   brew install STEALTHTEMP1/openwebui-installer/openwebui-installer"
