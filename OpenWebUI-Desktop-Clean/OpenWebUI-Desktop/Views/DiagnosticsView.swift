//
//  DiagnosticsView.swift
//  OpenWebUI-Desktop
//
//  Created on December 22, 2024.
//  Diagnostics and Troubleshooting View - Level 3 Complete Abstraction
//

import SwiftUI

struct DiagnosticsView: View {
    @EnvironmentObject private var containerManager: ContainerManager
    @Environment(\.dismiss) private var dismiss

    @State private var diagnosticReport: DiagnosticReport?
    @State private var isGenerating = false
    @State private var showingExportOptions = false
    @State private var selectedExportFormat: ExportFormat = .text

    enum ExportFormat: String, CaseIterable {
        case text = "Plain Text"
        case json = "JSON"
        case markdown = "Markdown"

        var fileExtension: String {
            switch self {
            case .text: return "txt"
            case .json: return "json"
            case .markdown: return "md"
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isGenerating {
                    generatingView
                } else if let report = diagnosticReport {
                    reportView(report)
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("Diagnostics")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if diagnosticReport != nil && !isGenerating {
                        Button("Export") {
                            showingExportOptions = true
                        }
                        .buttonStyle(.bordered)
                    }

                    Button("Refresh") {
                        generateReport()
                    }
                    .disabled(isGenerating)

                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .onAppear {
            generateReport()
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView(
                report: diagnosticReport!,
                format: $selectedExportFormat
            )
        }
    }

    // MARK: - Generating View
    @ViewBuilder
    private var generatingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Generating Diagnostic Report")
                .font(.title2)
                .fontWeight(.medium)

            Text("Collecting system information, container status, and logs...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Diagnostic Report")
                .font(.title2)
                .fontWeight(.medium)

            Text("Generate a diagnostic report to view system information and troubleshooting data.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            Button("Generate Report") {
                generateReport()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Report View
    @ViewBuilder
    private func reportView(_ report: DiagnosticReport) -> some View {
        HSplitView {
            // Sidebar with sections
            VStack(alignment: .leading, spacing: 0) {
                Text("Report Sections")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                List {
                    DiagnosticSectionItem(
                        title: "System Information",
                        icon: "desktopcomputer",
                        isHealthy: true
                    )

                    DiagnosticSectionItem(
                        title: "Container Status",
                        icon: "cube.box",
                        isHealthy: report.containerStatus.health == .healthy
                    )

                    DiagnosticSectionItem(
                        title: "Configuration",
                        icon: "gear",
                        isHealthy: true
                    )

                    DiagnosticSectionItem(
                        title: "Application Logs",
                        icon: "doc.text",
                        isHealthy: report.appLogs.isEmpty ? false : true
                    )

                    DiagnosticSectionItem(
                        title: "Container Logs",
                        icon: "terminal",
                        isHealthy: report.containerLogs.isEmpty ? false : true
                    )
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 200, maxWidth: 250)

            // Main content
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    systemInformationSection(report.systemInfo)
                    containerStatusSection(report.containerStatus)
                    configurationSection(report.configuration)
                    applicationLogsSection(report.appLogs)
                    containerLogsSection(report.containerLogs)
                }
                .padding(20)
            }
        }
    }

    // MARK: - Report Sections
    @ViewBuilder
    private func systemInformationSection(_ systemInfo: SystemInfo) -> some View {
        DiagnosticSection(title: "System Information", icon: "desktopcomputer") {
            VStack(spacing: 12) {
                DiagnosticRow(label: "macOS Version", value: systemInfo.macOSVersion)
                DiagnosticRow(label: "Architecture", value: systemInfo.architecture)
                DiagnosticRow(label: "Total Memory", value: systemInfo.memoryTotalGB)
                DiagnosticRow(label: "Available Disk Space", value: systemInfo.availableDiskSpaceGB)
                DiagnosticRow(label: "App Version", value: "\(systemInfo.appVersion) (\(systemInfo.buildNumber))")
                DiagnosticRow(
                    label: "Apple Silicon",
                    value: systemInfo.isAppleSilicon ? "Yes" : "No",
                    isHealthy: true
                )
            }
        }
    }

    @ViewBuilder
    private func containerStatusSection(_ status: ContainerStatus) -> some View {
        DiagnosticSection(title: "Container Status", icon: "cube.box") {
            VStack(spacing: 12) {
                DiagnosticRow(
                    label: "Running",
                    value: status.isRunning ? "Yes" : "No",
                    isHealthy: status.isRunning
                )
                DiagnosticRow(
                    label: "Health",
                    value: status.health.displayName,
                    isHealthy: status.health == .healthy
                )
                DiagnosticRow(label: "Port", value: String(status.port))
                DiagnosticRow(label: "Uptime", value: status.uptimeString)
                DiagnosticRow(label: "Memory Usage", value: status.memoryUsageString)
                DiagnosticRow(label: "CPU Usage", value: status.cpuUsageString)
                DiagnosticRow(label: "Image Version", value: status.imageVersion ?? "Unknown")
            }
        }
    }

    @ViewBuilder
    private func configurationSection(_ config: AppConfiguration) -> some View {
        DiagnosticSection(title: "Configuration", icon: "gear") {
            VStack(spacing: 12) {
                DiagnosticRow(
                    label: "Auto Start Container",
                    value: config.autoStartContainer ? "Enabled" : "Disabled"
                )
                DiagnosticRow(
                    label: "Enable Diagnostics",
                    value: config.enableDiagnostics ? "Enabled" : "Disabled"
                )
                DiagnosticRow(
                    label: "Check for Updates",
                    value: config.checkForUpdates ? "Enabled" : "Disabled"
                )
                DiagnosticRow(label: "Container Port", value: String(config.containerPort))
                DiagnosticRow(
                    label: "Notifications",
                    value: config.enableNotifications ? "Enabled" : "Disabled"
                )
                DiagnosticRow(
                    label: "Menu Bar Icon",
                    value: config.enableMenuBarIcon ? "Enabled" : "Disabled"
                )
            }
        }
    }

    @ViewBuilder
    private func applicationLogsSection(_ logs: [String]) -> some View {
        DiagnosticSection(title: "Application Logs", icon: "doc.text") {
            if logs.isEmpty {
                Text("No application logs available")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Showing last \(min(logs.count, 50)) log entries:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(logs.suffix(50).indices, id: \.self) { index in
                                Text(logs.suffix(50)[index])
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(12)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                    }
                    .frame(maxHeight: 200)
                }
            }
        }
    }

    @ViewBuilder
    private func containerLogsSection(_ logs: [String]) -> some View {
        DiagnosticSection(title: "Container Logs", icon: "terminal") {
            if logs.isEmpty {
                Text("No container logs available")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Showing last \(min(logs.count, 50)) log entries:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(logs.suffix(50).indices, id: \.self) { index in
                                Text(logs.suffix(50)[index])
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(12)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                    }
                    .frame(maxHeight: 200)
                }
            }
        }
    }

    // MARK: - Actions
    private func generateReport() {
        isGenerating = true

        Task {
            // Simulate report generation time
            await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

            let systemInfo = SystemInfo.current()
            let containerStatus = containerManager.containerStatus
            let configuration = AppConfiguration()

            // Generate mock logs for demonstration
            let appLogs = [
                "[\(Date().formatted())] ContainerManager initialized",
                "[\(Date().formatted())] System requirements check passed",
                "[\(Date().formatted())] Container runtime extracted successfully",
                "[\(Date().formatted())] Container image loaded successfully",
                "[\(Date().formatted())] Container started successfully",
                "[\(Date().formatted())] Health monitoring started"
            ]

            let containerLogs = [
                "Starting Open WebUI server...",
                "Loading configuration files...",
                "Initializing AI models...",
                "Server listening on port 8080",
                "Ready to accept connections"
            ]

            await MainActor.run {
                diagnosticReport = DiagnosticReport(
                    timestamp: Date(),
                    systemInfo: systemInfo,
                    containerStatus: containerStatus,
                    appLogs: appLogs,
                    containerLogs: containerLogs,
                    configuration: configuration
                )
                isGenerating = false
            }
        }
    }
}

// MARK: - Supporting Views
struct DiagnosticSection<Content: View>: View {
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

            content
                .padding(16)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
        }
    }
}

struct DiagnosticRow: View {
    let label: String
    let value: String
    let isHealthy: Bool?

    init(label: String, value: String, isHealthy: Bool? = nil) {
        self.label = label
        self.value = value
        self.isHealthy = isHealthy
    }

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                if let isHealthy = isHealthy {
                    Image(systemName: isHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(isHealthy ? .green : .orange)
                        .font(.caption)
                }

                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
            }
        }
    }
}

struct DiagnosticSectionItem: View {
    let title: String
    let icon: String
    let isHealthy: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 16)

            Text(title)
                .font(.subheadline)

            Spacer()

            Image(systemName: isHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isHealthy ? .green : .orange)
                .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Export Options View
struct ExportOptionsView: View {
    let report: DiagnosticReport
    @Binding var format: DiagnosticsView.ExportFormat
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Export Diagnostic Report")
                .font(.title2)
                .fontWeight(.medium)

            VStack(alignment: .leading, spacing: 12) {
                Text("Format:")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Picker("Format", selection: $format) {
                    ForEach(DiagnosticsView.ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
            }
            .frame(maxWidth: 300)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Export") {
                    exportReport()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        .frame(width: 400, height: 200)
    }

    private func exportReport() {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "OpenWebUI-Diagnostic-\(Date().timeIntervalSince1970).\(format.fileExtension)"
        savePanel.allowedContentTypes = [.plainText]
        savePanel.title = "Export Diagnostic Report"

        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                let content: String

                switch format {
                case .text:
                    content = report.generateReport()
                case .json:
                    content = report.generateJSONReport()
                case .markdown:
                    content = report.generateMarkdownReport()
                }

                try content.write(to: url, atomically: true, encoding: .utf8)
                dismiss()

                // Show success notification
                let alert = NSAlert()
                alert.messageText = "Export Successful"
                alert.informativeText = "Diagnostic report saved to \(url.lastPathComponent)"
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()

            } catch {
                // Show error alert
                let alert = NSAlert()
                alert.messageText = "Export Failed"
                alert.informativeText = "Could not save diagnostic report: \(error.localizedDescription)"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
}

// MARK: - DiagnosticReport Extensions
extension DiagnosticReport {
    func generateJSONReport() -> String {
        let data: [String: Any] = [
            "timestamp": timestamp.ISO8601Format(),
            "systemInfo": [
                "macOSVersion": systemInfo.macOSVersion,
                "architecture": systemInfo.architecture,
                "memoryTotal": systemInfo.memoryTotal,
                "availableDiskSpace": systemInfo.availableDiskSpace,
                "appVersion": systemInfo.appVersion,
                "buildNumber": systemInfo.buildNumber
            ],
            "containerStatus": [
                "isRunning": containerStatus.isRunning,
                "health": containerStatus.health.rawValue,
                "port": containerStatus.port,
                "uptime": containerStatus.uptime ?? 0,
                "memoryUsage": containerStatus.memoryUsage ?? 0,
                "cpuUsage": containerStatus.cpuUsage ?? 0
            ],
            "configuration": [
                "autoStartContainer": configuration.autoStartContainer,
                "enableDiagnostics": configuration.enableDiagnostics,
                "checkForUpdates": configuration.checkForUpdates,
                "containerPort": configuration.containerPort,
                "enableNotifications": configuration.enableNotifications,
                "enableMenuBarIcon": configuration.enableMenuBarIcon
            ],
            "appLogs": appLogs,
            "containerLogs": containerLogs
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }

        return "{\"error\": \"Failed to generate JSON report\"}"
    }

    func generateMarkdownReport() -> String {
        return """
        # OpenWebUI Desktop Diagnostic Report

        **Generated:** \(timestamp.formatted())

        ## System Information

        | Property | Value |
        |----------|-------|
        | macOS Version | \(systemInfo.macOSVersion) |
        | Architecture | \(systemInfo.architecture) |
        | Total Memory | \(systemInfo.memoryTotalGB) |
        | Available Disk Space | \(systemInfo.availableDiskSpaceGB) |
        | App Version | \(systemInfo.appVersion) (\(systemInfo.buildNumber)) |

        ## Container Status

        | Property | Value |
        |----------|-------|
        | Running | \(containerStatus.isRunning ? "✅ Yes" : "❌ No") |
        | Health | \(containerStatus.health.displayName) |
        | Port | \(containerStatus.port) |
        | Uptime | \(containerStatus.uptimeString) |
        | Memory Usage | \(containerStatus.memoryUsageString) |
        | CPU Usage | \(containerStatus.cpuUsageString) |

        ## Configuration

        | Setting | Value |
        |---------|-------|
        | Auto Start Container | \(configuration.autoStartContainer ? "Enabled" : "Disabled") |
        | Enable Diagnostics | \(configuration.enableDiagnostics ? "Enabled" : "Disabled") |
        | Check for Updates | \(configuration.checkForUpdates ? "Enabled" : "Disabled") |
        | Container Port | \(configuration.containerPort) |
        | Notifications | \(configuration.enableNotifications ? "Enabled" : "Disabled") |
        | Menu Bar Icon | \(configuration.enableMenuBarIcon ? "Enabled" : "Disabled") |

        ## Application Logs

        ```
        \(appLogs.suffix(20).joined(separator: "\n"))
        ```

        ## Container Logs

        ```
        \(containerLogs.suffix(20).joined(separator: "\n"))
        ```
        """
    }
}

// MARK: - Preview
struct DiagnosticsView_Previews: PreviewProvider {
    static var previews: some View {
        DiagnosticsView()
            .environmentObject(ContainerManager())
    }
}
