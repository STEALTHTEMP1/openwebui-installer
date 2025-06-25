//
//  ErrorView.swift
//  OpenWebUI-Desktop
//
//  Created on December 22, 2024.
//  Error Handling View with Recovery Options - Level 3 Complete Abstraction
//

import SwiftUI

struct ErrorView: View {
    let message: String
    let retry: () -> Void

    @State private var showingDetails = false
    @State private var showingDiagnostics = false

    var body: some View {
        VStack(spacing: 32) {
            // Error Icon with Animation
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.red)
            }

            // Error Information
            VStack(spacing: 16) {
                Text("Setup Error")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Action Buttons
            VStack(spacing: 12) {
                Button("Try Again") {
                    retry()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)

                HStack(spacing: 16) {
                    Button("Show Details") {
                        showingDetails.toggle()
                    }
                    .buttonStyle(.bordered)

                    Button("Generate Report") {
                        showingDiagnostics = true
                    }
                    .buttonStyle(.bordered)

                    Button("Open in Browser") {
                        openInBrowser()
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.regular)
            }

            // Troubleshooting Tips
            if showingDetails {
                troubleshootingSection
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .animation(.easeInOut(duration: 0.3), value: showingDetails)
        .sheet(isPresented: $showingDiagnostics) {
            DiagnosticReportView(errorMessage: message)
        }
    }

    @ViewBuilder
    private var troubleshootingSection: some View {
        VStack(spacing: 16) {
            Divider()
                .frame(maxWidth: 400)

            VStack(alignment: .leading, spacing: 12) {
                Text("Troubleshooting Tips")
                    .font(.headline)
                    .foregroundColor(.primary)

                VStack(alignment: .leading, spacing: 8) {
                    troubleshootingTip(
                        icon: "checkmark.circle",
                        title: "Check System Requirements",
                        description: "Ensure you have macOS 10.15+ and at least 4GB RAM"
                    )

                    troubleshootingTip(
                        icon: "internaldrive",
                        title: "Free Up Disk Space",
                        description: "Make sure you have at least 3GB of free storage"
                    )

                    troubleshootingTip(
                        icon: "lock.shield",
                        title: "Check Permissions",
                        description: "Allow the app to access files in System Preferences"
                    )

                    troubleshootingTip(
                        icon: "network",
                        title: "Network Connection",
                        description: "Ensure you have internet for initial setup"
                    )

                    troubleshootingTip(
                        icon: "arrow.counterclockwise",
                        title: "Restart Application",
                        description: "Quit and reopen the app if issues persist"
                    )
                }
            }
            .padding(20)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .frame(maxWidth: 500)
        }
    }

    private func troubleshootingTip(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.accentColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func openInBrowser() {
        if let url = URL(string: "http://localhost:3000") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Diagnostic Report View
struct DiagnosticReportView: View {
    let errorMessage: String
    @Environment(\.dismiss) private var dismiss
    @State private var reportContent = ""
    @State private var isGenerating = true

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isGenerating {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)

                        Text("Generating diagnostic report...")
                            .font(.headline)

                        Text("Collecting system information and logs")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Diagnostic Report")
                            .font(.title2)
                            .fontWeight(.medium)

                        Text("This report contains system information and logs that can help troubleshoot the issue.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ScrollView {
                            Text(reportContent)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(8)
                        }

                        HStack {
                            Button("Copy to Clipboard") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(reportContent, forType: .string)
                            }
                            .buttonStyle(.bordered)

                            Spacer()

                            Button("Save Report") {
                                saveReport()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Diagnostic Report")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            generateReport()
        }
    }

    private func generateReport() {
        Task {
            await Task.sleep(nanoseconds: 1_000_000_000) // Simulate report generation

            let systemInfo = SystemInfo.current()
            let timestamp = Date().formatted()

            reportContent = """
            OpenWebUI Desktop Diagnostic Report
            Generated: \(timestamp)

            === ERROR INFORMATION ===
            Error Message: \(errorMessage)

            === SYSTEM INFORMATION ===
            macOS Version: \(systemInfo.macOSVersion)
            Architecture: \(systemInfo.architecture)
            Total Memory: \(systemInfo.memoryTotalGB)
            Available Disk Space: \(systemInfo.availableDiskSpaceGB)
            App Version: \(systemInfo.appVersion) (\(systemInfo.buildNumber))

            === RUNTIME ENVIRONMENT ===
            App Container Directory: ~/Library/Containers/OpenWebUI/
            Runtime Path: ~/Library/Containers/OpenWebUI/runtime/podman
            Data Directory: ~/Library/Containers/OpenWebUI/data/

            === TROUBLESHOOTING STEPS ===
            1. Verify system requirements (macOS 10.15+, 4GB RAM, 3GB disk space)
            2. Check app permissions in System Preferences > Security & Privacy
            3. Ensure sufficient disk space is available
            4. Try restarting the application
            5. If issues persist, try reinstalling the application

            === SUPPORT INFORMATION ===
            For additional support, please visit:
            https://github.com/open-webui/open-webui/issues

            Include this report when filing a support request.
            """

            await MainActor.run {
                isGenerating = false
            }
        }
    }

    private func saveReport() {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "OpenWebUI-Diagnostic-\(Date().timeIntervalSince1970).txt"
        savePanel.allowedContentTypes = [.plainText]
        savePanel.title = "Save Diagnostic Report"

        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                try reportContent.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                print("Error saving diagnostic report: \(error)")
            }
        }
    }
}

// MARK: - Error Types Extension
extension ContainerError {
    var recoverySuggestions: [String] {
        switch self {
        case .unsupportedSystem:
            return [
                "Upgrade to macOS 10.15 (Catalina) or later",
                "Check Apple's compatibility guide for your Mac model"
            ]
        case .insufficientDiskSpace:
            return [
                "Free up disk space by deleting unused files",
                "Empty the Trash",
                "Use Storage Management tools in System Preferences"
            ]
        case .insufficientMemory:
            return [
                "Close other applications to free up memory",
                "Restart your Mac to clear memory",
                "Consider upgrading your Mac's RAM"
            ]
        case .bundledRuntimeMissing, .bundledImageMissing:
            return [
                "Reinstall the application from the original source",
                "Download a fresh copy from the official website",
                "Check that the download completed successfully"
            ]
        case .runtimeExtractionFailed:
            return [
                "Check that you have write permissions to your Library folder",
                "Try running the app with administrator privileges",
                "Temporarily disable antivirus software that might be blocking file extraction"
            ]
        case .permissionDenied:
            return [
                "Grant Full Disk Access to the app in System Preferences > Security & Privacy",
                "Check that the app is allowed to access files and folders",
                "Restart the app after changing permissions"
            ]
        default:
            return [
                "Restart the application",
                "Restart your Mac",
                "Check for app updates",
                "Contact support if the issue persists"
            ]
        }
    }
}

// MARK: - Preview
struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ErrorView(
                message: "System requirements not met. macOS 10.15 or later is required.",
                retry: {}
            )
            .previewDisplayName("System Error")

            ErrorView(
                message: "Container failed to start. Port 3000 is already in use by another application.",
                retry: {}
            )
            .previewDisplayName("Port Conflict")

            ErrorView(
                message: "Insufficient disk space. At least 3GB of free space is required for installation.",
                retry: {}
            )
            .previewDisplayName("Disk Space Error")
        }
        .frame(width: 800, height: 600)
    }
}
