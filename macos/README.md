# Open WebUI macOS App

This directory contains a minimal Swift package used as a starting point for the macOS wrapper around Open WebUI.

The Swift code calls the existing Python based installer so we can reuse the container management logic without rewriting it in Swift.

```bash
swift run
```

Running the package will execute `openwebui-installer install` using the same logic as our CLI.
