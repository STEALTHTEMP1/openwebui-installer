//
//  ContentView.swift
//  OpenWebUI-Desktop
//
//  Created on December 22, 2024.
//  Main Content View - Level 3 Complete Abstraction
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var containerManager: ContainerManager
    @State private var showingSettings = false
    @State private var showingDiagnostics = false

    var body: some View {
        VStack(spacing: 0) {
            // Optional toolbar for native controls
            if case .ready = containerManager.state {
                ToolbarView()
                    .environmentObject(containerManager)
            }

            // Main content area
            ZStack {
                switch containerManager.state {
                case .initializing,
                     .extractingRuntime,
                     .loadingImage,
                     .startingContainer:
                    SetupView()
                        .environmentObject(containerManager)

                case .ready:
                    WebView(url: URL(string: "http://localhost:\(containerManager.containerStatus.port)")!)
                        .background(Color.white)

                case .error(let message):
                    ErrorView(message: message) {
                        containerManager.restart()
                    }

                case .stopped:
                    StoppedView {
                        containerManager.restart()
                    }

                case .updating:
                    UpdateView()
                        .environmentObject(containerManager)
                }
            }
        }
        .navigationTitle("Open WebUI")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Status indicator
                HStack {
                    StatusIndicator(health: containerManager.containerStatus.health)

                    if case .ready = containerManager.state {
                        Button("Settings") {
                            showingSettings = true
                        }
                        .keyboardShortcut(",", modifiers: .command)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(containerManager)
        }
        .sheet(isPresented: $showingDiagnostics) {
            DiagnosticsView()
                .environmentObject(containerManager)
        }
        .onAppear {
            containerManager.initialize()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            // Graceful shutdown
            containerManager.stop()
        }
    }
}

// MARK: - Toolbar View
struct ToolbarView: View {
    @EnvironmentObject private var containerManager: ContainerManager

    var body: some View {
        HStack {
            // App branding (minimal)
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.accentColor)
                Text("Open WebUI")
                    .font(.headline)
                    .fontWeight(.medium)
            }

            Spacer()

            // Quick actions
            HStack(spacing: 12) {
                // Status info
                HStack(spacing: 4) {
                    StatusIndicator(health: containerManager.containerStatus.health)
                    Text(containerManager.containerStatus.health.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .frame(height: 16)

                // Quick actions
                Button(action: { containerManager.openInBrowser() }) {
                    Image(systemName: "safari")
                }
                .help("Open in Browser")

                Button(action: { containerManager.restart() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Restart")
                .disabled(containerManager.state.isWorking)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }
}

// MARK: - Status Indicator
struct StatusIndicator: View {
    let health: ContainerHealth

    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
            )
    }

    private var statusColor: Color {
        switch health {
        case .healthy:
            return .green
        case .unhealthy:
            return .red
        case .starting:
            return .orange
        case .stopped:
            return .gray
        case .unknown:
            return .gray
        }
    }
}

// MARK: - Stopped View
struct StoppedView: View {
    let onRestart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "pause.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text("Open WebUI is Stopped")
                    .font(.title2)
                    .fontWeight(.medium)

                Text("The AI assistant is currently not running.")
                    .foregroundColor(.secondary)
            }

            Button("Start Open WebUI") {
                onRestart()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Update View
struct UpdateView: View {
    @EnvironmentObject private var containerManager: ContainerManager

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            VStack(spacing: 12) {
                Text("Updating Open WebUI")
                    .font(.title2)
                    .fontWeight(.medium)

                Text("Downloading and installing the latest version...")
                    .foregroundColor(.secondary)

                ProgressView(value: containerManager.setupProgress)
                    .frame(width: 300)

                Text("\(Int(containerManager.setupProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ContainerManager())
            .frame(width: 1000, height: 700)
    }
}
