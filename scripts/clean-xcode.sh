#!/usr/bin/env bash
set -euo pipefail

# clean-xcode.sh - Remove Xcode cache directories and verify bundled runtime

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUNDLE_SCRIPT="$PROJECT_ROOT/OpenWebUI-Desktop/Scripts/bundle-resources.sh"

clean_dir() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        rm -rf "$dir"
        log_success "Removed $dir"
    else
        log_info "No $dir directory found"
    fi
}

main() {
    echo "🧹 Cleaning Xcode caches"
    echo "======================="

    clean_dir "$HOME/Library/Developer/Xcode/DerivedData"
    clean_dir "$HOME/Library/Caches/com.apple.dt.Xcode"

    if [[ -x "$BUNDLE_SCRIPT" && "$OSTYPE" == "darwin"* ]]; then
        log_info "Validating Bundled-Runtime..."
        if "$BUNDLE_SCRIPT" --verify; then
            log_success "Runtime bundle verified"
        else
            log_error "Runtime bundle verification failed"
        fi
    fi
}

main "$@"
