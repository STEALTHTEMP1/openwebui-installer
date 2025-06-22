#!/usr/bin/env bash
# Create a virtual environment and install development dependencies from local wheelhouse
set -euo pipefail

ENV_DIR=".venv"
python3 -m venv "$ENV_DIR"
# shellcheck disable=SC1090
source "$ENV_DIR/bin/activate"

pip install --upgrade pip
pip install --no-index --find-links=wheelhouse -r requirements-dev-no-github.txt

echo "Offline development environment ready in $ENV_DIR"
