//
//  AppState.swift
//  OpenWebUI-Desktop
//
//  Created on December 22, 2024.
//  App State Management for Level 3 Complete Abstraction
//

import Foundation
import Combine

/// Represents the current state of the application
enum AppState: Equatable {
    case initializing
    case extractingRuntime(progress: Double)
    case loadingImage(progress: Double)
    case startingContainer(progress: Double)
    case ready
    case error(message: String)
    case updating(progress: Double)
    case stopped

    var isWorking: Bool {
        switch self {
        case .initializing, .extractingRuntime, .loadingImage, .startingContainer, .updating:
            return true
        case .ready, .error, .stopped:
            return false
        }
    }

    var progressValue: Double {
        switch self {
        case .extractingRuntime(let progress),
             .loadingImage(let progress),
             .startingContainer(let progress),
             .updating(let progress):
            return progress
        case .initializing:
            return 0.0
        case .ready:
            return 1.0
        case .error, .stopped:
            return 0.0
        }
    }

    var displayMessage: String {
        switch self {
        case .initializing:
            return "Initializing Open WebUI..."
        case .extractingRuntime:
            return "Setting up container runtime (first time only)..."
        case .loadingImage:
            return "Loading Open WebUI image..."
        case .startingContainer:
            return "Starting Open WebUI..."
        case .ready:
            return "Open WebUI is ready!"
        case .error(let message):
            return message
        case .updating:
            return "Updating Open WebUI..."
        case .stopped:
            return "Open WebUI is stopped"
        }
    }
}

/// Container health status
enum ContainerHealth: String, CaseIterable {
    case healthy = "healthy"
    case unhealthy = "unhealthy"
    case starting = "starting"
    case stopped = "stopped"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .healthy:
            return "Running"
        case .unhealthy:
            return "Error"
        case .starting:
            return "Starting"
        case .stopped:
            return "Stopped"
        case .unknown:
            return "Unknown"
        }
    }

    var statusColor: String {
        switch self {
        case .healthy:
            return "systemGreen"
        case .unhealthy:
            return "systemRed"
        case .starting:
            return "systemOrange"
        case .stopped:
            return "systemGray"
        case .unknown:
            return "systemGray"
        }
    }
}

/// System information for diagnostics
struct SystemInfo {
    let macOSVersion: String
    let architecture: String
    let memoryTotal: UInt64
    let availableDiskSpace: UInt64
    let appVersion: String
    let buildNumber: String

    /// Retrieves the current system information, including macOS version, architecture, total memory, available disk space, and application version details.
    /// - Returns: A `SystemInfo` instance populated with the current system and application data.
    static func current() -> SystemInfo {
        let bundle = Bundle.main
        return SystemInfo(
            macOSVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            architecture: getCurrentArchitecture(),
            memoryTotal: ProcessInfo.processInfo.physicalMemory,
            availableDiskSpace: getAvailableDiskSpace(),
            appVersion: bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            buildNumber: bundle.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        )
    }

    var memoryTotalGB: String {
        let gb = Double(memoryTotal) / (1024 * 1024 * 1024)
        return String(format: "%.1f GB", gb)
    }

    var availableDiskSpaceGB: String {
        let gb = Double(availableDiskSpace) / (1024 * 1024 * 1024)
        return String(format: "%.1f GB", gb)
    }

    var isAppleSilicon: Bool {
        return architecture.contains("arm64")
    }
}

/// Container status information
struct ContainerStatus {
    let isRunning: Bool
    let health: ContainerHealth
    let uptime: TimeInterval?
    let memoryUsage: UInt64?
    let cpuUsage: Double?
    let port: Int
    let imageVersion: String?

    init(
        isRunning: Bool = false,
        health: ContainerHealth = .unknown,
        uptime: TimeInterval? = nil,
        memoryUsage: UInt64? = nil,
        cpuUsage: Double? = nil,
        port: Int = 3000,
        imageVersion: String? = nil
    ) {
        self.isRunning = isRunning
        self.health = health
        self.uptime = uptime
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
        self.port = port
        self.imageVersion = imageVersion
    }

    var uptimeString: String {
        guard let uptime = uptime else { return "Unknown" }

        let hours = Int(uptime) / 3600
        let minutes = (Int(uptime) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var memoryUsageString: String {
        guard let memoryUsage = memoryUsage else { return "Unknown" }
        let mb = Double(memoryUsage) / (1024 * 1024)
        return String(format: "%.0f MB", mb)
    }

    var cpuUsageString: String {
        guard let cpuUsage = cpuUsage else { return "Unknown" }
        return String(format: "%.1f%%", cpuUsage)
    }
}

/// App configuration settings
struct AppConfiguration {
    var autoStartContainer: Bool
    var enableDiagnostics: Bool
    var checkForUpdates: Bool
    var containerPort: Int
    var enableNotifications: Bool
    var enableMenuBarIcon: Bool

    init() {
        self.autoStartContainer = UserDefaults.standard.bool(forKey: "autoStartContainer")
        self.enableDiagnostics = UserDefaults.standard.bool(forKey: "enableDiagnostics")
        self.checkForUpdates = UserDefaults.standard.bool(forKey: "checkForUpdates")
        self.containerPort = UserDefaults.standard.integer(forKey: "containerPort") != 0 ?
                           UserDefaults.standard.integer(forKey: "containerPort") : 3000
        self.enableNotifications = UserDefaults.standard.bool(forKey: "enableNotifications")
        self.enableMenuBarIcon = UserDefaults.standard.bool(forKey: "enableMenuBarIcon")
    }

    /// Persists the current application configuration settings to UserDefaults.
    func save() {
        UserDefaults.standard.set(autoStartContainer, forKey: "autoStartContainer")
        UserDefaults.standard.set(enableDiagnostics, forKey: "enableDiagnostics")
        UserDefaults.standard.set(checkForUpdates, forKey: "checkForUpdates")
        UserDefaults.standard.set(containerPort, forKey: "containerPort")
        UserDefaults.standard.set(enableNotifications, forKey: "enableNotifications")
        UserDefaults.standard.set(enableMenuBarIcon, forKey: "enableMenuBarIcon")
    }
}

/// Diagnostic information for troubleshooting
struct DiagnosticReport {
    let timestamp: Date
    let systemInfo: SystemInfo
    let containerStatus: ContainerStatus
    let appLogs: [String]
    let containerLogs: [String]
    let configuration: AppConfiguration

    var fileName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        return "OpenWebUI-Diagnostic-\(formatter.string(from: timestamp)).txt"
    }

    /// Generates a formatted diagnostic report containing system information, container status, application configuration, and the last 50 entries from both application and container logs.
    /// - Returns: A multi-section string summarizing the current diagnostic state of the application.
    func generateReport() -> String {
        var report = """
        OpenWebUI Desktop Diagnostic Report
        Generated: \(timestamp.formatted())

        === SYSTEM INFORMATION ===
        macOS Version: \(systemInfo.macOSVersion)
        Architecture: \(systemInfo.architecture)
        Total Memory: \(systemInfo.memoryTotalGB)
        Available Disk Space: \(systemInfo.availableDiskSpaceGB)
        App Version: \(systemInfo.appVersion) (\(systemInfo.buildNumber))

        === CONTAINER STATUS ===
        Running: \(containerStatus.isRunning)
        Health: \(containerStatus.health.displayName)
        Uptime: \(containerStatus.uptimeString)
        Memory Usage: \(containerStatus.memoryUsageString)
        CPU Usage: \(containerStatus.cpuUsageString)
        Port: \(containerStatus.port)
        Image Version: \(containerStatus.imageVersion ?? "Unknown")

        === CONFIGURATION ===
        Auto Start Container: \(configuration.autoStartContainer)
        Enable Diagnostics: \(configuration.enableDiagnostics)
        Check for Updates: \(configuration.checkForUpdates)
        Container Port: \(configuration.containerPort)
        Enable Notifications: \(configuration.enableNotifications)
        Enable Menu Bar Icon: \(configuration.enableMenuBarIcon)

        === APPLICATION LOGS ===
        """

        for log in appLogs.suffix(50) {  // Last 50 log entries
            report += "\n\(log)"
        }

        report += "\n\n=== CONTAINER LOGS ==="

        for log in containerLogs.suffix(50) {  // Last 50 log entries
            report += "\n\(log)"
        }

        return report
    }
}

/// Retrieves the current machine architecture string using the `uname` system call.
/// - Returns: The architecture identifier (e.g., "arm64", "x86_64"), or "unknown" if unavailable.

private func getCurrentArchitecture() -> String {
    var info = utsname()
    uname(&info)
    let machine = withUnsafePointer(to: &info.machine) {
        $0.withMemoryRebound(to: CChar.self, capacity: 1) {
            String(validatingUTF8: $0)
        }
    }
    return machine ?? "unknown"
}

/// Returns the available disk space in bytes for the user's home directory.
/// - Returns: The number of free bytes available, or 0 if the value cannot be determined.
private func getAvailableDiskSpace() -> UInt64 {
    if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
       let freeSize = attributes[.systemFreeSize] as? NSNumber {
        return freeSize.uint64Value
    }
    return 0
}

// MARK: - Error Types

enum ContainerError: LocalizedError {
    case unsupportedSystem(String)
    case insufficientDiskSpace(String)
    case insufficientMemory(String)
    case bundledRuntimeMissing(String)
    case bundledImageMissing(String)
    case imageLoadFailed(String)
    case containerStartFailed(String)
    case containerNotReady(String)
    case runtimeExtractionFailed(String)
    case permissionDenied(String)
    case networkError(String)
    case configurationError(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedSystem(let message),
             .insufficientDiskSpace(let message),
             .insufficientMemory(let message),
             .bundledRuntimeMissing(let message),
             .bundledImageMissing(let message),
             .imageLoadFailed(let message),
             .containerStartFailed(let message),
             .containerNotReady(let message),
             .runtimeExtractionFailed(let message),
             .permissionDenied(let message),
             .networkError(let message),
             .configurationError(let message):
            return message
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .unsupportedSystem:
            return "Please upgrade to macOS 10.15 or later."
        case .insufficientDiskSpace:
            return "Please free up disk space and try again."
        case .insufficientMemory:
            return "Close other applications to free up memory."
        case .bundledRuntimeMissing, .bundledImageMissing:
            return "Please reinstall the application."
        case .imageLoadFailed, .containerStartFailed:
            return "Try restarting the application."
        case .containerNotReady:
            return "The container may need more time to start. Please wait and try again."
        case .runtimeExtractionFailed:
            return "Check that you have write permissions to the application directory."
        case .permissionDenied:
            return "Please grant the necessary permissions in System Preferences."
        case .networkError:
            return "Check your network connection and try again."
        case .configurationError:
            return "Reset configuration in Settings and try again."
        }
    }
}
