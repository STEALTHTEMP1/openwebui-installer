

# 📄 Universal Container App Store - Product Requirements Document

**Product Name:** Universal Container App Store for macOS  
**Code Name:** UniversalInstaller.app  
**Author:** Product Management Team  
**Date:** June 23, 2025  
**Version:** 2.0 (PIVOT - Expanded from OpenWebUI Installer)  
**Status:** APPROVED FOR DEVELOPMENT  

---

## 🎯 Executive Summary

**MAJOR PIVOT**: The project has evolved from a single OpenWebUI installer to a **Universal Container App Store** - the "App Store for Containerized AI/Productivity Tools." This represents a **10x larger market opportunity** by creating a platform for discovering, installing, and managing multiple containerized applications through a single native macOS interface.

**Vision:** Download one installer, browse an app store catalog, one-click install any AI or productivity tool, and use them seamlessly without ever knowing containers exist.

## 📊 Strategic Context & Market Opportunity

### **Market Evolution**
- **Before:** Fragmented container app installation (Docker Desktop + manual setup)
- **Current State:** Each containerized app requires technical setup
- **Our Opportunity:** First "App Store for Containers" with Level 3 abstraction
- **Market Size:** All Mac users wanting local AI/productivity tools (~50M+ users)

### **Competitive Landscape**
- **Docker Desktop:** Technical, developer-focused, resource-heavy
- **Individual App Installers:** Fragmented, no discovery, technical complexity  
- **Web-based Solutions:** Privacy concerns, internet dependency
- **Our Advantage:** Native macOS experience + app store discovery + zero technical knowledge required

---

## 👥 Target Users & Personas

### **Primary Users (90% of addressable market)**
- **Mac users** (Intel and Apple Silicon, macOS 10.15+)
- **Non-technical users** who avoid Terminal and Docker
- **AI enthusiasts** wanting local AI without complexity
- **Privacy-conscious users** preferring local tools over cloud services
- **Small business owners** needing productivity tools
- **Knowledge workers** seeking AI-powered workflows

### **User Mental Model**
Users think: *"I want AI tools"* (not "I want OpenWebUI specifically")
- They change tools frequently based on needs
- They want productivity-focused solutions
- They span many segments (design, writing, coding, analysis)
- They want an app store experience for discovery

### **User Expectations**
- ✅ **No Terminal usage** ever required
- ✅ **App Store-like experience** for discovery and installation
- ✅ **One-click install** for any tool
- ✅ **Zero container knowledge** required (Level 3 Complete Abstraction)
- ✅ **Multiple tools running** simultaneously
- ✅ **Native Mac integration** (Dock, notifications, window management)
- ✅ **Browse and discover** new tools easily

---

## 🏗️ Technical Architecture

### **Universal App Store Architecture**
```
┌─────────────────────────────────────────────────────────────┐
│                UniversalInstaller.app Bundle                │  <- Single installer app
├─────────────────────────────────────────────────────────────┤
│  App Store Catalog Interface (SwiftUI)                     │  <- Main user interface
│  ├─ Featured Apps (OpenWebUI promoted)                     │  <- Marketing/discovery
│  ├─ Browse by Category (AI, Drawing, Notes, Code)          │  <- User navigation
│  ├─ Search and Filter                                      │  <- App discovery
│  └─ Install/Manage installed apps                          │  <- App management
├─────────────────────────────────────────────────────────────┤
│  Multi-Frontend Container Management                        │  <- Generic container orchestration
│  ├─ App Configuration Registry                             │  <- JSON configs per app
│  ├─ Download-on-Demand System                              │  <- Container image management
│  ├─ Multi-App Status Monitoring                            │  <- Health checks for all apps
│  └─ Smart Browser Integration                              │  <- Launch apps in browser
├─────────────────────────────────────────────────────────────┤
│  Bundled Runtime + Base System                             │  <- Core infrastructure
│  ├─ Podman Binary (~30MB)                                  │  <- Container runtime
│  ├─ Featured App Image (OpenWebUI ~80MB)                   │  <- Bundled flagship app
│  └─ App Catalog Index                                      │  <- Available apps metadata
└─────────────────────────────────────────────────────────────┘
```

### **Smart Launcher + App Store Model**
- **Native SwiftUI interface** for app store catalog
- **Smart browser integration** - apps launch in user's default browser (Safari)
- **Multi-container orchestration** - multiple apps running simultaneously
- **Download-on-demand** - only featured apps bundled, others downloaded when selected
- **Configuration-driven** - new apps added via JSON configs, no code changes

---

## 🛠️ Core Functional Requirements

### **1. App Store Catalog Interface**
#### **Must-Have Features:**
- **Featured Apps Section** - Promoted tools (OpenWebUI featured initially)
- **Category Browsing** - AI & Chat, Design, Notes, Development, Monitoring, Productivity
- **Search and Filter** - Find apps by name, category, tags, description
- **App Detail Views** - Screenshots, descriptions, ratings, installation size
- **One-Click Installation** - Download and install with single button press
- **Installation Progress** - Real-time progress with time estimates

#### **App Card Information:**
- App name and icon
- Category and tags
- Brief description (2-3 lines)
- User rating/review count (future)
- Installation size and requirements
- Install/Launch/Settings buttons

### **2. Multi-Container Management**
#### **Must-Have Features:**
- **Simultaneous Apps** - Run 5+ apps concurrently without conflicts
- **Port Management** - Automatic port allocation and conflict resolution
- **Resource Allocation** - Smart memory and CPU limits per app
- **Health Monitoring** - Auto-restart failed containers, status reporting
- **Dependency Management** - Handle app-specific requirements automatically

#### **Container Lifecycle:**
- Download container image (with progress)
- Verify image integrity
- Configure networking and resources
- Start container with health checks
- Monitor and maintain running state
- Clean shutdown and resource cleanup

### **3. App Configuration System**
#### **JSON Configuration Format:**
```json
{
  "id": "openwebui",
  "name": "Open WebUI",
  "displayName": "AI Chat Assistant",
  "description": "User-friendly interface for AI models like ChatGPT, Claude, and local LLMs",
  "category": "ai-chat",
  "featured": true,
  "version": "0.3.8",
  "containerImage": "ghcr.io/open-webui/open-webui:main",
  "ports": [{"internal": 8080, "external": 3000}],
  "environment": {},
  "healthCheck": {"endpoint": "/health", "timeout": 30},
  "resources": {"minMemory": "512MB", "maxMemory": "2GB"},
  "screenshots": ["screenshot1.png", "screenshot2.png"],
  "bundled": true,
  "downloadSize": "1.2GB",
  "tags": ["ai", "chat", "llm", "local"]
}
```

### **4. Download-on-Demand System**
#### **Must-Have Features:**
- **Progressive Download** - Download container images as needed
- **Bandwidth Management** - Throttling and pause/resume capability
- **Integrity Verification** - Checksum validation of downloaded images
- **Storage Management** - Automatic cleanup of unused images
- **Offline Mode** - Bundled apps work without internet

---

## 🎨 User Experience Design

### **Main App Store Interface**
```
┌─────────────────────────────────────────────────────────────┐
│ 🔍 Search Apps                    ⚙️ Settings    📋 Library │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ 🌟 Featured                                                 │
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐            │
│ │🧠 Open WebUI│ │📐 Excalidraw│ │📝 Notion Alt│            │
│ │AI Assistant │ │Collaborative│ │Note Taking  │            │
│ │⭐⭐⭐⭐⭐     │ │Drawing      │ │& Wiki       │            │
│ │[INSTALL]    │ │⭐⭐⭐⭐      │ │⭐⭐⭐        │            │
│ └─────────────┘ └─────────────┘ └─────────────┘            │
│                                                             │
│ 🎯 Categories                                               │
│ [🧠 AI & Chat] [📐 Design] [📝 Notes] [💻 Code] [🎮 Games] │
│                                                             │
│ 📱 Browse All Apps                                          │
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐            │
│ │📊 Grafana   │ │🔒 Bitwarden │ │🌐 VS Code   │            │
│ │Monitoring   │ │Password Mgr │ │Code Editor  │            │
│ │⭐⭐⭐⭐      │ │⭐⭐⭐⭐⭐     │ │⭐⭐⭐⭐⭐     │            │
│ │[INSTALL]    │ │[INSTALLED]  │ │[INSTALL]    │            │
│ └─────────────┘ └─────────────┘ └─────────────┘            │
└─────────────────────────────────────────────────────────────┘
```

### **Installation User Flow**
```
1. Download UniversalInstaller.dmg (~100MB base)
   ↓
2. Open DMG → Drag app to Applications
   ↓
3. Launch app → App Store catalog appears
   ↓
4. Browse/Search → Select app (e.g., "AI Chat Assistant")
   ↓
5. Click "Install" → Download progress shown (~30 seconds - 2 minutes)
   ↓
6. Click "Launch" → App opens in browser automatically
   ↓
7. Success! User is chatting with AI (or using chosen tool)
```

### **Multi-App Management**
- **Library View** - See all installed apps with status indicators
- **Quick Switcher** - Fast switching between running apps
- **Resource Dashboard** - Monitor memory/CPU usage across apps
- **Bulk Operations** - Start all, stop all, update all functionality

---

## 📱 Launch App Catalog (15-20 Apps)

### **🧠 AI & Chat Category**
- **OpenWebUI** ⭐ (Featured, Bundled) - AI Chat Assistant
- **Ollama WebUI** - Alternative AI Interface  
- **LibreChat** - Multi-AI Client (OpenAI, Claude, etc.)
- **Chatbot UI** - Customizable Chat Interface
- **Text Generation WebUI** - Advanced AI Text Generation

### **📐 Design & Drawing**
- **Excalidraw** - Collaborative Whiteboard
- **Draw.io** - Diagram and Flowchart Editor
- **Penpot** - Open Source Design Tool
- **tldraw** - Simple Drawing and Diagramming

### **📝 Notes & Productivity**
- **Obsidian Publish** - Knowledge Management
- **Outline** - Team Wiki and Documentation
- **Joplin Server** - Note Taking with Sync
- **Standard Notes** - Private, Encrypted Notes
- **Trilium** - Hierarchical Note Taking

### **💻 Development Tools**
- **VS Code Server** - Browser-based IDE
- **Jupyter Lab** - Data Science Notebooks
- **GitLab** - Code Repository and CI/CD
- **code-server** - VS Code in Browser

### **📊 Analytics & Monitoring**
- **Grafana** - Data Visualization Dashboard
- **Prometheus** - Monitoring and Alerting
- **Plausible** - Privacy-friendly Analytics

---

## 🎯 Success Metrics & KPIs

### **Technical Performance Metrics**
- **Installation Success Rate:** >95% across all supported macOS versions
- **Time to First App Running:** <30 seconds for bundled apps, <2 minutes for downloaded
- **Multi-App Performance:** Support 5+ concurrent apps without system degradation
- **Catalog Load Time:** <2 seconds to display full catalog
- **Download Performance:** Optimal bandwidth usage with progress tracking

### **User Engagement Metrics**
- **Apps per User:** Average 3-5 apps installed per user
- **Multi-App Usage:** >60% of users run multiple apps simultaneously
- **Discovery Rate:** >40% of users install apps beyond their initial choice
- **Retention Rate:** >80% of users still using the platform after 30 days
- **User Satisfaction:** >4.5/5 stars in user feedback

### **Business Metrics**
- **Market Penetration:** 10,000+ active users within 6 months
- **Developer Interest:** 50+ app submissions to catalog within 3 months
- **Platform Growth:** 25+ curated apps available at launch
- **Support Efficiency:** <2% of installations generate support tickets

---

## 🚨 Technical Risks & Mitigation

### **High-Risk Items**
1. **Multi-Container Resource Management**
   - *Risk:* Apps competing for system resources, crashes, poor performance
   - *Mitigation:* Smart resource allocation, container limits, automated restart

2. **Container Image Download Reliability**
   - *Risk:* Failed downloads, corrupted images, bandwidth issues
   - *Mitigation:* Resume capability, integrity checks, mirror CDN

3. **Port Conflict Management**
   - *Risk:* Multiple apps trying to use same ports
   - *Mitigation:* Dynamic port allocation, conflict detection, automatic reassignment

4. **App Quality Control**
   - *Risk:* Malicious or broken apps in catalog
   - *Mitigation:* Curated catalog, app review process, security scanning

### **Medium-Risk Items**
1. **macOS Compatibility Across Versions**
2. **Apple Silicon vs Intel Performance Differences**
3. **User Education for App Store Concept**
4. **Browser Integration Edge Cases**

---

## 🗓️ Development Timeline & Roadmap

### **Phase 1: Multi-Frontend Foundation (Weeks 1-4)**
**Goal:** Functional universal installer with 5-10 test apps

#### **Week 1: App Configuration Architecture**
- [ ] Create app configuration JSON schema
- [ ] Implement FrontendConfiguration protocol 
- [ ] Build AppRegistry system for catalog management
- [ ] Create sample configurations for 5 test apps

#### **Week 2: Multi-Container Management**
- [ ] Refactor ContainerManager for multi-app support
- [ ] Implement port allocation and resource management
- [ ] Add multi-container orchestration
- [ ] Build container lifecycle management

#### **Week 3: Download-on-Demand System**
- [ ] Build container image downloader with progress
- [ ] Implement installation flow and verification
- [ ] Add storage management and cleanup
- [ ] Create installation progress tracking

#### **Week 4: Basic Catalog Interface** 
- [ ] Create SwiftUI app store main view
- [ ] Build app card components and detail views
- [ ] Implement category navigation and search
- [ ] Add install/launch workflows

### **Phase 2: App Store UI Polish (Weeks 5-8)**
**Goal:** Production-quality app store experience

#### **Week 5-6: Enhanced Catalog Experience**
- [ ] Featured apps section with promotion logic
- [ ] Advanced search and filtering capabilities
- [ ] App screenshots gallery and rich descriptions
- [ ] Installation progress UI with time estimates
- [ ] Error handling and recovery flows

#### **Week 7-8: App Management Dashboard**
- [ ] Installed apps library with status monitoring
- [ ] Quick app switcher and window management
- [ ] Resource usage dashboard and analytics
- [ ] Bulk operations (start all, stop all, update all)
- [ ] App settings and preferences per app

### **Phase 3: Production Readiness (Weeks 9-12)**
**Goal:** Distributable, production-ready universal installer

#### **Week 9-10: Distribution & Testing**
- [ ] Code signing and notarization setup
- [ ] DMG creation with bundled featured apps
- [ ] Multi-Mac configuration testing (Intel + Apple Silicon)
- [ ] Performance optimization and resource tuning
- [ ] Security review and vulnerability testing

#### **Week 11-12: Launch Preparation**
- [ ] User onboarding flow and tutorial
- [ ] Comprehensive documentation and help system
- [ ] Beta testing program with real users
- [ ] Marketing materials and app store screenshots
- [ ] Support infrastructure and troubleshooting guides

### **Phase 4: Catalog Ecosystem (Weeks 13-16)**
**Goal:** Scalable catalog with 15-20 curated apps

#### **Week 13-14: Catalog Management Infrastructure**
- [ ] Catalog server/CDN for app metadata distribution
- [ ] App submission and review process
- [ ] Version management and automatic updates
- [ ] App discovery algorithms and recommendations

#### **Week 15-16: Market Launch**
- [ ] Curate and test 15-20 high-quality apps
- [ ] Public beta release with user feedback collection
- [ ] Marketing campaign and developer outreach
- [ ] Public launch and user acquisition

---

## 🔧 Implementation Details

### **App Configuration JSON Schema**
```json
{
  "$schema": "https://universalinstaller.app/schema/app-config.json",
  "id": "string (required, unique identifier)",
  "name": "string (required, technical name)",
  "displayName": "string (required, user-facing name)",
  "description": "string (required, 1-3 sentences)",
  "longDescription": "string (optional, detailed description)",
  "category": "enum (ai-chat, design, notes, development, monitoring, productivity)",
  "subcategory": "string (optional)",
  "featured": "boolean (default: false)",
  "version": "string (required, semver format)",
  "containerImage": "string (required, full image URL)",
  "ports": [
    {
      "internal": "number (container port)",
      "external": "number (host port, optional)",
      "protocol": "string (tcp/udp, default: tcp)"
    }
  ],
  "environment": {
    "KEY": "value (environment variables)"
  },
  "volumes": [
    {
      "host": "string (host path)",
      "container": "string (container path)",
      "readOnly": "boolean (default: false)"
    }
  ],
  "healthCheck": {
    "endpoint": "string (HTTP endpoint for health check)",
    "timeout": "number (seconds, default: 30)",
    "interval": "number (seconds, default: 10)",
    "retries": "number (default: 3)"
  },
  "resources": {
    "minMemory": "string (e.g., '512MB')",
    "maxMemory": "string (e.g., '2GB')",
    "minCpus": "number (CPU cores, default: 0.5)",
    "maxCpus": "number (CPU cores, default: 2)"
  },
  "screenshots": ["string (array of screenshot URLs)"],
  "icon": "string (app icon URL)",
  "bundled": "boolean (included in main installer)",
  "downloadSize": "string (estimated download size)",
  "diskSpace": "string (estimated disk usage when running)",
  "tags": ["string (array of searchable tags)"],
  "developer": {
    "name": "string (developer/organization name)",
    "website": "string (developer website)",
    "support": "string (support contact)"
  },
  "license": "string (license type)",
  "sourceCode": "string (optional, source code URL)",
  "documentation": "string (optional, documentation URL)",
  "requirements": {
    "macOSVersion": "string (minimum macOS version)",
    "architecture": ["string (supported architectures: x86_64, arm64)"],
    "internetRequired": "boolean (requires internet to function)"
  }
}
```

### **Core Swift Architecture**

#### **AppConfiguration Protocol**
```swift
// Models/AppConfiguration.swift
protocol AppConfiguration {
    var id: String { get }
    var name: String { get }
    var displayName: String { get }
    var description: String { get }
    var category: AppCategory { get }
    var containerImage: String { get }
    var ports: [PortMapping] { get }
    var healthCheck: HealthCheckConfig { get }
    var resources: ResourceRequirements { get }
    var bundled: Bool { get }
    var featured: Bool { get }
    var screenshots: [String] { get }
    var tags: [String] { get }
}

struct ConcreteAppConfiguration: AppConfiguration, Codable {
    let id: String
    let name: String
    let displayName: String
    let description: String
    let category: AppCategory
    let containerImage: String
    let ports: [PortMapping]
    let healthCheck: HealthCheckConfig
    let resources: ResourceRequirements
    let bundled: Bool
    let featured: Bool
    let screenshots: [String]
    let tags: [String]
}
```

#### **Multi-Container Management**
```swift
// Services/ContainerManager.swift
@MainActor
class ContainerManager: ObservableObject {
    @Published var runningContainers: [String: ContainerStatus] = [:]
    @Published var installationProgress: [String: Double] = [:]
    
    private let portManager = PortManager()
    private let resourceManager = ResourceManager()
    private let imageDownloader = ImageDownloader()
    
    func installApp(_ app: AppConfiguration) async throws {
        // 1. Check system requirements
        try await resourceManager.validateRequirements(for: app)
        
        // 2. Allocate resources (port, memory, etc.)
        let allocation = try resourceManager.allocateResources(for: app)
        
        // 3. Download container image (if not bundled)
        if !app.bundled {
            try await imageDownloader.downloadImage(app.containerImage, 
                                                   progress: { [weak self] progress in
                self?.installationProgress[app.id] = progress
            })
        }
        
        // 4. Create and start container
        try await startContainer(for: app, with: allocation)
        
        // 5. Wait for health check
        try await waitForHealthCheck(app: app)
        
        // 6. Register as installed
        await registerInstalledApp(app)
    }
    
    func launchApp(_ appId: String) async throws {
        guard let status = runningContainers[appId] else {
            throw ContainerError.appNotRunning(appId)
        }
        
        let url = URL(string: "http://localhost:\(status.port)")!
        await NSWorkspace.shared.open(url)
    }
    
    func stopApp(_ appId: String) async throws {
        // Stop container gracefully
        // Release allocated resources
        // Update status
    }
}
```

#### **App Store UI Components**
```swift
// Views/AppStore/AppStoreView.swift
struct AppStoreView: View {
    @StateObject private var appRegistry = AppRegistry()
    @StateObject private var containerManager = ContainerManager()
    @State private var selectedCategory: AppCategory = .all
    @State private var searchText = ""
    
    var body: some View {
        NavigationSplitView {
            // Category sidebar
            CategorySidebar(selectedCategory: $selectedCategory)
        } content: {
            // Main catalog view
            AppCatalogView(
                apps: filteredApps,
                searchText: $searchText,
                containerManager: containerManager
            )
        } detail: {
            // App detail view
            AppDetailView(
                app: selectedApp,
                containerManager: containerManager
            )
        }
        .task {
            await appRegistry.loadCatalog()
        }
    }
    
    private var filteredApps: [AppConfiguration] {
        appRegistry.availableApps
            .filter { selectedCategory == .all || $0.category == selectedCategory }
            .filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
    }
}

// Views/Components/AppCard.swift  
struct AppCard: View {
    let app: AppConfiguration
    let installStatus: InstallStatus
    let onInstall: () -> Void
    let onLaunch: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // App header with icon and name
            HStack {
                AsyncImage(url: URL(string: app.icon)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 48, height: 48)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.displayName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(app.category.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Featured badge
                if app.featured {
                    Text("FEATURED")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            
            // Description
            Text(app.description)
                .font(.body)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            
            // Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(app.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 1)
            }
            
            // Action button
            HStack {
                // Size and requirements info
                VStack(alignment: .leading, spacing: 2) {
                    Text(app.downloadSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("macOS \(app.requirements.macOSVersion)+")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Install/Launch button
                switch installStatus {
                case .notInstalled:
                    Button("Install") {
                        onInstall()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                case .installing(let progress):
                    VStack(spacing: 4) {
                        ProgressView(value: progress)
                            .frame(width: 80)
                        Text("\(Int(progress * 100))%")
                            .font(.caption2)
                    }
                    
                case .installed:
                    Button("Launch") {
                        onLaunch()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                case .running:
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        
                        Button("Open") {
                            onLaunch()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}
```

### **Resource Management**
```swift
// Services/ResourceManager.swift
class ResourceManager: ObservableObject {
    private let minSystemMemoryReserved: UInt64 = 2 * 1024 * 1024 * 1024 // 2GB
    private let maxContainerMemoryPercent: Double = 0.6 // 60% of available memory
    
    func validateRequirements(for app: AppConfiguration) async throws {
        let systemInfo = SystemInfo.current()
        
        // Check macOS version
        guard systemInfo.macOSVersion >= app.requirements.macOSVersion else {
            throw ResourceError.incompatibleOS(
                required: app.requirements.macOSVersion,
                current: systemInfo.macOSVersion
            )
        }
        
        // Check available memory
        let availableMemory = systemInfo.memoryTotal - getCurrentMemoryUsage() - minSystemMemoryReserved
        let requiredMemory = parseMemoryString(app.resources.maxMemory)
        
        guard availableMemory >= requiredMemory else {
            throw ResourceError.insufficientMemory(
                required: app.resources.maxMemory,
                available: formatBytes(availableMemory)
            )
        }
        
        // Check disk space
        let availableDisk = systemInfo.availableDiskSpace
        let requiredDisk = parseMemoryString(app.diskSpace ?? "1GB")
        
        guard availableDisk >= requiredDisk else {
            throw ResourceError.insufficientDisk(
                required: app.diskSpace ?? "1GB",
                available: formatBytes(availableDisk)
            )
        }
    }
    
    func allocateResources(for app: AppConfiguration) throws -> ResourceAllocation {
        let port = try PortManager.shared.allocatePort(preferred: app.ports.first?.external)
        let memoryLimit = calculateMemoryLimit(for: app)
        let cpuLimit = calculateCPULimit(for: app)
        
        return ResourceAllocation(
            appId: app.id,
            port: port,
            memoryLimit: memoryLimit,
            cpuLimit: cpuLimit
        )
    }
}
```

---

## 📦 Distribution Strategy

### **Primary Distribution**
1. **Direct Download** - UniversalInstaller.dmg from project website
2. **GitHub Releases** - Automated DMG creation and distribution
3. **Word of Mouth** - Developer and AI community sharing

### **Secondary Distribution** 
1. **Homebrew Cask** - `brew install --cask universal-installer`
2. **Mac App Store** - If Apple approves container management apps
3. **Developer Partnerships** - Integration with containerized app developers

### **Bundle Contents**
- **Base Installer:** ~100MB (Podman runtime + catalog index)
- **Featured App:** OpenWebUI bundled (~80MB compressed)
- **Total DMG Size:** ~200MB (competitive with individual app installers)

---

## 💰 Business Model & Monetization

### **Phase 1: Free Platform (0-12 months)**
- Completely free universal installer
- Focus on user adoption and market penetration
- Build developer ecosystem and app catalog

### **Phase 2: Platform Services (12+ months)**
- **Featured App Placement** - Developers pay for prominent catalog placement
- **Premium App Support** - Hosting and distribution for paid/premium apps
- **Enterprise Catalogs** - Private app catalogs for organizations
- **Developer Tools** - Enhanced analytics and deployment tools

### **Revenue Projections (Conservative)**
- **Year 1:** $0 (user acquisition focus)
- **Year 2:** $50K-100K (featured placement + premium apps)
- **Year 3:** $200K-500K (enterprise catalogs + platform fees)

---

## 🎉 Success Definition

**The Universal Container App Store succeeds when:**

### **User Success Metrics**
- ✅ **User Discovery:** >40% of users install apps beyond their initial search intent

