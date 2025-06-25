# Open WebUI Homebrew Tap

This is the official Homebrew tap for Open WebUI tools and utilities.

> **Note**: As part of the **Universal Container App Store** initiative, this tap will eventually distribute additional containerized applications beyond Open WebUI.

## Available Formulae

- `openwebui-installer`: Official installer for Open WebUI with native Ollama integration for macOS

## Installation

First, add the tap:

```bash
brew tap open-webui/tap
```

Then install the desired formula and launch Open WebUI:

```bash
brew install openwebui-installer
openwebui-installer install  # runs the standard Docker command
```

### Upgrading

To upgrade `openwebui-installer` to the latest release, run:

```bash
brew update
brew upgrade openwebui-installer
```

## Development

The formulae in this tap are automatically updated by GitHub Actions when new releases are published.

### Manual Formula Updates

If you need to update a formula manually:

1. Update the formula file in the `Formula` directory
2. Test the formula locally:
   ```bash
   brew install --build-from-source Formula/formula-name.rb
   ```
3. Create a pull request with your changes

## License

MIT License 