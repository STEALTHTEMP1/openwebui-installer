#!/usr/bin/env python3
"""Compatibility entry point for invoking the installer via ``install.py``.

The official command line interface lives in :mod:`openwebui_installer.cli`.
This thin wrapper simply delegates to that entry point so existing scripts
calling ``python install.py`` continue to work.
"""

from openwebui_installer.cli import main


if __name__ == "__main__":
    main()
