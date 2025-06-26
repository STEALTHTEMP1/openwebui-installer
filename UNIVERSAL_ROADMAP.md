# 📅 Universal Container App Store Roadmap

This roadmap extends the initial product requirements for the Universal Container App Store (code name **UniversalInstaller.app**). It outlines the planned development phases and key milestones after the foundational work from Phase 1 Week 2.

## Phase 1: Multi‑Frontend Foundation (Weeks 1‑4)

### Week 3: Download‑on‑Demand System (cont’d)
1. Finalize checksum and signature verification using **Cosign**.
2. Implement resumable downloads with parallel transfer support.
3. Add SwiftUI progress indicators with ETA and bandwidth display.
4. Write automated tests covering download validation and failure recovery in both CLI and GUI paths.

### Week 4: App Catalog & Dashboard
1. Build SwiftUI grid/list views for browsing catalog apps.
2. Implement search functionality and category filters.
3. Add status dashboard showing resource usage and health indicators.
4. Connect the container management service for real‑time dashboard updates.

## Phase 2: Security and MCP Integration (Weeks 5‑8)
1. Add license‑compliance checks in CI pipelines (reuse Bandit and other scanning tools).
2. Implement the **Model Context Protocol (MCP)** service and integrate it with container apps.
3. Develop a credential vault backed by the macOS Keychain with CLI access.
4. Start integration tests for GPU acceleration via the native Swift bridge.

## Phase 3: Distribution & Polishing (Weeks 9‑12)
1. Package `UniversalInstaller.app` with Podman and the OpenWebUI image bundled.
2. Set up code signing and notarization workflows in GitHub Actions using macOS runners.
3. Generate a Homebrew formula as part of the release pipeline for cross‑platform support.
4. Perform final UI/UX polishing, documentation updates, and release‑candidate testing.

## Phase 4: Windows Support (Backlog)
1. Port the container management layer to Windows using WSL or native Podman.
2. Add CI jobs for Windows runners and update tests accordingly.
3. Provide an installer package for Windows users while keeping the shared codebase intact.

---

_This document reflects the approved development plan as of December 2024. Future updates may refine milestones or introduce additional phases as the project evolves._
