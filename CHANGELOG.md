# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-06-19

### Added
- Initial release of the Open WebUI Installer
- Command-line interface with install, uninstall, and status commands
- Graphical user interface with installation progress tracking
- Docker Desktop integration with automatic download prompt
- Ollama integration with automatic installation via Homebrew
- System requirements validation
- Installation progress tracking
- Error handling and recovery
- Automatic cleanup on uninstall
- Custom port configuration support
- Custom Docker image support
- Comprehensive test suite
- GitHub Actions workflows for CI/CD
- Homebrew formula for easy installation

### Dependencies
- Python 3.9 or later
- Docker Desktop for Mac
- Ollama
- PyQt6 for GUI
- Click for CLI
- Docker SDK for Python

### Security
- Upfront permission requests
- Secure handling of Docker and Ollama interactions
- Input validation and sanitization

### Developer Experience
- Detailed documentation
- Release process automation
- Test coverage reporting
- Code quality checks
- Security scanning 
