# Codex Development Setup

This repository includes a helper script `codex-setup.sh` for preparing a local
Codex development environment. The script installs the Qt dependencies required
for running the PyQt test suite, supports offline installation using a
`wheelhouse/` directory and starts an Xvfb display for headless testing.

## Usage

```bash
./codex-setup.sh
```

The script will:

1. Detect your operating system (macOS or Linux).
2. Install Qt build dependencies (`libx11-dev`, `libgl1-mesa-dev`, `xvfb`, etc.).
3. Install Python requirements. If network installation fails and a `wheelhouse/`
   directory exists, packages are installed from that directory using
   `pip --no-index`.
4. Launch an Xvfb display on `:99` and export the `DISPLAY` and
   `QT_QPA_PLATFORM=offscreen` variables so GUI tests run headlessly.

After running the script you can execute tests and linting using the predefined
commands in `.codexrc`:

```bash
codex test   # Runs xvfb-run -a pytest -q
codex lint   # Runs flake8
codex build  # Builds distribution with python -m build
```

See the `.codexrc` file for the exact commands.
