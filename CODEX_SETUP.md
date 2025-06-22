# Codex Environment Setup

The `codex-setup.sh` script prepares the development environment for running automated tests with Codex.

## Usage

1. Run the setup script:
   ```bash
   ./codex-setup.sh
   ```
2. The script installs Qt build dependencies using `apt-get` on Linux or Homebrew on macOS.
3. Python dependencies are installed from PyPI. If network access fails, place pre-built wheels in a `wheelhouse/` directory and rerun the script.
4. An Xvfb display is started on `:99` for headless PyQt tests.
5. The commands used by Codex are stored in `.codexrc`:
   - **Tests**: `xvfb-run -a pytest -q`
   - **Lint**: `black --check .`, `isort --check-only .`, `flake8 .`
   - **Build**: `python -m build`

After running `codex-setup.sh`, the environment is ready for running tests or CI workflows that rely on a virtual display.
