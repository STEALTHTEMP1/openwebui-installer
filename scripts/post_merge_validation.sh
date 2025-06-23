#!/bin/bash

# Comprehensive post-merge validation for Universal App Store
# Ensures all merges maintained system integrity

# Load utility libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/error_handling.sh"
source "$SCRIPT_DIR/lib/resource_manager.sh"
source "$SCRIPT_DIR/lib/lock_manager.sh"
source "$SCRIPT_DIR/lib/dependency_checker.sh"
source "$SCRIPT_DIR/lib/git_cache.sh"
source "$SCRIPT_DIR/lib/input_sanitizer.sh"

# Check dependencies
check_dependencies

# Acquire lock for this operation
if ! acquire_lock "post_merge_validation"; then
    log_error "Another validation is already running"
    exit 1
fi
auto_release_lock "post_merge_validation"

echo "🔍 Post-Merge Validation - Universal App Store"
echo "=============================================="

VALIDATION_FAILED=false
VALIDATION_REPORT=".branch-analysis/validation_report_$(timestamp).md"
register_temp_file "$VALIDATION_REPORT"

# Initialize validation report
cat > "$VALIDATION_REPORT" << EOF
# Post-Merge Validation Report

**Timestamp**: $(iso_timestamp)
**Branch**: $(git_current_branch)
**Commit**: $(safe_git rev-parse HEAD)

## Validation Results

EOF

log_result() {
    local test_name=$1
    local status=$2
    local details=$3

    if [[ "$status" == "PASS" ]]; then
        log_info "✅ $test_name"
        echo "- ✅ **$test_name**: PASSED" >> "$VALIDATION_REPORT"
    elif [[ "$status" == "SKIP" ]]; then
        log_warn "⏭️  $test_name"
        echo "- ⏭️  **$test_name**: SKIPPED" >> "$VALIDATION_REPORT"
    else
        log_error "❌ $test_name"
        echo "- ❌ **$test_name**: FAILED" >> "$VALIDATION_REPORT"
        VALIDATION_FAILED=true
    fi

    if [[ -n "$details" ]]; then
        log_debug "Details: $details"
        echo "  - Details: $details" >> "$VALIDATION_REPORT"
    fi
}

# Start timing
start_timer "post_merge_validation"

# Test 1: Critical Files Exist
log_info "Testing critical file existence..."
CRITICAL_FILES=(
    "install.py"
    "openwebui_installer/cli.py"
    "openwebui_installer/installer.py"
    "openwebui_installer/gui.py"
    "OpenWebUI-Desktop/OpenWebUI-Desktop/OpenWebUIApp.swift"
    "OpenWebUI-Desktop/OpenWebUI-Desktop/ContentView.swift"
    "appstore.md"
    "UNIVERSAL_ROADMAP.md"
    "smart_merge.sh"
    "pyproject.toml"
)

MISSING_FILES=()
for file in "${CRITICAL_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
        MISSING_FILES+=("$file")
    fi
done

if [[ ${#MISSING_FILES[@]} -eq 0 ]]; then
    log_result "Critical Files Exist" "PASS" "All critical files present"
else
    log_result "Critical Files Exist" "FAIL" "Missing: ${MISSING_FILES[*]}"
fi

# Test 2: Python Syntax Validation
log_info "Testing Python syntax..."
PYTHON_ERRORS=()
for py_file in $(find . -name "*.py" -not -path "./.git/*" -not -path "./venv/*" -not -path "./.venv/*" -not -path "./.branch-analysis/*" 2>/dev/null); do
    # Validate file path
    py_file=$(validate_file_path "$py_file")
    if ! python3 -m py_compile "$py_file" 2>/dev/null; then
        PYTHON_ERRORS+=("$py_file")
    fi
done

if [[ ${#PYTHON_ERRORS[@]} -eq 0 ]]; then
    log_result "Python Syntax" "PASS" "All Python files compile"
else
    log_result "Python Syntax" "FAIL" "Syntax errors in: ${PYTHON_ERRORS[*]}"
fi

# Test 3: Swift Syntax Validation (if available)
if command -v xcrun >/dev/null 2>&1; then
    log_info "Testing Swift syntax..."
    SWIFT_ERRORS=()
    for swift_file in $(find OpenWebUI-Desktop -name "*.swift" 2>/dev/null || true); do
        swift_file=$(validate_file_path "$swift_file")
        if ! xcrun swift -typecheck "$swift_file" 2>/dev/null; then
            SWIFT_ERRORS+=("$swift_file")
        fi
    done

    if [[ ${#SWIFT_ERRORS[@]} -eq 0 ]]; then
        log_result "Swift Syntax" "PASS" "All Swift files compile"
    else
        log_result "Swift Syntax" "FAIL" "Syntax errors in: ${SWIFT_ERRORS[*]}"
    fi
else
    log_result "Swift Syntax" "SKIP" "Xcode tools not available"
fi

# Test 4: Import Validation
log_info "Testing Python imports..."
IMPORT_ERRORS=()

# Test main CLI import
if ! python3 -c "
import sys
sys.path.insert(0, '.')
try:
    from openwebui_installer.cli import main
    print('CLI import: OK')
except Exception as e:
    print(f'CLI import failed: {e}')
    exit(1)
" 2>/dev/null; then
    IMPORT_ERRORS+=("CLI main import")
fi

# Test installer import
if ! python3 -c "
import sys
sys.path.insert(0, '.')
try:
    from openwebui_installer.installer import Installer
    print('Installer import: OK')
except Exception as e:
    print(f'Installer import failed: {e}')
    exit(1)
" 2>/dev/null; then
    IMPORT_ERRORS+=("Installer class import")
fi

# Test GUI import (might fail if PyQt6 not installed)
if ! python3 -c "
import sys
sys.path.insert(0, '.')
try:
    from openwebui_installer.gui import main
    print('GUI import: OK')
except Exception as e:
    print(f'GUI import failed: {e}')
    exit(1)
" 2>/dev/null; then
    IMPORT_ERRORS+=("GUI main import (PyQt6 may not be installed)")
fi

if [[ ${#IMPORT_ERRORS[@]} -eq 0 ]]; then
    log_result "Python Imports" "PASS" "All critical imports successful"
else
    log_result "Python Imports" "FAIL" "Import errors: ${IMPORT_ERRORS[*]}"
fi

# Test 5: Merge Conflict Artifacts
log_info "Testing for merge conflict artifacts..."
CONFLICT_ARTIFACTS=$(find . -name "*.py" -o -name "*.swift" -o -name "*.md" -o -name "*.toml" | xargs grep -l "<<<<<<\|======\|>>>>>>" 2>/dev/null || echo "")

if [[ -z "$CONFLICT_ARTIFACTS" ]]; then
    log_result "Merge Conflict Artifacts" "PASS" "No conflict markers found"
else
    log_result "Merge Conflict Artifacts" "FAIL" "Found conflict markers in: $CONFLICT_ARTIFACTS"
fi

# Test 6: Universal App Store Components
log_info "Testing Universal App Store components..."
APPSTORE_COMPONENTS=(
    "appstore.md"
    "UNIVERSAL_ROADMAP.md"
    "OpenWebUI-Desktop/OpenWebUI-Desktop/OpenWebUIApp.swift"
    "OpenWebUI-Desktop/OpenWebUI-Desktop/ContentView.swift"
)

MISSING_APPSTORE=()
for component in "${APPSTORE_COMPONENTS[@]}"; do
    if [[ ! -f "$component" ]]; then
        MISSING_APPSTORE+=("$component")
    fi
done

if [[ ${#MISSING_APPSTORE[@]} -eq 0 ]]; then
    log_result "Universal App Store Components" "PASS" "All components present"
else
    log_result "Universal App Store Components" "FAIL" "Missing: ${MISSING_APPSTORE[*]}"
fi

# Test 7: CLI Runtime Support
log_info "Testing CLI runtime support..."
if [[ -f "openwebui_installer/cli.py" ]] && grep -q "runtime.*str" openwebui_installer/cli.py; then
    log_result "CLI Runtime Support" "PASS" "Runtime parameter support detected"
else
    log_result "CLI Runtime Support" "FAIL" "Runtime parameter support missing"
fi

# Test 8: Swift ContainerManager
log_info "Testing Swift ContainerManager..."
if [[ -f "OpenWebUI-Desktop/OpenWebUI-Desktop/Models/ContainerManager.swift" ]]; then
    log_result "Swift ContainerManager" "PASS" "ContainerManager.swift exists"
else
    log_result "Swift ContainerManager" "FAIL" "ContainerManager.swift missing"
fi

# Test 9: Duplicate Directory Check
log_info "Testing for duplicate directories..."
DUPLICATE_ISSUES=()
if [[ -d "openwebui-installer" && -d "openwebui_installer" ]]; then
    DUPLICATE_ISSUES+=("Both openwebui-installer and openwebui_installer directories exist")
fi

if [[ ${#DUPLICATE_ISSUES[@]} -eq 0 ]]; then
    log_result "Duplicate Directories" "PASS" "No duplicate directories found"
else
    log_result "Duplicate Directories" "FAIL" "${DUPLICATE_ISSUES[*]}"
fi

# Test 10: Basic Functionality Test
log_info "Testing basic functionality..."
BASIC_TEST_ERRORS=()

# Test CLI help
if ! python3 -c "
import sys
sys.path.insert(0, '.')
from openwebui_installer.cli import cli
try:
    # Mock sys.argv for testing
    import sys
    original_argv = sys.argv
    sys.argv = ['cli', '--help']
    try:
        cli()
    except SystemExit as e:
        if e.code == 0:
            print('CLI help: OK')
        else:
            raise
    finally:
        sys.argv = original_argv
except Exception as e:
    print(f'CLI help failed: {e}')
    exit(1)
" 2>/dev/null; then
    BASIC_TEST_ERRORS+=("CLI help command")
fi

# Test installer instantiation
if ! python3 -c "
import sys
sys.path.insert(0, '.')
try:
    from openwebui_installer.installer import Installer
    # Test both runtime modes
    installer_docker = Installer(runtime='docker')
    installer_podman = Installer(runtime='podman')
    print('Installer instantiation: OK')
except Exception as e:
    print(f'Installer instantiation failed: {e}')
    exit(1)
" 2>/dev/null; then
    BASIC_TEST_ERRORS+=("Installer instantiation")
fi

if [[ ${#BASIC_TEST_ERRORS[@]} -eq 0 ]]; then
    log_result "Basic Functionality" "PASS" "Core functionality works"
else
    log_result "Basic Functionality" "FAIL" "Issues: ${BASIC_TEST_ERRORS[*]}"
fi

# Test 11: Git Repository Integrity
log_info "Testing Git repository integrity..."
GIT_ISSUES=()

# Check for uncommitted changes
if ! safe_git diff --quiet; then
    GIT_ISSUES+=("Uncommitted changes in working directory")
fi

# Check for untracked important files
UNTRACKED_IMPORTANT=$(safe_git ls-files --others --exclude-standard | grep -E "\.(py|swift|md|toml)$" | head -5 || echo "")
if [[ -n "$UNTRACKED_IMPORTANT" ]]; then
    GIT_ISSUES+=("Untracked important files: $(echo "$UNTRACKED_IMPORTANT" | tr '\n' ' ')")
fi

if [[ ${#GIT_ISSUES[@]} -eq 0 ]]; then
    log_result "Git Repository Integrity" "PASS" "Repository is clean"
else
    log_result "Git Repository Integrity" "FAIL" "${GIT_ISSUES[*]}"
fi

# Test 12: Universal App Store Schema Validation
log_info "Testing Universal App Store schema..."
SCHEMA_ISSUES=()

# Check if appstore.md contains required sections
if [[ -f "appstore.md" ]]; then
    REQUIRED_SECTIONS=(
        "Universal Container App Store"
        "FR-001: App Store Catalog Interface"
        "FR-002: Multi-Container Management"
        "FR-003: App Configuration System"
        "FR-004: Download-on-Demand System"
        "FR-005: Model Context Protocol"
    )

    for section in "${REQUIRED_SECTIONS[@]}"; do
        if ! grep -q "$section" appstore.md; then
            SCHEMA_ISSUES+=("Missing section: $section")
        fi
    done
fi

if [[ ${#SCHEMA_ISSUES[@]} -eq 0 ]]; then
    log_result "Universal App Store Schema" "PASS" "All required sections present"
else
    log_result "Universal App Store Schema" "FAIL" "${SCHEMA_ISSUES[*]}"
fi

# End timing
VALIDATION_DURATION=$(end_timer "post_merge_validation")

# Generate summary
echo ""
echo "📊 Validation Summary"
echo "===================="

# Write summary to report
cat >> "$VALIDATION_REPORT" << EOF

## Summary

**Validation Date**: $(iso_timestamp)
**Total Tests**: 12
**Duration**: ${VALIDATION_DURATION}s
**Repository State**: $(if [[ "$VALIDATION_FAILED" == "false" ]]; then echo "✅ HEALTHY"; else echo "❌ ISSUES DETECTED"; fi)

## Recommendations

EOF

if [[ "$VALIDATION_FAILED" == "false" ]]; then
    log_info "✅ All validations passed!"
    log_info "🎉 Universal App Store merge process completed successfully"
    echo ""
    echo "Next steps:"
    echo "1. Test the Universal App Store functionality manually"
    echo "2. Run the Swift app to verify UI components"
    echo "3. Test CLI commands with both Docker and Podman"
    echo "4. Continue with Universal App Store development"

    cat >> "$VALIDATION_REPORT" << EOF
✅ **All validations passed!** The Universal App Store codebase is ready for development.

### Next Steps:
1. Test Universal App Store functionality manually
2. Run Swift app to verify UI components
3. Test CLI commands with both Docker and Podman
4. Continue with Universal App Store development roadmap
EOF
else
    log_error "❌ Some validations failed"
    log_warn "⚠️  Please review the issues above and resolve them"
    echo ""
    echo "Common fixes:"
    echo "1. Run: python3 -m py_compile on failed Python files"
    echo "2. Check for merge conflict markers and resolve them"
    echo "3. Ensure all required Universal App Store files are present"
    echo "4. Test imports and fix any missing dependencies"

    cat >> "$VALIDATION_REPORT" << EOF
❌ **Some validations failed.** Please review and resolve the issues above.

### Common Fixes:
1. Run \`python3 -m py_compile\` on failed Python files
2. Check for merge conflict markers and resolve them
3. Ensure all required Universal App Store files are present
4. Test imports and fix any missing dependencies

### Manual Verification:
- Test CLI: \`python3 -m openwebui_installer.cli --help\`
- Test imports: \`python3 -c "from openwebui_installer.installer import Installer"\`
- Check Swift compilation if Xcode is available
EOF
fi

echo ""
log_info "📄 Detailed report saved to: $VALIDATION_REPORT"
echo -e "⏱️  Validation completed in: ${BLUE}${VALIDATION_DURATION}s${NC}"

# Create success/failure indicator file
if [[ "$VALIDATION_FAILED" == "false" ]]; then
    touch ".branch-analysis/validation_success"
    log_info "🎯 Universal App Store is ready for development!"
    exit 0
else
    touch ".branch-analysis/validation_failed"
    log_error "🚨 Please resolve validation issues before proceeding"
    exit 1
fi
