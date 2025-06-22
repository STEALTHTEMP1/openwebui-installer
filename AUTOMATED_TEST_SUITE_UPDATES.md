# 🧪 Automated Test Suite Updates

## 🎯 Objective
Maintain a reliable and portable test suite that covers the CLI, installer, and GUI components. Ensure tests can run in CI environments on macOS and Linux, including headless setups.

## 📦 Scope
- **Python unit tests** located in `tests/test_cli.py` and `tests/test_installer.py` must be kept up to date with code changes.
- **GUI tests** in `tests/test_gui.py` should run reliably by providing the required Qt libraries or using a headless alternative such as `PyQt6==6.6` with the `minimal` plugin.
- **Installation script** (`install.py`) will be extended to support DMG-based installation when a DMG package becomes available.

## 🛠️ Requirements
1. **CI Compatibility**
   - Tests must run in GitHub Actions using the existing Python workflow.
   - Provide instructions or scripts to install Qt dependencies in CI for macOS and Linux runners.
   - Support headless test execution by setting `QT_QPA_PLATFORM=offscreen` when no display server is available.

2. **Test Maintenance**
   - Keep `tests/test_cli.py` and `tests/test_installer.py` in sync with new CLI commands and installer features.
   - Update mocks and fixtures to reflect changes in Docker interactions or configuration logic.

3. **GUI Test Support**
   - Ensure `tests/test_gui.py` uses a lightweight Qt backend and does not require a real display.
   - Document any additional packages needed for GUI tests in `requirements-dev.txt`.

4. **DMG Installation Support**
   - When a DMG build of Open WebUI is released, extend `install.py` so that users can choose between the current Docker-based method and DMG installation.
   - Provide unit tests verifying that the new DMG logic is executed when selected.

## 🚀 Deliverables
- Updated unit tests with clear comments and maintainable mocks.
- CI configuration snippets documenting how to install Qt libraries for headless runs.
- Placeholder functions in `install.py` for DMG installation with TODO markers until the DMG is available.
- Documentation within this repository describing how to run the full test suite locally and in CI.

