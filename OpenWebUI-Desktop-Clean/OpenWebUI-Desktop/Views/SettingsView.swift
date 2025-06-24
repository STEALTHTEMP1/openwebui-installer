//
//  SettingsView.swift
//  OpenWebUI-Desktop
//
//  Created on December 22, 2024.
//  Settings and Configuration View - Level 3 Complete Abstraction
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var containerManager: ContainerManager
    @Environment(\.dismiss) private var dismiss

    @State private var configuration = AppConfiguration()
    @State private var showingResetAlert = false
    @State private var showingPortChangeAlert = false
    @State private var tempPort: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Settings Content
                ScrollView {
                    LazyVStack(spacing: 24) {
                        generalSection
                        containerSection
                        advancedSection
                        aboutSection
                    }
                    .padding(20)
                }

                // Action Buttons
                HStack {
                    Button("Reset to Defaults") {
                        showingResetAlert = true
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)

                    Button("Save") {
                        saveSettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
                .padding(20)
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .navigationTitle("Settings")
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            loadSettings()
        }
        .alert("Reset Settings", isPresented: $showingResetAlert) {
            Button("Reset", role: .destructive) {
                resetToDefaults()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all settings to their default values. This action cannot be undone.")
        }
        .alert("Port Change Warning", isPresented: $showingPortChangeAlert) {
            Button("Change Port", role: .destructive) {
                applyPortChange()
            }
            Button("Cancel", role: .cancel) {
                tempPort = String(configuration.containerPort)
            }
        } message: {
            Text("Changing the port will restart Open WebUI. Any unsaved work may be lost.")
        }
    }

    // MARK: - General Settings Section
    @ViewBuilder
    private var generalSection: some View {
        SettingsSection(title: "General", icon: "gear") {
            VStack(spacing: 16) {
                SettingsRow(
                    title: "Auto-start Container",
                    description: "Automatically start Open WebUI when the app launches"
                ) {
                    Toggle("", isOn: $configuration.autoStartContainer)
                        .toggleStyle(.switch)
                }

                SettingsRow(
                    title: "Enable Notifications",
                    description: "Show system notifications for status updates and errors"
                ) {
                    Toggle("", isOn: $configuration.enableNotifications)
                        .toggleStyle(.switch)
                }

                SettingsRow(
                    title: "Show Menu Bar Icon",
                    description: "Display a status icon in the menu bar for quick access"
                ) {
                    Toggle("", isOn: $configuration.enableMenuBarIcon)
                        .toggleStyle(.switch)
                }

                SettingsRow(
                    title: "Check for Updates",
                    description: "Automatically check for app updates"
                ) {
                    Toggle("", isOn: $configuration.checkForUpdates)
                        .toggleStyle(.switch)
                }
            }
        }
    }

    // MARK: - Container Settings Section
    @ViewBuilder
    private var containerSection: some View {
        SettingsSection(title: "Container", icon: "cube.box") {
            VStack(spacing: 16) {
                SettingsRow(
                    title: "Port",
                    description: "Local port for Open WebUI (requires restart)"
                ) {
                    HStack {
                        TextField("Port", text: $tempPort)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .onSubmit {
                                validateAndSetPort()
                            }

                        if tempPort != String(configuration.containerPort) {
                            Button("Apply") {
                                validateAndSetPort()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }

                SettingsRow(
                    title: "Container Status",
                    description: "Current status of the Open WebUI container"
                ) {
                    HStack {
                        StatusIndicator(health: containerManager.containerStatus.health)
                        Text(containerManager.containerStatus.health.displayName)
                            .foregroundColor(.secondary)

                        if containerManager.containerStatus.isRunning {
                            Text("• Uptime: \(containerManager.containerStatus.uptimeString)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                SettingsRow(
                    title: "Resource Usage",
                    description: "Current container resource consumption"
                ) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Memory: \(containerManager.containerStatus.memoryUsageString)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("CPU: \(containerManager.containerStatus.cpuUsageString)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Advanced Settings Section
    @ViewBuilder
    private var advancedSection: some View {
        SettingsSection(title: "Advanced", icon: "slider.horizontal.3") {
            VStack(spacing: 16) {
                SettingsRow(
                    title: "Enable Diagnostics",
                    description: "Collect diagnostic information for troubleshooting"
                ) {
                    Toggle("", isOn: $configuration.enableDiagnostics)
                        .toggleStyle(.switch)
                }

                SettingsRow(
                    title: "Generate Diagnostic Report",
                    description: "Create a report with system and container information"
                ) {
                    Button("Generate Report") {
                        containerManager.generateDiagnostics()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!configuration.enableDiagnostics)
                }

                SettingsRow(
                    title: "Container Logs",
                    description: "View current container logs"
                ) {
                    Button("View Logs") {
                        openContainerLogs()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!containerManager.containerStatus.isRunning)
                }

                SettingsRow(
                    title: "Reset Container",
                    description: "Stop and recreate the container (clears all data)"
                ) {
                    Button("Reset Container") {
                        resetContainer()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
        }
    }

    // MARK: - About Section
    @ViewBuilder
    private var aboutSection: some View {
        SettingsSection(title: "About", icon: "info.circle") {
            VStack(spacing: 16) {
                SettingsRow(
                    title: "Version",
                    description: "Current application version"
                ) {
                    Text(SystemInfo.current().appVersion)
                        .foregroundColor(.secondary)
                }

                SettingsRow(
                    title: "Build",
                    description: "Build number and system information"
                ) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(SystemInfo.current().buildNumber)
                            .foregroundColor(.secondary)

                        Text(SystemInfo.current().architecture)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                SettingsRow(
                    title: "Open WebUI",
                    description: "Learn more about the Open WebUI project"
                ) {
                    Button("Visit Website") {
                        if let url = URL(string: "https://github.com/open-webui/open-webui") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.bordered)
                }

                SettingsRow(
                    title: "License",
                    description: "View license information"
                ) {
                    Button("View License") {
                        showLicense()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    /// Loads the current application configuration into local state and updates the temporary port value.
    private func loadSettings() {
        configuration = AppConfiguration()
        tempPort = String(configuration.containerPort)
    }

    /// Saves the current configuration and closes the settings view.
    private func saveSettings() {
        configuration.save()
        dismiss()
    }

    /// Resets the application configuration to its default values and updates the temporary port field accordingly.
    private func resetToDefaults() {
        configuration = AppConfiguration()
        configuration.autoStartContainer = true
        configuration.enableDiagnostics = true
        configuration.checkForUpdates = true
        configuration.containerPort = 3000
        configuration.enableNotifications = true
        configuration.enableMenuBarIcon = false

        tempPort = String(configuration.containerPort)
    }

    /// Validates the temporary port input and triggers a port change alert if the value is valid and different from the current configuration.
    /// If the input is invalid, resets the temporary port field to the current container port.
    private func validateAndSetPort() {
        guard let port = Int(tempPort), port > 1024 && port < 65535 else {
            tempPort = String(configuration.containerPort)
            return
        }

        if port != configuration.containerPort {
            showingPortChangeAlert = true
        }
    }

    /// Applies the new container port setting and restarts the container if the port is valid.
    /// - Note: Only ports in the range 1025–65534 are accepted.
    private func applyPortChange() {
        if let port = Int(tempPort), port > 1024 && port < 65535 {
            configuration.containerPort = port
            // This would trigger a container restart in the real implementation
            containerManager.restart()
        }
    }

    /// Opens the container logs window. Currently, this function only prints a message to the console as a placeholder.
    private func openContainerLogs() {
        // This would open a separate window with container logs
        // For now, we'll just print to console
        print("Opening container logs...")
    }

    /// Prompts the user to confirm resetting the container, then stops and recreates the container if confirmed.
    /// All container data will be lost upon reset.
    private func resetContainer() {
        let alert = NSAlert()
        alert.messageText = "Reset Container"
        alert.informativeText = "This will stop and recreate the container. All data will be lost. Are you sure you want to continue?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            containerManager.stop()
            // Add slight delay then restart
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                containerManager.restart()
            }
        }
    }

    /// Displays an informational alert with license details and provides an option to view the full license online.
    private func showLicense() {
        let alert = NSAlert()
        alert.messageText = "License Information"
        alert.informativeText = """
        This application embeds Open WebUI, which is licensed under a modified BSD-3-Clause license.

        Copyright (c) 2023-2024 Timothy Jaeryang Baek

        The native macOS wrapper is developed independently and provides a desktop interface for Open WebUI while preserving all original branding and attribution.

        For full license text, visit: https://github.com/open-webui/open-webui/blob/main/LICENSE
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "View Full License")

        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            if let url = URL(string: "https://github.com/open-webui/open-webui/blob/main/LICENSE") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

// MARK: - Settings Section Component
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                    .frame(width: 20)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            VStack(spacing: 12) {
                content
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
    }
}

// MARK: - Settings Row Component
struct SettingsRow<Content: View>: View {
    let title: String
    let description: String
    let content: Content

    init(title: String, description: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.description = description
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            content
        }
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(ContainerManager())
    }
}
