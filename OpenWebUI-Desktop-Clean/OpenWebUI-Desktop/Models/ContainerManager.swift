//
//  ContainerManager.swift
//  OpenWebUI-Desktop
//
//  Created on December 22, 2024.
//  Core Container Management - Level 3 Complete Abstraction
//  Ported from Python installer.py with enhanced native features
//

import Foundation
import Combine
import UserNotifications

@MainActor
class ContainerManager: ObservableObject {
    // MARK: - Published Properties
    @Published var state: AppState = .initializing
    @Published var setupProgress: Double = 0.0
    @Published var statusMessage: String = "Initializing..."
    @Published var containerStatus = ContainerStatus()
    @Published var isHealthy: Bool = false

    // MARK: - Private Properties
    private let containerName = "openwebui-app"
    private let imageName = "ghcr.io/open-webui/open-webui:main"
    private let defaultPort = 3000
    private var healthCheckTimer: Timer?
    private var appLogs: [String] = []
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Configuration
    private var configuration = AppConfiguration()

    // MARK: - Paths and URLs
    private var appContainerDirectory: URL {
        let containerDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Containers")
            .appendingPathComponent("OpenWebUI")

        try? FileManager.default.createDirectory(at: containerDir, withIntermediateDirectories: true)
        return containerDir
    }

    private var runtimeDirectory: URL {
        appContainerDirectory.appendingPathComponent("runtime")
    }

    private var podmanPath: URL {
        runtimeDirectory.appendingPathComponent("podman")
    }

    private var dataDirectory: URL {
        appContainerDirectory.appendingPathComponent("data")
    }

    private var configDirectory: URL {
        appContainerDirectory.appendingPathComponent("config")
    }

    // MARK: - Initialization
    init() {
        configuration = AppConfiguration()
        setupLogging()
        setupNotifications()
    }

    // MARK: - Main Initialization Flow
    func initialize() {
        Task {
            await performInitialization()
        }
    }

    private func performInitialization() async {
        do {
            log("Starting OpenWebUI initialization")

            // Step 1: System Requirements Check
            state = .initializing
            statusMessage = "Checking system requirements..."
            setupProgress = 0.1
            await Task.sleep(nanoseconds: 500_000_000) // Brief pause for UI

            try checkSystemRequirements()
            log("System requirements check passed")

            // Step 2: Runtime Setup
            if !runtimeExists() {
                state = .extractingRuntime(progress: 0.0)
                statusMessage = "Setting up container runtime (first time only)..."
                try await extractBundledRuntime()
                log("Container runtime extracted successfully")
            } else {
                log("Container runtime already exists")
            }

            setupProgress = 0.4

            // Step 3: Image Setup
            if !await containerImageExists() {
                state = .loadingImage(progress: 0.0)
                statusMessage = "Loading Open WebUI image..."
                try await loadBundledImage()
                log("Container image loaded successfully")
            } else {
                log("Container image already exists")
            }

            setupProgress = 0.7

            // Step 4: Container Startup
            state = .startingContainer(progress: 0.0)
            statusMessage = "Starting Open WebUI..."
            try await startContainer()
            log("Container started successfully")

            setupProgress = 1.0
            state = .ready
            statusMessage = "Open WebUI is ready!"

            // Step 5: Start Health Monitoring
            startHealthMonitoring()

            // Step 6: Show Success Notification
            await showNotification(
                title: "Open WebUI Ready",
                body: "Your AI assistant is ready to use!"
            )

            log("Initialization completed successfully")

        } catch {
            let errorMessage = getUserFriendlyErrorMessage(error)
            log("Initialization failed: \(errorMessage)")
            state = .error(message: errorMessage)

            await showNotification(
                title: "Setup Error",
                body: errorMessage
            )
        }
    }

    // MARK: - System Requirements Check
    private func checkSystemRequirements() throws {
        let systemInfo = SystemInfo.current()
        log("Checking system requirements - macOS: \(systemInfo.macOSVersion), Arch: \(systemInfo.architecture)")

        // Check macOS version (require 10.15+)
        let version = ProcessInfo.processInfo.operatingSystemVersion
        if version.majorVersion < 10 || (version.majorVersion == 10 && version.minorVersion < 15) {
            throw ContainerError.unsupportedSystem("macOS 10.15 (Catalina) or later is required. You have macOS \(systemInfo.macOSVersion)")
        }

        // Check available disk space (require 3GB)
        let requiredSpace: UInt64 = 3 * 1024 * 1024 * 1024
        if systemInfo.availableDiskSpace < requiredSpace {
            throw ContainerError.insufficientDiskSpace("At least 3GB of free disk space is required. Available: \(systemInfo.availableDiskSpaceGB)")
        }

        // Check available memory (require 4GB)
        let requiredMemory: UInt64 = 4 * 1024 * 1024 * 1024
        if systemInfo.memoryTotal < requiredMemory {
            throw ContainerError.insufficientMemory("At least 4GB of RAM is required. Available: \(systemInfo.memoryTotalGB)")
        }

        log("System requirements satisfied")
    }

    // MARK: - Runtime Management
    private func runtimeExists() -> Bool {
        let exists = FileManager.default.fileExists(atPath: podmanPath.path)
        log("Runtime exists check: \(exists)")
        return exists
    }

    private func extractBundledRuntime() async throws {
        log("Starting runtime extraction")

        guard let bundledPodmanPath = Bundle.main.path(forResource: "podman", ofType: nil) else {
            throw ContainerError.bundledRuntimeMissing("Podman runtime not found in app bundle. Please reinstall the application.")
        }

        // Create runtime directory
        try FileManager.default.createDirectory(at: runtimeDirectory, withIntermediateDirectories: true)

        // Copy podman binary
        let bundledURL = URL(fileURLWithPath: bundledPodmanPath)
        try FileManager.default.copyItem(at: bundledURL, to: podmanPath)

        // Make executable
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: podmanPath.path
        )

        // Initialize podman machine (if needed)
        try await initializePodmanMachine()

        log("Runtime extraction completed")
    }

    private func initializePodmanMachine() async throws {
        log("Initializing podman machine")

        // For Level 3 abstraction, we use rootless podman
        // This sets up the initial podman configuration
        let process = Process()
        process.executableURL = podmanPath
        process.arguments = ["system", "connection", "default"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        // Don't throw error if this fails - podman might already be configured
        log("Podman machine initialization completed (exit code: \(process.terminationStatus))")
    }

    // MARK: - Image Management
    private func containerImageExists() async -> Bool {
        do {
            let output = try await runPodmanCommand(["images", "--format", "json"])
            let exists = output.contains(imageName)
            log("Container image exists check: \(exists)")
            return exists
        } catch {
            log("Error checking container image: \(error)")
            return false
        }
    }

    private func loadBundledImage() async throws {
        log("Starting image loading")

        guard let bundledImagePath = Bundle.main.path(forResource: "openwebui-image", ofType: "tar.gz") else {
            throw ContainerError.bundledImageMissing("Open WebUI image not found in app bundle. Please reinstall the application.")
        }

        // Load image using podman
        let _ = try await runPodmanCommand(["load", "-i", bundledImagePath])

        log("Image loading completed")
    }

    // MARK: - Container Management
    private func startContainer() async throws {
        log("Starting container")

        // Remove existing container if it exists
        try? await stopAndRemoveContainer()

        // Create data directory if it doesn't exist
        try FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true)

        // Start new container with comprehensive configuration
        let arguments = [
            "run", "-d",
            "--name", containerName,
            "--replace", // Replace if exists
            "-p", "\(configuration.containerPort):8080",
            "-v", "\(dataDirectory.path):/app/backend/data",
            "-e", "OLLAMA_API_BASE_URL=http://host.docker.internal:11434/api",
            "--add-host", "host.docker.internal:host-gateway",
            "--memory", "2g", // Limit memory usage
            "--cpus", "2.0", // Limit CPU usage
            imageName
        ]

        let _ = try await runPodmanCommand(arguments)

        // Wait for container to be ready
        try await waitForContainerReady()

        log("Container started successfully")
    }

    private func stopAndRemoveContainer() async throws {
        log("Stopping and removing existing container")

        // Stop container
        try? await runPodmanCommand(["stop", containerName])

        // Remove container
        try? await runPodmanCommand(["rm", "-f", containerName])

        log("Container stopped and removed")
    }

    private func waitForContainerReady() async throws {
        let maxAttempts = 60
        let checkInterval: UInt64 = 1_000_000_000 // 1 second in nanoseconds

        log("Waiting for container to become ready")

        for attempt in 1...maxAttempts {
            // Update progress
            let progress = Double(attempt) / Double(maxAttempts)
            if case .startingContainer = state {
                state = .startingContainer(progress: progress)
            }

            // Check if container is responding
            if try await isContainerResponding() {
                log("Container is ready after \(attempt) attempts")
                return
            }

            if attempt < maxAttempts {
                await Task.sleep(nanoseconds: checkInterval)
            }
        }

        throw ContainerError.containerNotReady("Container failed to become ready within \(maxAttempts) seconds")
    }

    private func isContainerResponding() async throws -> Bool {
        guard let url = URL(string: "http://localhost:\(configuration.containerPort)") else {
            return false
        }

        do {
            let request = URLRequest(url: url, timeoutInterval: 5.0)
            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                let isResponding = httpResponse.statusCode == 200
                if isResponding {
                    log("Container is responding with HTTP \(httpResponse.statusCode)")
                }
                return isResponding
            }
        } catch {
            // Expected during startup - don't log as error
            return false
        }

        return false
    }

    // MARK: - Health Monitoring
    private func startHealthMonitoring() {
        log("Starting health monitoring")

        healthCheckTimer?.invalidate()
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performHealthCheck()
            }
        }
    }

    private func performHealthCheck() async {
        do {
            let status = try await getContainerStatus()
            updateContainerStatus(status)

            if !status.isRunning && state == .ready {
                log("Container stopped unexpectedly - attempting recovery")
                await attemptRecovery()
            }

        } catch {
            log("Health check failed: \(error)")
            isHealthy = false
        }
    }

    private func updateContainerStatus(_ status: ContainerStatus) {
        containerStatus = status
        isHealthy = status.health == .healthy

        if status.isRunning && state != .ready {
            state = .ready
        }
    }

    private func attemptRecovery() async {
        log("Attempting automatic recovery")

        do {
            await showNotification(
                title: "Restarting Open WebUI",
                body: "Automatically recovering from an error..."
            )

            try await startContainer()

            await showNotification(
                title: "Recovery Successful",
                body: "Open WebUI has been restarted successfully"
            )

            log("Automatic recovery successful")

        } catch {
            log("Automatic recovery failed: \(error)")
            state = .error(message: "Container stopped unexpectedly. \(getUserFriendlyErrorMessage(error))")

            await showNotification(
                title: "Recovery Failed",
                body: "Please restart the application"
            )
        }
    }

    // MARK: - Container Status
    private func getContainerStatus() async throws -> ContainerStatus {
        let output = try await runPodmanCommand(["ps", "--filter", "name=\(containerName)", "--format", "json"])

        // Parse JSON output to get container status
        if let data = output.data(using: .utf8),
           let containers = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let container = containers.first {

            let isRunning = (container["State"] as? String) == "running"
            let status = container["Status"] as? String ?? ""

            // Get additional stats if container is running
            var memoryUsage: UInt64?
            var cpuUsage: Double?

            if isRunning {
                do {
                    let statsOutput = try await runPodmanCommand(["stats", "--no-stream", "--format", "json", containerName])
                    if let statsData = statsOutput.data(using: .utf8),
                       let stats = try? JSONSerialization.jsonObject(with: statsData) as? [String: Any] {

                        if let memUsage = stats["MemUsage"] as? String {
                            // Parse memory usage (format: "123MB / 2GB")
                            let components = memUsage.components(separatedBy: " / ")
                            if let first = components.first, first.hasSuffix("MB") {
                                let numString = String(first.dropLast(2))
                                if let mb = Double(numString) {
                                    memoryUsage = UInt64(mb * 1024 * 1024)
                                }
                            }
                        }

                        if let cpu = stats["CPU"] as? String, cpu.hasSuffix("%") {
                            let numString = String(cpu.dropLast(1))
                            cpuUsage = Double(numString)
                        }
                    }
                } catch {
                    // Stats are optional - don't fail if we can't get them
                    log("Could not get container stats: \(error)")
                }
            }

            let health: ContainerHealth = isRunning ? .healthy : .stopped

            return ContainerStatus(
                isRunning: isRunning,
                health: health,
                uptime: nil, // TODO: Calculate from start time
                memoryUsage: memoryUsage,
                cpuUsage: cpuUsage,
                port: configuration.containerPort,
                imageVersion: nil // TODO: Get from image metadata
            )
        }

        return ContainerStatus(isRunning: false, health: .stopped, port: configuration.containerPort)
    }

    // MARK: - Podman Command Execution
    private func runPodmanCommand(_ arguments: [String]) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = podmanPath
            process.arguments = arguments

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            process.terminationHandler = { process in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""

                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    let error = ContainerError.containerStartFailed("Command failed: \(arguments.joined(separator: " "))\nOutput: \(output)")
                    continuation.resume(throwing: error)
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: ContainerError.containerStartFailed("Failed to execute command: \(error)"))
            }
        }
    }

    // MARK: - Public Control Methods
    func restart() {
        Task {
            await performInitialization()
        }
    }

    func stop() {
        Task {
            do {
                state = .stopped
                try await stopAndRemoveContainer()
                healthCheckTimer?.invalidate()
                log("Container stopped by user")
            } catch {
                log("Error stopping container: \(error)")
            }
        }
    }

    func openInBrowser() {
        let url = URL(string: "http://localhost:\(configuration.containerPort)")!
        NSWorkspace.shared.open(url)
        log("Opened in browser: \(url)")
    }

    // MARK: - Diagnostics
    func generateDiagnostics() {
        Task {
            do {
                let diagnostics = await createDiagnosticReport()
                let report = diagnostics.generateReport()

                let savePanel = NSSavePanel()
                savePanel.nameFieldStringValue = diagnostics.fileName
                savePanel.allowedContentTypes = [.plainText]
                savePanel.title = "Save Diagnostic Report"

                if savePanel.runModal() == .OK, let url = savePanel.url {
                    try report.write(to: url, atomically: true, encoding: .utf8)

                    await showNotification(
                        title: "Diagnostic Report Saved",
                        body: "Report saved to \(url.lastPathComponent)"
                    )

                    log("Diagnostic report saved to: \(url.path)")
                }
            } catch {
                log("Error generating diagnostics: \(error)")
            }
        }
    }

    private func createDiagnosticReport() async -> DiagnosticReport {
        let containerLogs = await getContainerLogs()

        return DiagnosticReport(
            timestamp: Date(),
            systemInfo: SystemInfo.current(),
            containerStatus: containerStatus,
            appLogs: Array(appLogs.suffix(100)),
            containerLogs: containerLogs,
            configuration: configuration
        )
    }

    private func getContainerLogs() async -> [String] {
        do {
            let output = try await runPodmanCommand(["logs", "--tail", "100", containerName])
            return output.components(separatedBy: .newlines).filter { !$0.isEmpty }
        } catch {
            return ["Error retrieving container logs: \(error)"]
        }
    }

    // MARK: - Notifications
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                self.log("Notification permission error: \(error)")
            } else {
                self.log("Notification permission granted: \(granted)")
            }
        }
    }

    private func showNotification(title: String, body: String) async {
        guard configuration.enableNotifications else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Logging
    private func setupLogging() {
        // Initialize logging system
        log("ContainerManager initialized")
    }

    private func log(_ message: String) {
        let timestamp = DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] \(message)"
        appLogs.append(logEntry)

        // Keep only last 1000 log entries
        if appLogs.count > 1000 {
            appLogs.removeFirst(appLogs.count - 1000)
        }

        print("🔧 ContainerManager: \(message)")
    }

    // MARK: - Error Handling
    private func getUserFriendlyErrorMessage(_ error: Error) -> String {
        if let containerError = error as? ContainerError {
            return containerError.localizedDescription
        }

        let message = error.localizedDescription

        // Translate common technical errors to user-friendly messages
        if message.contains("permission denied") {
            return "Permission denied. Please check that the app has necessary permissions."
        } else if message.contains("address already in use") {
            return "Port \(configuration.containerPort) is already in use. Please close other applications using this port or change the port in settings."
        } else if message.contains("no such file") {
            return "Required files are missing. Please reinstall the application."
        } else if message.contains("network") {
            return "Network error. Please check your internet connection."
        }

        return "An unexpected error occurred: \(message)"
    }

    // MARK: - Cleanup
    deinit {
        healthCheckTimer?.invalidate()
        log("ContainerManager deinitialized")
    }
}
