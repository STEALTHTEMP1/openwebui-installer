#!/usr/bin/env bash
# Create a virtual environment and install development dependencies online
set -euo pipefail

ENV_DIR=".venv"
python3 -m venv "$ENV_DIR"
# shellcheck disable=SC1090
source "$ENV_DIR/bin/activate"

pip install --upgrade pip
pip install -r requirements-dev.txt

echo "Development environment ready in $ENV_DIR"
