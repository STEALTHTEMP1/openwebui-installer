//
//  OpenWebUIApp.swift
//  OpenWebUI-Desktop
//
//  Created on December 22, 2024.
//  Level 3 Complete Abstraction - Native macOS App for Open WebUI
//

import SwiftUI

@main
struct OpenWebUIApp: App {
    @StateObject private var containerManager = ContainerManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(containerManager)
                .frame(minWidth: 1000, minHeight: 700)
                .onAppear {
                    setupAppEnvironment()
                }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button("About Open WebUI") {
                    showAboutPanel()
                }
                .keyboardShortcut("a", modifiers: [.command, .shift])

                Divider()

                Button("Generate Diagnostic Report") {
                    containerManager.generateDiagnostics()
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
        }
    }

    private func setupAppEnvironment() {
        // Configure app-level settings
        UserDefaults.standard.register(defaults: [
            "autoStartContainer": true,
            "enableDiagnostics": true,
            "checkForUpdates": true
        ])
    }

    private func showAboutPanel() {
        let alert = NSAlert()
        alert.messageText = "Open WebUI Desktop"
        alert.informativeText = """
        A native macOS application for Open WebUI

        Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")

        This application provides a seamless desktop experience for Open WebUI,
        with complete Docker abstraction and native macOS integration.

        Open WebUI is developed by Timothy Jaeryang Baek and contributors.
        Licensed under modified BSD-3-Clause license.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
