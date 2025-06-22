# Homebrew Tap for Open WebUI Installer

This is the official Homebrew tap for Open WebUI Installer - an easy-to-use installer and manager for Open WebUI, a user-friendly AI interface that supports Ollama, OpenAI API, and more.

## Installation

First, tap this repository:

```bash
brew tap STEALTHTEMP1/openwebui-installer
```

Then install Open WebUI Installer:

```bash
brew install openwebui-installer
```

## Usage

After installation, you can use the installer with these commands:

```bash
# Install Open WebUI
openwebui-installer install

# Start Open WebUI service
openwebui-installer start

# Stop Open WebUI service
openwebui-installer stop

# Update Open WebUI to the latest version
openwebui-installer update

# Check status
openwebui-installer status

# Uninstall Open WebUI
openwebui-installer uninstall

# Show help and all available commands
openwebui-installer --help

# Show version information
openwebui-installer --version
```

## What is Open WebUI?

Open WebUI is a user-friendly web interface for AI models that supports:

- **Ollama** - Run local AI models
- **OpenAI API** - Connect to OpenAI's models
- **Custom APIs** - Connect to other AI services
- **Multiple Models** - Switch between different AI models easily
- **Chat Interface** - Clean, intuitive chat experience
- **Model Management** - Easy model installation and management

## Features of the Installer

- **One-command installation** - Get Open WebUI running with a single command
- **Automatic updates** - Keep your installation up-to-date
- **Service management** - Start, stop, and manage the Open WebUI service
- **Cross-platform** - Works on macOS, Linux, and Windows (via WSL)
- **Docker support** - Uses Docker for clean, isolated installations
- **Configuration management** - Easy setup and configuration

## Requirements

- macOS 10.15+ or Linux
- Docker (will be installed if not present)
- Internet connection for downloading models and updates

## Getting Help

If you encounter any issues:

1. Check the help command: `openwebui-installer --help`
2. Visit the main project: [Open WebUI](https://github.com/open-webui/open-webui)
3. Report issues: [Open WebUI Installer Issues](https://github.com/STEALTHTEMP1/openwebui-installer/issues)

## Uninstalling

To remove the installer:

```bash
brew uninstall openwebui-installer
brew untap STEALTHTEMP1/openwebui-installer
```

To also remove Open WebUI (if installed):

```bash
openwebui-installer uninstall  # Run this before uninstalling the installer
```

## Development

This tap is maintained separately from the main Open WebUI Installer project to provide easy Homebrew distribution while keeping the main project private.

For the latest releases and updates, this tap automatically tracks the main project's releases.

## License

This Homebrew tap is open source. The Open WebUI Installer software it installs may have its own license terms.