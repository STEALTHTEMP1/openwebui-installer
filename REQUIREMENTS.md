# 📋 Universal Container App Store - Comprehensive Requirements Document

**Product Name:** Universal Container App Store for macOS
**Code Name:** UniversalInstaller.app
**Document Type:** Master Requirements Document
**Version:** 1.0
**Date:** December 2024
**Status:** ✅ APPROVED FOR DEVELOPMENT

---

## 📖 Document Purpose

This document serves as the **single source of truth** for all requirements related to the Universal Container App Store project. It consolidates and supersedes all previous requirement documents including:

- `Universal Container App Store.md` (Original PRD)
- `Universal Container App Store - Feedback & Revision Canvas (v0.6).md` (Latest revisions)
- `ONE_CLICK_REQUIREMENTS.md` (Installation requirements)
- `prd.md` (Original OpenWebUI installer PRD)

---

## 🎯 Executive Summary & Vision

### **Project Evolution**
**MAJOR PIVOT**: From single OpenWebUI installer → **Universal Container App Store**

### **Vision Statement**
*"App Store for native desktop AI—privacy‑first, fully local."*

Download one installer, browse an app store catalog, one-click install any AI or productivity tool, and use them seamlessly without ever knowing containers exist.

### **Core Value Proposition**
- **Local containerization** → safety, isolation, zero vendor lock‑in
- **Privacy-first architecture** → all processing stays on device
- **Native desktop experience** → seamless macOS integration
- **Zero technical knowledge** → App Store-like simplicity

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

## 🛠️ Functional Requirements

### **FR-001: App Store Catalog Interface**

#### **Must-Have Features:**
- **Visual app catalog** with grid/list view options
- **Category browsing** (AI & Chat, Design & Drawing, Notes & Productivity, Development Tools, Analytics & Monitoring)
- **Search functionality** with tag-based filtering
- **Featured apps section** with OpenWebUI prominently displayed
- **App details view** with screenshots, descriptions, and user ratings
- **Installation status indicators** (Not Installed, Installing, Installed, Running)

#### **App Card Information Display:**
- App name and display name
- Brief description (1-3 sentences)
- Category and tags
- Developer information
- Screenshots/preview images
- Download size and disk space requirements
- User ratings and review count
- Installation status and quick actions

### **FR-002: Multi-Container Management**

#### **Must-Have Features:**
- **Simultaneous app execution** - multiple containerized apps running concurrently
- **Port management** - automatic port allocation and conflict resolution
- **Resource monitoring** - CPU, memory, and disk usage per app
- **Health checks** - automatic monitoring and restart of failed containers
- **Status dashboard** - real-time view of all installed and running apps

#### **Container Lifecycle Management:**
- **Install**: Download container image, verify checksums, prepare configuration
- **Start**: Launch container with proper environment and port mapping
- **Stop**: Graceful shutdown with data persistence
- **Update**: Pull latest versions with rollback capability
- **Uninstall**: Complete removal of container, images, and associated data

### **FR-003: App Configuration System**

#### **Configuration Management:**
- **JSON-based app definitions** with standardized schema
- **Version control** for app configurations
- **License verification** through GitHub dependency scanning
- **Security validation** with checksum and signature verification

#### **JSON Configuration Format (v2.0):**
```json
{
  "$schema": "https://universalinstaller.app/schema/app-config-v2.json",
  "formatVersion": "2.0",
  "id": "string (required, unique identifier)",
  "name": "string (required, technical name)",
  "displayName": "string (required, user-facing name)",
  "description": "string (required, 1-3 sentences)",
  "category": "enum (ai-chat, design, notes, development, monitoring)",
  "version": "string (required, semver format)",
  "containerImage": "string (required, full image URL with digest)",
  "bundled": "boolean (default: false, only OpenWebUI = true)",
  "license": {
    "type": "string (SPDX identifier)",
    "url": "string (license URL)",
    "verified": "boolean (GitHub dependency scanning verified)"
  },
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
  "mcp": {
    "version": "string (MCP protocol version)",
    "scope": "enum (none, read-only, read-write)",
    "contextTypes": ["persona", "language", "preferences"]
  },
  "credentials": {
    "required": ["string (array of required API services)"],
    "optional": ["string (array of optional API services)"]
  },
  "gpu": {
    "acceleration": "enum (none, preferred, required)",
    "nativeSwiftBridge": "boolean (supports UniversalGPU protocol)",
    "frameworks": ["Metal", "MPSGraph", "CoreML"],
    "minimumVRAM": "string (e.g., '4GB')"
  },
  "appIntents": {
    "supported": "boolean (supports Apple Intelligence integration)",
    "intents": ["ShareContext", "LaunchApp", "GetStatus"]
  }
}
