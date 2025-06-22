#!/usr/bin/env bash
# Download wheels for all dependencies and generate offline requirements files
set -euo pipefail

mkdir -p wheelhouse

pip download -r requirements.txt -d wheelhouse
pip download -r requirements-dev.txt -d wheelhouse

# Remove GitHub and VCS references for offline installs
sed '/git+.*github.com/d' requirements.txt > requirements-no-github.txt
sed '/git+.*github.com/d' requirements-dev.txt > requirements-dev-no-github.txt

echo "Offline bundle created in wheelhouse/"
