#!/bin/bash

# bundle-resources.sh
# OpenWebUI-Desktop
#
# Created on December 22, 2024.
# Resource Bundling Script for Level 3 Complete Abstraction
#
# This script downloads and prepares the necessary runtime components
# for bundling into the OpenWebUI Desktop application.

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUNDLED_RUNTIME_DIR="$PROJECT_DIR/Bundled-Runtime"
TEMP_DIR="$PROJECT_DIR/temp-downloads"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# log_info prints an informational message to stdout with blue color formatting.
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# log_success prints a success message in green to stdout.
log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# log_warning prints a warning message to stdout in yellow color.
log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# log_error prints an error message in red to stderr.
log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# check_platform verifies that the script is running on macOS and exits with an error if not.
check_platform() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "This script must be run on macOS"
        exit 1
    fi
}

# detect_architecture determines the current CPU architecture and echoes 'arm64' or 'amd64', exiting with an error for unsupported architectures.
detect_architecture() {
    local arch=$(uname -m)
    if [[ "$arch" == "arm64" ]]; then
        echo "arm64"
    elif [[ "$arch" == "x86_64" ]]; then
        echo "amd64"
    else
        log_error "Unsupported architecture: $arch"
        exit 1
    fi
}

# setup_directories creates the bundled runtime and temporary directories required for resource preparation.
setup_directories() {
    log_info "Setting up directories..."

    mkdir -p "$BUNDLED_RUNTIME_DIR"
    mkdir -p "$TEMP_DIR"

    log_success "Directories created"
}

# download_podman downloads the appropriate Podman remote client binary for the detected macOS architecture, verifies its functionality, and places it in the bundled runtime directory. Exits on failure at any step.
download_podman() {
    local arch=$(detect_architecture)
    local podman_version="v4.8.3"  # Use stable version
    local download_url

    log_info "Downloading Podman binary for $arch architecture..."

    case "$arch" in
        "arm64")
            download_url="https://github.com/containers/podman/releases/download/${podman_version}/podman-remote-release-darwin_arm64.zip"
            ;;
        "amd64")
            download_url="https://github.com/containers/podman/releases/download/${podman_version}/podman-remote-release-darwin_amd64.zip"
            ;;
        *)
            log_error "Unsupported architecture for Podman: $arch"
            exit 1
            ;;
    esac

    local podman_zip="$TEMP_DIR/podman-${arch}.zip"
    local podman_extract_dir="$TEMP_DIR/podman-extract"

    # Download Podman
    if ! curl -L -o "$podman_zip" "$download_url"; then
        log_error "Failed to download Podman from $download_url"
        exit 1
    fi

    # Extract Podman
    mkdir -p "$podman_extract_dir"
    if ! unzip -q "$podman_zip" -d "$podman_extract_dir"; then
        log_error "Failed to extract Podman archive"
        exit 1
    fi

    # Find and copy podman binary
    local podman_binary=$(find "$podman_extract_dir" -name "podman" -type f | head -1)
    if [[ -z "$podman_binary" ]]; then
        log_error "Could not find podman binary in extracted archive"
        exit 1
    fi

    # Copy to bundled runtime directory
    cp "$podman_binary" "$BUNDLED_RUNTIME_DIR/podman"
    chmod +x "$BUNDLED_RUNTIME_DIR/podman"

    # Verify the binary works
    if ! "$BUNDLED_RUNTIME_DIR/podman" --version > /dev/null 2>&1; then
        log_error "Downloaded Podman binary is not functional"
        exit 1
    fi

    local version_info=$("$BUNDLED_RUNTIME_DIR/podman" --version)
    log_success "Podman downloaded and verified: $version_info"
}

# prepare_openwebui_image pulls the latest Open WebUI container image, saves it as a compressed archive in the bundled runtime directory, and ensures Podman is available for the operation.
prepare_openwebui_image() {
    log_info "Preparing Open WebUI container image..."

    local image_name="ghcr.io/open-webui/open-webui:main"
    local podman_binary="$BUNDLED_RUNTIME_DIR/podman"
    local image_archive="$BUNDLED_RUNTIME_DIR/openwebui-image.tar.gz"

    # Check if podman is available (either system or bundled)
    local podman_cmd
    if command -v podman &> /dev/null; then
        podman_cmd="podman"
        log_info "Using system Podman"
    elif [[ -x "$podman_binary" ]]; then
        podman_cmd="$podman_binary"
        log_info "Using bundled Podman"
    else
        log_error "No Podman binary available. Please run download_podman first or install Podman system-wide."
        exit 1
    fi

    # Pull the latest Open WebUI image
    log_info "Pulling Open WebUI image: $image_name"
    if ! $podman_cmd pull "$image_name"; then
        log_error "Failed to pull Open WebUI image"
        exit 1
    fi

    # Save image to archive
    log_info "Saving image to archive..."
    local temp_archive="$TEMP_DIR/openwebui-image.tar"

    if ! $podman_cmd save -o "$temp_archive" "$image_name"; then
        log_error "Failed to save Open WebUI image"
        exit 1
    fi

    # Compress the archive
    log_info "Compressing image archive..."
    if ! gzip -c "$temp_archive" > "$image_archive"; then
        log_error "Failed to compress image archive"
        exit 1
    fi

    # Get compressed size
    local compressed_size=$(du -h "$image_archive" | cut -f1)
    log_success "Open WebUI image prepared: $compressed_size"

    # Clean up temporary archive
    rm -f "$temp_archive"
}

# create_metadata generates a JSON metadata file describing the bundled Podman binary and Open WebUI container image, including version, size, architecture, and system requirements.
create_metadata() {
    log_info "Creating resource metadata..."

    local metadata_file="$BUNDLED_RUNTIME_DIR/bundle-info.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local arch=$(detect_architecture)

    # Get file sizes
    local podman_size="unknown"
    local image_size="unknown"

    if [[ -f "$BUNDLED_RUNTIME_DIR/podman" ]]; then
        podman_size=$(stat -f%z "$BUNDLED_RUNTIME_DIR/podman" 2>/dev/null || echo "unknown")
    fi

    if [[ -f "$BUNDLED_RUNTIME_DIR/openwebui-image.tar.gz" ]]; then
        image_size=$(stat -f%z "$BUNDLED_RUNTIME_DIR/openwebui-image.tar.gz" 2>/dev/null || echo "unknown")
    fi

    # Get Podman version
    local podman_version="unknown"
    if [[ -x "$BUNDLED_RUNTIME_DIR/podman" ]]; then
        podman_version=$("$BUNDLED_RUNTIME_DIR/podman" --version 2>/dev/null | head -1 || echo "unknown")
    fi

    cat > "$metadata_file" << EOF
{
  "bundleInfo": {
    "createdAt": "$timestamp",
    "architecture": "$arch",
    "bundler": "bundle-resources.sh",
    "bundlerVersion": "1.0.0"
  },
  "runtime": {
    "name": "podman",
    "version": "$podman_version",
    "size": $podman_size,
    "path": "podman",
    "executable": true
  },
  "containerImage": {
    "name": "ghcr.io/open-webui/open-webui:main",
    "size": $image_size,
    "path": "openwebui-image.tar.gz",
    "compressed": true,
    "format": "tar.gz"
  },
  "requirements": {
    "macOSMinVersion": "10.15",
    "architectures": ["arm64", "x86_64"],
    "minimumMemoryGB": 4,
    "minimumDiskSpaceGB": 3
  }
}
EOF

    log_success "Resource metadata created: $metadata_file"
}

# verify_bundle checks the integrity and validity of the bundled Podman binary, Open WebUI image archive, and metadata file, reporting any errors found.
verify_bundle() {
    log_info "Verifying bundled resources..."

    local errors=0

    # Check Podman binary
    if [[ ! -f "$BUNDLED_RUNTIME_DIR/podman" ]]; then
        log_error "Podman binary not found"
        ((errors++))
    elif [[ ! -x "$BUNDLED_RUNTIME_DIR/podman" ]]; then
        log_error "Podman binary is not executable"
        ((errors++))
    else
        if ! "$BUNDLED_RUNTIME_DIR/podman" --version > /dev/null 2>&1; then
            log_error "Podman binary is not functional"
            ((errors++))
        else
            log_success "Podman binary verified"
        fi
    fi

    # Check Open WebUI image
    if [[ ! -f "$BUNDLED_RUNTIME_DIR/openwebui-image.tar.gz" ]]; then
        log_error "Open WebUI image archive not found"
        ((errors++))
    else
        # Verify it's a valid gzip file
        if ! gzip -t "$BUNDLED_RUNTIME_DIR/openwebui-image.tar.gz" 2>/dev/null; then
            log_error "Open WebUI image archive is corrupted"
            ((errors++))
        else
            log_success "Open WebUI image archive verified"
        fi
    fi

    # Check metadata
    if [[ ! -f "$BUNDLED_RUNTIME_DIR/bundle-info.json" ]]; then
        log_error "Bundle metadata not found"
        ((errors++))
    else
        # Verify it's valid JSON
        if ! python3 -m json.tool "$BUNDLED_RUNTIME_DIR/bundle-info.json" > /dev/null 2>&1; then
            log_error "Bundle metadata is not valid JSON"
            ((errors++))
        else
            log_success "Bundle metadata verified"
        fi
    fi

    if [[ $errors -eq 0 ]]; then
        log_success "All bundled resources verified successfully"
        return 0
    else
        log_error "Found $errors error(s) in bundled resources"
        return 1
    fi
}

# cleanup removes the temporary download directory and its contents if it exists.
cleanup() {
    log_info "Cleaning up temporary files..."

    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        log_success "Temporary files cleaned up"
    fi
}

# show_summary displays a summary of the bundled Podman runtime and Open WebUI image, including their sizes, versions, and bundle location.
show_summary() {
    log_info "Bundle Summary:"
    echo "----------------------------------------"

    if [[ -f "$BUNDLED_RUNTIME_DIR/podman" ]]; then
        local podman_size=$(du -h "$BUNDLED_RUNTIME_DIR/podman" | cut -f1)
        local podman_version=$("$BUNDLED_RUNTIME_DIR/podman" --version 2>/dev/null | head -1)
        echo "Podman Runtime: $podman_size ($podman_version)"
    fi

    if [[ -f "$BUNDLED_RUNTIME_DIR/openwebui-image.tar.gz" ]]; then
        local image_size=$(du -h "$BUNDLED_RUNTIME_DIR/openwebui-image.tar.gz" | cut -f1)
        echo "Open WebUI Image: $image_size (compressed)"
    fi

    if [[ -d "$BUNDLED_RUNTIME_DIR" ]]; then
        local total_size=$(du -sh "$BUNDLED_RUNTIME_DIR" | cut -f1)
        echo "Total Bundle Size: $total_size"
    fi

    echo "----------------------------------------"
    echo "Bundle Location: $BUNDLED_RUNTIME_DIR"
    echo "Ready for Xcode integration!"
}

# usage prints command-line usage instructions and available options for the bundle-resources.sh script.
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Downloads and prepares runtime components for OpenWebUI Desktop app."
    echo ""
    echo "Options:"
    echo "  --podman-only     Download only Podman binary"
    echo "  --image-only      Prepare only Open WebUI image"
    echo "  --verify          Verify existing bundle"
    echo "  --clean           Clean up temporary files and exit"
    echo "  --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                Download all components"
    echo "  $0 --podman-only  Download only Podman"
    echo "  $0 --verify       Verify existing bundle"
}

# main parses command-line arguments and orchestrates the resource bundling, verification, cleanup, and summary display for the OpenWebUI Desktop application on macOS.
main() {
    local podman_only=false
    local image_only=false
    local verify_only=false
    local clean_only=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --podman-only)
                podman_only=true
                shift
                ;;
            --image-only)
                image_only=true
                shift
                ;;
            --verify)
                verify_only=true
                shift
                ;;
            --clean)
                clean_only=true
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Ensure we're on macOS
    check_platform

    echo "🚀 OpenWebUI Desktop Resource Bundler"
    echo "======================================"

    if [[ "$clean_only" == true ]]; then
        cleanup
        exit 0
    fi

    if [[ "$verify_only" == true ]]; then
        if verify_bundle; then
            show_summary
            exit 0
        else
            exit 1
        fi
    fi

    # Setup directories
    setup_directories

    # Download components based on options
    if [[ "$image_only" == false ]]; then
        download_podman
    fi

    if [[ "$podman_only" == false ]]; then
        prepare_openwebui_image
    fi

    # Create metadata and verify
    create_metadata

    if verify_bundle; then
        cleanup
        show_summary
        log_success "Resource bundling completed successfully!"
    else
        log_error "Resource bundling failed verification"
        exit 1
    fi
}

# Execute main function with all arguments
main "$@"
