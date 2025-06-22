#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print status messages
print_status() {
    echo -e "${YELLOW}==> $1${NC}"
}

# Function to check command success
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1${NC}"
        exit 1
    fi
}

# Create test environment
print_status "Creating test environment..."
python3 -m venv test_env
source test_env/bin/activate
check_success "Test environment created"

# Test PyPI installation
print_status "Testing PyPI installation..."
pip install openwebui-installer
check_success "PyPI installation"

# Test CLI functionality
print_status "Testing CLI functionality..."
openwebui-installer --version
check_success "CLI version check"

openwebui-installer status
check_success "CLI status check"

# Test uninstallation
print_status "Testing uninstallation..."
openwebui-installer uninstall
check_success "CLI uninstallation"

# Clean up PyPI installation
pip uninstall -y openwebui-installer
deactivate
rm -rf test_env

# Test Homebrew installation
print_status "Testing Homebrew installation..."
brew tap open-webui/homebrew-tap
check_success "Homebrew tap added"

brew install openwebui-installer
check_success "Homebrew installation"

# Test CLI functionality again
print_status "Testing Homebrew CLI functionality..."
openwebui-installer --version
check_success "Homebrew CLI version check"

openwebui-installer status
check_success "Homebrew CLI status check"

# Test uninstallation
print_status "Testing Homebrew uninstallation..."
openwebui-installer uninstall
check_success "Homebrew CLI uninstallation"

# Clean up Homebrew installation
brew uninstall openwebui-installer
brew untap open-webui/homebrew-tap

# Test manual installation
print_status "Testing manual installation..."
git clone https://github.com/open-webui/openwebui-installer.git
cd openwebui-installer

# Create new test environment
python3 -m venv venv
source venv/bin/activate

# Install in development mode
pip install -e .
check_success "Manual installation"

# Test CLI functionality
print_status "Testing manual installation CLI functionality..."
openwebui-installer --version
check_success "Manual CLI version check"

openwebui-installer status
check_success "Manual CLI status check"

# Test uninstallation
print_status "Testing manual uninstallation..."
openwebui-installer uninstall
check_success "Manual CLI uninstallation"

# Clean up manual installation
deactivate
cd ..
rm -rf openwebui-installer

echo -e "${GREEN}All installation tests completed successfully!${NC}" 
