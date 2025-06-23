import Foundation

/// Simple container manager calling the existing Python installer.
struct ContainerManager {
    /// Run the Python-based installer using the `openwebui-installer` CLI.
    static func install() throws {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        proc.arguments = ["openwebui-installer", "install"]
        try proc.run()
        proc.waitUntilExit()
    }
}

print("Starting Open WebUI installer...")
try? ContainerManager.install()
