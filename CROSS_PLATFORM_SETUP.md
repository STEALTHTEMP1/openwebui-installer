# Cross-Platform Setup Guide

This guide outlines the recommended steps to prepare a development environment on **macOS** and **Linux**. The same steps are used in the CI workflows so local builds behave like the automated tests.

## Requirements

- **Python 3.9+**
- **Docker** (Docker Desktop or compatible engine)
- `bash`, `curl`, and common build tools

## 1. Clone the repository

```bash
git clone https://github.com/STEALTHTEMP1/openwebui-installer.git
cd openwebui-installer
```

## 2. Run the setup script

Use the helper script to install all dependencies and configure a virtual environment. The script detects your OS and installs the required packages.

```bash
./codex-setup.sh --full
```

This installs Python packages, Qt dependencies and sets up headless testing (Xvfb on Linux or XQuartz on macOS).

## 3. Start the development environment

```bash
./dev.sh start
```

This command builds the Docker images if needed and starts the services defined in `docker-compose.dev.yml`.

## 4. Open a development shell

```bash
./dev.sh shell
```

Inside the shell you can run tests, lint the code and build documentation just like the CI jobs:

```bash
pytest tests/
black .
isort .
```

## CI parity

The GitHub Actions workflows call the same setup commands on both macOS and Ubuntu runners. Following the steps above ensures your local environment matches the CI configuration.

