#!/bin/bash

# Repository Restructuring Validation Script
# This script validates that the restructured repository maintains all required functionality

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Validation results
PASSED=0
FAILED=0
WARNINGS=0

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if file exists
check_file() {
    local file=$1
    local required=$2

    if [ -f "$file" ]; then
        print_status "$GREEN" "✓ Found: $file"
        ((PASSED++))
    else
        if [ "$required" = "required" ]; then
            print_status "$RED" "✗ Missing required file: $file"
            ((FAILED++))
        else
            print_status "$YELLOW" "⚠ Missing optional file: $file"
            ((WARNINGS++))
        fi
    fi
}

# Function to check if directory exists
check_dir() {
    local dir=$1
    local required=$2

    if [ -d "$dir" ]; then
        print_status "$GREEN" "✓ Found directory: $dir"
        ((PASSED++))
    else
        if [ "$required" = "required" ]; then
            print_status "$RED" "✗ Missing required directory: $dir"
            ((FAILED++))
        else
            print_status "$YELLOW" "⚠ Missing optional directory: $dir"
            ((WARNINGS++))
        fi
    fi
}

# Function to check Python imports
check_python_imports() {
    print_status "$BLUE" "\n=== Checking Python Import Structure ==="

    if python3 -c "import openwebui_installer" 2>/dev/null; then
        print_status "$GREEN" "✓ Python package imports correctly"
        ((PASSED++))
    else
        print_status "$RED" "✗ Python package import failed"
        ((FAILED++))
    fi
}

# Function to check entry points
check_entry_points() {
    print_status "$BLUE" "\n=== Checking Entry Points ==="

    # Check if CLI entry point exists
    if [ -f "openwebui_installer/cli.py" ]; then
        if grep -q "def cli" "openwebui_installer/cli.py"; then
            print_status "$GREEN" "✓ CLI entry point found"
            ((PASSED++))
        else
            print_status "$RED" "✗ CLI entry point function missing"
            ((FAILED++))
        fi
    fi

    # Check if GUI entry point exists
    if [ -f "openwebui_installer/gui.py" ]; then
        if grep -q "def main" "openwebui_installer/gui.py"; then
            print_status "$GREEN" "✓ GUI entry point found"
            ((PASSED++))
        else
            print_status "$RED" "✗ GUI entry point function missing"
            ((FAILED++))
        fi
    fi
}

# Function to check Docker functionality
check_docker_files() {
    print_status "$BLUE" "\n=== Checking Docker Configuration ==="

    # Check for production Dockerfiles
    for dockerfile in Dockerfile Dockerfile.ai Dockerfile.dev; do
        if [ -f "$dockerfile" ]; then
            print_status "$GREEN" "✓ Found: $dockerfile"
            ((PASSED++))
        else
            print_status "$YELLOW" "⚠ Missing: $dockerfile"
            ((WARNINGS++))
        fi
    done

    # Check .dockerignore
    check_file ".dockerignore" "required"
}

# Function to check CI/CD
check_cicd() {
    print_status "$BLUE" "\n=== Checking CI/CD Configuration ==="

    check_file ".github/workflows/ci.yml" "required"
    check_file ".github/workflows/release.yml" "required"
    check_file ".github/dependabot.yml" "optional"
}

# Function to check distribution methods
check_distribution() {
    print_status "$BLUE" "\n=== Checking Distribution Methods ==="

    check_dir "helm-chart" "optional"
    check_dir "homebrew-tap" "optional"
    check_dir "kubernetes" "optional"

    # Check Helm chart structure if it exists
    if [ -d "helm-chart" ]; then
        check_file "helm-chart/Chart.yaml" "required"
        check_file "helm-chart/values.yaml" "required"
        check_dir "helm-chart/templates" "required"
    fi
}

# Function to check for private files that shouldn't be public
check_no_private_files() {
    print_status "$BLUE" "\n=== Checking for Private Files (Should NOT Exist) ==="

    local private_files=(
        ".branch-analysis"
        "scripts/merge_safe_branches.sh"
        "BRANCH_MANAGEMENT.md"
        "DEVELOPMENT_TEAM_GUIDE.md"
        ".env.dev"
        "tests/test_cli.py.bak"
    )

    for file in "${private_files[@]}"; do
        if [ -e "$file" ]; then
            print_status "$RED" "✗ Private file still exists: $file"
            ((FAILED++))
        else
            print_status "$GREEN" "✓ Private file removed: $file"
            ((PASSED++))
        fi
    done
}

# Function to validate installation process
check_installation() {
    print_status "$BLUE" "\n=== Checking Installation Process ==="

    # Check if install.py exists and is executable
    if [ -f "install.py" ]; then
        print_status "$GREEN" "✓ install.py exists"
        ((PASSED++))

        # Check if it has proper shebang
        if head -n1 install.py | grep -q "^#!/usr/bin/env python"; then
            print_status "$GREEN" "✓ install.py has proper shebang"
            ((PASSED++))
        else
            print_status "$YELLOW" "⚠ install.py missing shebang"
            ((WARNINGS++))
        fi
    else
        print_status "$RED" "✗ install.py missing"
        ((FAILED++))
    fi

    # Check setup.sh
    check_file "setup.sh" "optional"
}

# Function to check dependencies
check_dependencies() {
    print_status "$BLUE" "\n=== Checking Dependencies ==="

    check_file "requirements.txt" "required"
    check_file "pyproject.toml" "required"
    check_file "setup.py" "required"

    # Validate requirements.txt format
    if [ -f "requirements.txt" ]; then
        if grep -E "^[a-zA-Z0-9_-]+[><=]" requirements.txt >/dev/null; then
            print_status "$GREEN" "✓ requirements.txt has valid format"
            ((PASSED++))
        else
            print_status "$YELLOW" "⚠ requirements.txt might be empty or invalid"
            ((WARNINGS++))
        fi
    fi
}

# Function to run basic smoke test
run_smoke_test() {
    print_status "$BLUE" "\n=== Running Smoke Tests ==="

    # Test Python package structure
    if python3 -c "from openwebui_installer import installer" 2>/dev/null; then
        print_status "$GREEN" "✓ Can import installer module"
        ((PASSED++))
    else
        print_status "$RED" "✗ Cannot import installer module"
        ((FAILED++))
    fi

    # Test CLI help
    if python3 -m openwebui_installer.cli --help >/dev/null 2>&1; then
        print_status "$GREEN" "✓ CLI help works"
        ((PASSED++))
    else
        print_status "$YELLOW" "⚠ CLI help failed (might need dependencies)"
        ((WARNINGS++))
    fi
}

# Function to generate validation report
generate_report() {
    local report_file="validation_report_$(date +%Y%m%d_%H%M%S).md"

    cat > "$report_file" << EOF
# Repository Restructuring Validation Report

Date: $(date)

## Summary

- **Passed**: $PASSED checks
- **Failed**: $FAILED checks
- **Warnings**: $WARNINGS checks

## Status: $([ $FAILED -eq 0 ] && echo "✅ VALID" || echo "❌ INVALID")

## Required Actions

EOF

    if [ $FAILED -gt 0 ]; then
        cat >> "$report_file" << EOF
### Critical Issues (Must Fix)

The following required files/features are missing:
- Review the failed checks above
- Restore any missing required files
- Fix any broken functionality

EOF
    fi

    if [ $WARNINGS -gt 0 ]; then
        cat >> "$report_file" << EOF
### Warnings (Consider Fixing)

The following optional features are missing:
- Review the warning checks above
- Decide if these features should be restored
- Document any intentional removals

EOF
    fi

    cat >> "$report_file" << EOF
## Validation Details

See console output above for detailed check results.

## Next Steps

1. Fix any critical issues (failed checks)
2. Review warnings and decide on actions
3. Run validation again after fixes
4. Proceed with deployment once all critical checks pass

EOF

    print_status "$BLUE" "\nValidation report saved to: $report_file"
}

# Main execution
main() {
    print_status "$BLUE" "=== Repository Restructuring Validation ==="
    print_status "$BLUE" "Validating public repository structure...\n"

    # Core functionality checks
    print_status "$BLUE" "=== Checking Core Installer Files ==="
    check_dir "openwebui_installer" "required"
    check_file "openwebui_installer/__init__.py" "required"
    check_file "openwebui_installer/installer.py" "required"
    check_file "openwebui_installer/cli.py" "required"
    check_file "openwebui_installer/gui.py" "optional"
    check_file "openwebui_installer/downloader.py" "optional"

    # Documentation checks
    print_status "$BLUE" "\n=== Checking Documentation ==="
    check_file "README.md" "required"
    check_file "LICENSE" "required"
    check_file "CHANGELOG.md" "optional"
    check_file "GETTING_STARTED.md" "optional"

    # Configuration checks
    print_status "$BLUE" "\n=== Checking Configuration Files ==="
    check_file ".gitignore" "required"
    check_file ".env.example" "optional"

    # Run additional checks
    check_dependencies
    check_docker_files
    check_cicd
    check_distribution
    check_entry_points
    check_installation
    check_no_private_files

    # Run smoke tests if no critical failures
    if [ $FAILED -eq 0 ]; then
        run_smoke_test
    else
        print_status "$YELLOW" "\nSkipping smoke tests due to critical failures"
    fi

    # Generate report
    generate_report

    # Final summary
    print_status "$BLUE" "\n=== Validation Complete ==="
    print_status "$GREEN" "Passed: $PASSED checks"
    print_status "$RED" "Failed: $FAILED checks"
    print_status "$YELLOW" "Warnings: $WARNINGS checks"

    if [ $FAILED -eq 0 ]; then
        print_status "$GREEN" "\n✅ Repository structure is VALID for public release"
        exit 0
    else
        print_status "$RED" "\n❌ Repository structure is INVALID - fixes required"
        exit 1
    fi
}

# Run main function
main
