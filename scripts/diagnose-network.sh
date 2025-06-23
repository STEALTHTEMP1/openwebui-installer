#!/bin/bash

# diagnose-network.sh - Network connectivity diagnostics for Codex environments
# This script tests basic internet connectivity and access to common service endpoints.
# It should run on both macOS and Linux systems.

set -euo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo "🔍 Codex Network Connectivity Diagnostics"
    echo "=========================================="
    echo ""
}

# Helper to test TCP connectivity with a fallback if `timeout` is unavailable
check_port() {
    local host="$1"
    local port="$2"
    if command -v timeout >/dev/null 2>&1; then
        timeout 5 bash -c "</dev/tcp/$host/$port" 2>/dev/null
    elif command -v nc >/dev/null 2>&1; then
        nc -z -w5 "$host" "$port" >/dev/null 2>&1
    else
        # Fallback using bash TCP redirection with background sleep
        (exec 3<>"/dev/tcp/$host/$port") >/dev/null 2>&1
    fi
}

print_header

# Basic connectivity tests
echo "🌐 Basic Connectivity Tests:"
if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
    echo -e "  ✅ Internet connectivity: ${GREEN}OK${NC}"
else
    echo -e "  ❌ Internet connectivity: ${RED}FAILED${NC}"
fi

if ping -c 1 -W 5 1.1.1.1 >/dev/null 2>&1; then
    echo -e "  ✅ DNS resolution: ${GREEN}OK${NC}"
else
    echo -e "  ❌ DNS resolution: ${RED}FAILED${NC}"
fi

echo ""

echo "🎯 Service-Specific Tests:"
endpoints=(
    "github.com:443:GitHub (for git packages)"
    "pypi.org:443:PyPI (for pip packages)"
    "files.pythonhosted.org:443:PyPI CDN"
    "api.apple.com:443:Apple Notarization"
)

for endpoint in "${endpoints[@]}"; do
    IFS=':' read -r host port desc <<< "$endpoint"
    if check_port "$host" "$port"; then
        echo -e "  ✅ $desc: ${GREEN}OK${NC}"
    else
        echo -e "  ❌ $desc: ${RED}BLOCKED${NC}"
    fi
done

echo ""

echo "📦 Package Installation Tests:"

# Test pip access
if pip index versions pip >/dev/null 2>&1; then
    echo -e "  ✅ pip repository access: ${GREEN}OK${NC}"
else
    echo -e "  ❌ pip repository access: ${RED}FAILED${NC}"
fi

# Test GitHub package access (using requests package as example)
if pip index versions requests >/dev/null 2>&1; then
    echo -e "  ✅ Standard package access: ${GREEN}OK${NC}"
else
    echo -e "  ❌ Standard package access: ${RED}FAILED${NC}"
fi

echo ""

echo "🔧 Environment Information:"
echo "  • Platform: $(uname -s) $(uname -m)"
echo "  • Python: $(python --version 2>&1)"
echo "  • pip: $(pip --version 2>&1 | cut -d' ' -f1-2)"

if command -v curl >/dev/null 2>&1; then
    echo "  • curl: Available"
else
    echo "  • curl: Not available"
fi

if command -v wget >/dev/null 2>&1; then
    echo "  • wget: Available"
else
    echo "  • wget: Not available"
fi

echo ""

echo "💡 Recommendations:"

echo ""

if ! curl -s --connect-timeout 5 --head "https://github.com" >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  GitHub access blocked:${NC}"
    echo "   • Add 'allow_network': true to .codexrc"
    echo "   • Use wheelhouse/vendor directories for offline packages"
    echo "   • Consider pre-downloading GitHub packages"
    echo ""
fi

if ! curl -s --connect-timeout 5 --head "https://pypi.org" >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  PyPI access blocked:${NC}"
    echo "   • Enable internet access in Codex environment"
    echo "   • Use --find-links with local package cache"
    echo "   • Contact administrator for network policy"
    echo ""
fi

if [[ "$(uname)" == "Darwin" ]] && ! curl -s --connect-timeout 5 --head "https://api.apple.com" >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Apple services blocked:${NC}"
    echo "   • macOS notarization will fail"
    echo "   • Consider conditional notarization in build scripts"
    echo "   • Skip notarization step in restricted environments"
    echo ""
fi

echo "🔧 For full setup with network awareness:"
echo "   ./scripts/codex-setup-hardened.sh"

