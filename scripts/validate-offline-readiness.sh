#!/usr/bin/env bash
# Validate that all dependencies can be installed from the local wheelhouse
set -euo pipefail

if [ ! -d wheelhouse ]; then
  echo "wheelhouse directory not found" >&2
  exit 1
fi

python3 -m venv offline-validate-env
# shellcheck disable=SC1090
source offline-validate-env/bin/activate

pip install --upgrade pip
pip install --no-index --find-links=wheelhouse -r requirements-dev-no-github.txt

echo "Offline installation successful."

deactivate
rm -rf offline-validate-env
