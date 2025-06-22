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
- Python 3.9 or later
- Docker Desktop for Mac
- Ollama

## Installation

### Using pip with virtual environment (Recommended)

```bash
# Create and activate a virtual environment
python3 -m venv openwebui-installer-env
source openwebui-installer-env/bin/activate

# Install the installer
pip install openwebui-installer
```

### Using Homebrew (Coming Soon)

The Homebrew tap is not yet available. Please use the pip installation method above.

```bash
# This will be available once the tap is created:
# brew tap open-webui/homebrew-tap
# brew install openwebui-installer
```

### Alternative: Install from source

```bash
# Clone the repository
git clone https://github.com/open-webui/openwebui-installer.git
cd openwebui-installer

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install in development mode
pip install -e .
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

## Troubleshooting

### Externally Managed Environment Error

If you get an "externally-managed-environment" error when using pip:

```bash
# Solution 1: Use virtual environment (recommended)
python3 -m venv openwebui-installer-env
source openwebui-installer-env/bin/activate
pip install openwebui-installer

# Solution 2: Use pipx (installs in isolated environment)
brew install pipx
pipx install openwebui-installer

# Solution 3: Use --user flag (not recommended)
pip install --user openwebui-installer
```

### Homebrew Tap Not Found

The error "Repository not found" for Homebrew tap indicates:

1. **The tap repository doesn't exist yet** - Use pip installation instead
2. **GitHub repository access issues** - Check your internet connection
3. **Incorrect tap name** - The repository should be named `homebrew-tap`

**Current Status**: The Homebrew tap is not yet available. Please use pip installation.

### Docker Not Running

If you get "Docker is not running" errors:

1. Install Docker Desktop for Mac from https://www.docker.com/products/docker-desktop
2. Start Docker Desktop
3. Verify Docker is running: `docker --version`

### Ollama Not Running

If you get "Ollama is not running" errors:

1. Install Ollama from https://ollama.ai
2. Start Ollama: `ollama serve`
3. Verify Ollama is running: `curl http://localhost:11434/api/tags`

### Python Version Issues

If you get Python version errors:

1. Check your Python version: `python3 --version`
2. Install Python 3.9 or later from https://python.org
3. Use the correct Python version in commands

## License

MIT License - see [LICENSE](LICENSE) file

## Security

Please report security issues to security@openwebui.com