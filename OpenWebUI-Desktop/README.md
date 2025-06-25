# 🧠 OpenWebUI Desktop

**Level 3 Complete Abstraction - Native macOS App for Open WebUI**

> **Note**: This desktop wrapper is now maintained under the **Universal Container App Store** umbrella and may be distributed through the store alongside other containerized apps.

A native macOS application that provides seamless desktop integration for Open WebUI with **zero Docker knowledge required**. Download, drag to Applications, double-click, and start chatting with AI in under 30 seconds.

## ✨ Features

### 🎯 Level 3 Complete Abstraction
- **No Docker Desktop Required** - Bundled lightweight container runtime (~30MB)
- **Instant Startup** - Pre-bundled Open WebUI image, no downloads needed
- **Zero Technical Knowledge** - Users never see Docker or containers
- **Complete Offline Mode** - Works without internet after first launch
- **Native Mac Experience** - Dock integration, notifications, menu bar

### 🚀 Professional Features
- **Auto-Updates** - Sparkle framework for delta updates
- **One-Click Diagnostics** - Built-in troubleshooting and log collection
- **Export Conversations** - Save chats as Markdown, JSON, or plain text
- **Resource Optimization** - Battery-aware and memory-efficient
- **Intelligent Recovery** - Automatic error detection and self-healing

## 📋 System Requirements

- **macOS**: 10.15 (Catalina) or later
- **Architecture**: Intel x86_64 or Apple Silicon ARM64
- **Memory**: 4GB RAM minimum, 8GB recommended
- **Storage**: 3GB available space
- **Network**: Internet connection for initial setup only

## 🚀 Quick Start

### For Users

1. **Download** `OpenWebUI.dmg` from [Releases](https://github.com/STEALTHTEMP1/openwebui-installer/releases)
2. **Open** the DMG file
3. **Drag** OpenWebUI.app to Applications folder
4. **Launch** from Applications or Dock
5. **Wait** ~30 seconds for first-time setup
6. **Start chatting** with AI!

### For Developers

#### Prerequisites

```bash
# Install Xcode 14.0+ with Command Line Tools
xcode-select --install

# Ensure you have an Apple Developer account for code signing
```

#### Build Instructions

1. **Clone and Setup**
```bash
git clone https://github.com/STEALTHTEMP1/openwebui-installer.git
cd openwebui-installer/OpenWebUI-Desktop-Clean/OpenWebUI-Desktop
```

2. **Bootstrap Environment**
```bash
../scripts/bootstrap.sh
```

3. **Download Runtime Components** ⚠️ **Required Step**
```bash
# Make script executable
chmod +x ../../scripts/bundle-resources.sh

# Download Podman and Open WebUI image (~1.5GB download)
../../scripts/bundle-resources.sh

# Verify bundle (optional)
../../scripts/bundle-resources.sh --verify
```

> **📝 Note**: The large bundled runtime files (Podman binary ~41MB, OpenWebUI image ~1.5GB) are not included in the git repository due to GitHub's 100MB file size limit. You must run the `bundle-resources.sh` script to download these components locally before building the app.

4. **Open in Xcode**
```bash
open OpenWebUI-Desktop.xcodeproj
```

5. **Configure Code Signing**
   - Select your Development Team in project settings
   - Update Bundle Identifier if needed
   - Ensure "Automatically manage signing" is enabled

6. **Build and Run**
   - Product → Build (⌘B)
   - Product → Run (⌘R)

## 🏗️ Architecture

### Level 3 Complete Abstraction Design

```
┌─────────────────────────────────────┐
│        OpenWebUI.app Bundle         │  <- User sees only this
├─────────────────────────────────────┤
│  SwiftUI Native Interface           │  <- Native macOS UI
│  └─ WKWebView (Open WebUI)          │  <- Embedded web interface
├─────────────────────────────────────┤
│  Container Management (Swift)       │  <- Intelligent abstraction
│  └─ Automatic error recovery        │  <- Self-healing
├─────────────────────────────────────┤
│  Bundled Container Runtime          │  <- No Docker Desktop needed
│  ├─ Podman Binary (~30MB)           │  <- Rootless containers
│  └─ Open WebUI Image (~80MB)        │  <- Pre-bundled, offline-ready
└─────────────────────────────────────┘
```

### Key Components

- **`OpenWebUIApp.swift`** - Main app entry point and lifecycle
- **`ContainerManager.swift`** - Core container orchestration (ported from Python)
- **`AppState.swift`** - State management and data models
- **`SetupView.swift`** - First-run setup and progress UI
- **`WebView.swift`** - WKWebView wrapper with native enhancements
- **`ErrorView.swift`** - Error handling with recovery options
- **`SettingsView.swift`** - Configuration and preferences
- **`DiagnosticsView.swift`** - Built-in troubleshooting tools

## 🛠️ Development Guide

### Project Structure

```
OpenWebUI-Desktop/
├── OpenWebUI-Desktop.xcodeproj      # Xcode project
├── OpenWebUI-Desktop/               # Source code
│   ├── Models/                      # Data models and state
│   ├── Views/                       # SwiftUI views
│   ├── Managers/                    # Business logic
│   └── Resources/                   # Assets and configs
├── Bundled-Runtime/                 # Runtime components
│   ├── podman                       # Container runtime binary
│   ├── openwebui-image.tar.gz       # Pre-bundled container image
│   └── bundle-info.json             # Metadata
└── Scripts/                         # Build and utility scripts
    └── bundle-resources.sh          # Resource bundling
```

### Code Reuse from Python Installer

This native app ports proven logic from the existing Python installer:

- **Container Management** - `installer.py` → `ContainerManager.swift`
- **Error Handling** - User-friendly error messages preserved
- **Health Monitoring** - Automatic recovery patterns maintained
- **Configuration** - Settings and preferences migrated

### Testing

```bash
# Run unit tests
xcodebuild test -scheme OpenWebUI-Desktop

# Test resource bundling
../../scripts/bundle-resources.sh --verify

# Manual testing checklist
# □ First launch setup completes
# □ Container starts successfully
# □ Web interface loads properly
# □ Error recovery works
# □ Settings persist correctly
```

### Building Release Version

```bash
# Build for distribution
xcodebuild archive -scheme OpenWebUI-Desktop \
  -archivePath OpenWebUI-Desktop.xcarchive

# Export signed app
xcodebuild -exportArchive -archivePath OpenWebUI-Desktop.xcarchive \
  -exportPath . -exportOptionsPlist ExportOptions.plist

# Create DMG (requires create-dmg)
create-dmg --volname "OpenWebUI Desktop" \
  --window-size 600 400 \
  --app-drop-link 400 200 \
  OpenWebUI-Desktop.dmg \
  OpenWebUI-Desktop.app
```

## 📊 Performance Metrics

### Target Performance
- **App Size**: <200MB total download
- **Memory Usage**: <500MB RAM (vs 1GB+ Docker Desktop)
- **First Launch**: <30 seconds complete setup
- **Subsequent Launches**: <5 seconds to ready
- **Container Start**: <10 seconds
- **Web UI Load**: <3 seconds

### Resource Optimization
- **Battery Aware**: Reduces CPU/memory usage on low battery
- **Memory Limits**: Container automatically configured based on available RAM
- **Disk Cleanup**: Automatic cleanup of logs and temporary files
- **Network Efficiency**: All resources bundled, no runtime downloads

## 🔧 Troubleshooting

### Common Issues

#### "App is damaged and can't be opened"
```bash
# Clear quarantine attribute
xattr -cr /Applications/OpenWebUI.app
```

#### Container fails to start
1. Check available disk space (need 3GB+)
2. Verify port 3000 is not in use
3. Generate diagnostic report from app menu
4. Check Console.app for detailed logs

#### Performance issues
1. Close other applications to free memory
2. Check Activity Monitor for resource usage
3. Restart the app to reset container
4. Ensure you have adequate free disk space
5. Run `../scripts/clean-xcode.sh` to clear caches and verify the runtime

### Diagnostic Tools

The app includes built-in diagnostic tools:

1. **Settings → Generate Diagnostic Report** - Creates comprehensive system report
2. **View → Container Logs** - Real-time container output
3. **Help → System Information** - Hardware and software details
4. **Advanced → Reset Container** - Clean slate restart

## 🤝 Contributing

### Development Setup

1. **Fork** the repository
2. **Clone** your fork locally
3. **Follow** the build instructions above
4. **Create** a feature branch
5. **Test** thoroughly on different Mac configurations
6. **Submit** a pull request with detailed description

### Code Style

- **Swift**: Follow Swift API Design Guidelines
- **SwiftUI**: Use declarative patterns and state management
- **Comments**: Document complex business logic
- **Error Handling**: Provide user-friendly error messages
- **Testing**: Include unit tests for new features

### Contribution Areas

- 🐛 **Bug Fixes** - Help improve stability
- ✨ **Features** - Enhance user experience
- 📚 **Documentation** - Improve setup guides
- 🧪 **Testing** - Expand test coverage
- 🎨 **UI/UX** - Polish the interface
- 🔧 **Performance** - Optimize resource usage

## 📄 License

This application embeds Open WebUI, which is licensed under a modified BSD-3-Clause license.

**Copyright (c) 2023-2024 Timothy Jaeryang Baek**

The native macOS wrapper is developed independently and provides a desktop interface for Open WebUI while preserving all original branding and attribution as required by the Open WebUI license.

For full license details, see [LICENSE](LICENSE) and visit the [Open WebUI repository](https://github.com/open-webui/open-webui).

## 🙏 Acknowledgments

- **Open WebUI Team** - For creating an excellent AI interface
- **Timothy Jaeryang Baek** - Open WebUI creator and maintainer
- **Containers Community** - For Podman and container technologies
- **Apple Developer Community** - For SwiftUI and macOS frameworks

## 🔗 Links

- **Open WebUI Project**: https://github.com/open-webui/open-webui
- **Issues & Support**: https://github.com/STEALTHTEMP1/openwebui-installer/issues
- **Documentation**: https://docs.openwebui.com
- **Community**: https://discord.gg/5rJgQTnV4s

---

**Transform your AI experience with native macOS integration! 🚀**