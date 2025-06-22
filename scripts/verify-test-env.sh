#!/bin/bash
# verify-test-env.sh - Verify Qt test environment for CI
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

printf "\n🔍 Verifying test environment...\n"

python --version
pip --version

if python - <<'PY'
import sys
try:
    import PyQt6.QtCore as QtCore
    print('PyQt6 version:', QtCore.PYQT_VERSION_STR)
    print('Qt version:', QtCore.QT_VERSION_STR)
except Exception as e:
    print('PyQt6 import failed:', e)
    sys.exit(1)
PY
then
    echo -e "${GREEN}✅ PyQt6 import successful${NC}"
else
    echo -e "${RED}❌ PyQt6 import failed${NC}"
    exit 1
fi

if [[ "$(uname)" == "Linux" ]]; then
    echo "Checking libEGL..."
    if ldconfig -p | grep -q libEGL.so.1; then
        echo -e "${GREEN}✅ libEGL.so.1 found${NC}"
    else
        echo -e "${RED}❌ libEGL.so.1 missing${NC}"
        exit 1
    fi
    export DISPLAY=:99
    export QT_QPA_PLATFORM=offscreen
    if ! pgrep -x Xvfb >/dev/null; then
        Xvfb :99 -screen 0 1024x768x24 >/dev/null 2>&1 &
        sleep 3
    fi
    if DISPLAY=:99 xdpyinfo >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Virtual display running${NC}"
    else
        echo -e "${RED}❌ Virtual display not running${NC}"
        exit 1
    fi
fi

printf "${GREEN}Environment ready for tests.${NC}\n"
