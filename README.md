# Open WebUI Installer

Official installer for Open WebUI with native Ollama integration for macOS.

## Features

- Easy installation of Open WebUI with native Ollama integration
- Both command-line and graphical user interfaces
- Automatic system requirements validation
- Docker and Ollama integration
- Model selection and management
- Easy uninstallation and cleanup

## Requirements

- macOS 12 (Monterey) or later
- Python 3.8 or later
- Docker Desktop for Mac
- Ollama

## Installation

### Using Homebrew (Recommended)

```bash
# Add the tap
brew tap open-webui/tap

# Install the installer
brew install openwebui-installer
```

### Using pip

```bash
pip install openwebui-installer
```

## Usage

### Command Line Interface

```bash
# Show help
openwebui-installer --help

# Install with default settings (llama2 model, port 3000)
openwebui-installer install

# Install with custom model and port
openwebui-installer install --model codellama --port 8080

# Check installation status
openwebui-installer status

# Uninstall
openwebui-installer uninstall
```

### Graphical Interface

```bash
# Launch the GUI
openwebui-installer-gui
```

## Development

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/open-webui/openwebui-installer.git
   cd openwebui-installer
   ```

2. Create a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Unix/macOS
   ```

3. Install development dependencies:
   ```bash
   pip install -r requirements-dev.txt
   ```

### Testing

```bash
# Run tests
pytest

# Run tests with coverage
pytest --cov=openwebui_installer

# Run specific test file
pytest tests/test_installer.py
```

### Code Quality

```bash
# Format code
black .
isort .

# Check code style
flake8 .

# Type checking
mypy .

# Security checks
bandit -r openwebui_installer
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - see [LICENSE](LICENSE) file

## Security

Please report security issues to security@openwebui.com 