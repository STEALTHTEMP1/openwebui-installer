# Remaining Improvement Tasks

This file tracks pending refactor and enhancement tasks for the OpenWebUI Installer.

## High Priority

1. **Refactor `Installer.install` logic** (`openwebui_installer/installer.py`)
   - Split the method into helpers (`_pull_image`, `_pull_model`, `_create_launch_script`, `_start_container`).
   - Implement rollback if container start fails (remove pulled images, delete created configs).
2. **Add Docker client cleanup**
   - Provide a `close()` method or context manager on `Installer` to release `docker.from_env()` resources.
   - Ensure CLI and GUI close the client when done.
3. **Improve error handling**
   - Replace broad `except Exception` blocks in CLI and GUI with specific `InstallerError` and `SystemRequirementsError` handling.
   - Surface user‑friendly messages while logging stack traces for debugging.
4. **Extend CLI commands** (`openwebui_installer/cli.py`)
   - Implement `start`, `stop`, and `update` commands reusing new `Installer` methods.
   - Update help text and README examples accordingly.

## Medium Priority

5. **Dedicated container lifecycle methods** (`installer.py`)
   - Add `_start_container`, `_stop_container`, and `_remove_volume` helpers used by both `install()` and `uninstall()`.
   - Verify volume existence before removal to avoid errors.
6. **GUI responsiveness improvements** (`openwebui_installer/gui.py`)
   - Add timeouts to long‑running operations and emit progress updates regularly.
   - Consider moving heavy subprocess calls to worker processes if threading is insufficient.
7. **Structured logging**
   - Introduce a logging module used across CLI, GUI, and installer to capture debug information.
   - Replace `print` and `QMessageBox` error display with logging plus user messages.

## Low Priority

8. **Type hints and code style**
   - Add missing type annotations throughout the project and run static analysis (`mypy`).
9. **Integration and cross‑platform tests**
   - Create tests covering container lifecycle on Linux and macOS environments using GitHub Actions.
10. **Parameterize Docker image/tag**
    - Allow overriding the OpenWebUI image via config or environment variable for easier updates.

