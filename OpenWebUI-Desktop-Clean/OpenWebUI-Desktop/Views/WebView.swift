//
//  WebView.swift
//  OpenWebUI-Desktop
//
//  Created on December 22, 2024.
//  WKWebView Wrapper for Open WebUI - Level 3 Complete Abstraction
//

import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    let url: URL
    @State private var webView: WKWebView?
    @State private var isLoading = true
    @State private var canGoBack = false
    @State private var canGoForward = false

    /// Creates and configures a WKWebView instance for embedding in SwiftUI, tailored for the Open WebUI desktop experience.
    /// - Parameter context: The context provided by SwiftUI for coordinating updates and delegates.
    /// - Returns: A configured WKWebView with custom preferences, navigation/UI delegates, and state observers for integration with the parent SwiftUI view.
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()

        // Configure for optimal Open WebUI experience
        configuration.preferences.javaScriptEnabled = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.allowsInlineMediaPlayback = true

        // Enable developer tools in debug builds
        #if DEBUG
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        #endif

        // Configure user agent to identify as desktop
        configuration.applicationNameForUserAgent = "OpenWebUI-Desktop/1.0"

        // Configure media permissions
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        // Configure appearance
        webView.setValue(false, forKey: "drawsBackground")
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsMagnification = true
        webView.magnification = 1.0

        // Set up observers
        webView.addObserver(context.coordinator, forKeyPath: "canGoBack", options: .new, context: nil)
        webView.addObserver(context.coordinator, forKeyPath: "canGoForward", options: .new, context: nil)
        webView.addObserver(context.coordinator, forKeyPath: "isLoading", options: .new, context: nil)

        // Store reference
        DispatchQueue.main.async {
            self.webView = webView
        }

        return webView
    }

    /// Updates the WKWebView with the specified URL if it differs from the current one.
    /// - Parameter nsView: The WKWebView instance to update.
    /// - Parameter context: The context provided by SwiftUI for view updates.
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Only load if URL is different from current URL
        if nsView.url?.absoluteString != url.absoluteString {
            let request = URLRequest(url: url, timeoutInterval: 30.0)
            nsView.load(request)
        }
    }

    /// Creates and returns a coordinator to manage navigation and UI delegate callbacks for the web view.
    /// - Returns: A `Coordinator` instance linked to this `WebView`.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    /// Reloads the current page in the embedded web view.
    func reload() {
        webView?.reload()
    }

    /// Navigates the web view to the previous page in its history, if available.
    func goBack() {
        webView?.goBack()
    }

    /// Navigates the web view forward to the next page in the browsing history, if available.
    func goForward() {
        webView?.goForward()
    }

    /// Stops the current page load in the embedded web view, if one is in progress.
    func stopLoading() {
        webView?.stopLoading()
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        /// Called when the web view begins loading a new page.
        /// Updates the loading state and logs the start of navigation.
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
            print("🌐 WebView: Started loading \(webView.url?.absoluteString ?? "unknown URL")")
        }

        /// Called when the web view finishes loading a page.
        /// Updates loading and navigation state, and injects custom styles and scripts for enhanced native integration.
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
            }

            print("✅ WebView: Finished loading Open WebUI")

            // Inject custom CSS for better native integration (optional)
            injectCustomStyles(webView)
        }

        /// Handles navigation failures by updating the loading state and logging the error.
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
            print("❌ WebView: Navigation failed with error: \(error.localizedDescription)")
        }

        /// Handles failures during the provisional navigation phase of the web view.
        /// 
        /// Updates the loading state and, if the failure is due to an inability to connect to the host, displays a user-friendly connection error page.
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
            print("❌ WebView: Provisional navigation failed: \(error.localizedDescription)")

            // Show user-friendly error if Open WebUI is not ready
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCannotConnectToHost {
                showConnectionError(webView)
            }
        }

        /// Determines whether a navigation action should be allowed or canceled based on the destination URL.
        /// - Parameters:
        ///   - webView: The WKWebView requesting the navigation decision.
        ///   - navigationAction: The navigation action being evaluated.
        ///   - decisionHandler: Closure to call with the navigation policy.
        /// 
        /// Cancels navigation and opens the URL in the default browser if the destination is not localhost or 127.0.0.1. Allows navigation for local URLs.
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }

            // Handle external links
            if url.host != "localhost" && url.host != "127.0.0.1" {
                // Open external links in default browser
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            // Allow localhost navigation
            decisionHandler(.allow)
        }

        /// Handles requests to open new windows (e.g., popups) by loading the requested URL in the main web view instead of creating a new window.
        /// - Returns: Always returns nil to prevent the creation of a new WKWebView.
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // Handle popup windows by loading in main webview
            if let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }

        /// Presents a native macOS alert dialog in response to a JavaScript `alert()` call from the web content.
        /// - Parameters:
        ///   - webView: The web view invoking the alert.
        ///   - message: The message to display in the alert dialog.
        ///   - frame: The frame that initiated the alert.
        ///   - completionHandler: The closure to call after the alert is dismissed.
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            // Show native alert for JavaScript alerts
            let alert = NSAlert()
            alert.messageText = "Open WebUI"
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
            completionHandler()
        }

        /// Presents a native macOS confirmation dialog in response to a JavaScript `confirm()` call from the web content.
        /// - Parameters:
        ///   - webView: The web view requesting the confirmation dialog.
        ///   - message: The message to display in the confirmation dialog.
        ///   - frame: The frame that initiated the request.
        ///   - completionHandler: Completion handler called with `true` if the user confirms, or `false` if canceled.
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            // Show native confirmation dialog
            let alert = NSAlert()
            alert.messageText = "Open WebUI"
            alert.informativeText = message
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            completionHandler(response == .alertFirstButtonReturn)
        }

        /// Handles updates to observed WKWebView properties and synchronizes navigation and loading state with the parent WebView.
        /// - Parameters:
        ///   - keyPath: The key path of the property that changed.
        ///   - object: The observed object, expected to be a WKWebView.
        ///   - change: A dictionary containing the changes to the observed property.
        ///   - context: The context pointer passed when adding the observer.
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if let webView = object as? WKWebView {
                DispatchQueue.main.async {
                    switch keyPath {
                    case "canGoBack":
                        self.parent.canGoBack = webView.canGoBack
                    case "canGoForward":
                        self.parent.canGoForward = webView.canGoForward
                    case "isLoading":
                        self.parent.isLoading = webView.isLoading
                    default:
                        break
                    }
                }
            }
        }

        /// Injects custom CSS and JavaScript into the provided WKWebView to enhance native integration.
        /// 
        /// This includes enabling text selection, improving scrolling, hiding scrollbars, and adding native-like keyboard shortcuts for reload and zoom functionality. The enhancements are applied after the page loads to provide a more seamless desktop experience.
        private func injectCustomStyles(_ webView: WKWebView) {
            let css = """
            /* Custom styles for better native integration */
            body {
                -webkit-user-select: text;
                -webkit-touch-callout: default;
            }

            /* Improve scrolling on macOS */
            * {
                -webkit-overflow-scrolling: touch;
            }

            /* Hide any scrollbars that might interfere with native look */
            ::-webkit-scrollbar {
                width: 0px;
                background: transparent;
            }
            """

            let script = """
            var style = document.createElement('style');
            style.innerHTML = `\(css)`;
            document.head.appendChild(style);

            // Add native-like keyboard shortcuts
            document.addEventListener('keydown', function(e) {
                // Cmd+R for reload
                if (e.metaKey && e.key === 'r') {
                    e.preventDefault();
                    window.location.reload();
                }

                // Cmd+Plus/Minus for zoom
                if (e.metaKey && (e.key === '+' || e.key === '=')) {
                    e.preventDefault();
                    document.body.style.zoom = (parseFloat(document.body.style.zoom) || 1) + 0.1;
                }
                if (e.metaKey && e.key === '-') {
                    e.preventDefault();
                    document.body.style.zoom = Math.max(0.5, (parseFloat(document.body.style.zoom) || 1) - 0.1);
                }
                if (e.metaKey && e.key === '0') {
                    e.preventDefault();
                    document.body.style.zoom = 1;
                }
            });

            // Notify native app that page is ready
            console.log('Open WebUI page fully loaded and enhanced');
            """

            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    print("⚠️ WebView: Error injecting custom styles: \(error)")
                }
            }
        }

        /// Loads a custom HTML error page into the provided WKWebView to indicate a connection issue with Open WebUI, displaying a spinner and auto-refreshing every 3 seconds.
        /// - Parameter webView: The WKWebView instance in which to display the connection error page.
        private func showConnectionError(_ webView: WKWebView) {
            let errorHTML = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <title>Connecting to Open WebUI</title>
                <style>
                    body {
                        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                        display: flex;
                        justify-content: center;
                        align-items: center;
                        height: 100vh;
                        margin: 0;
                        background: #f5f5f5;
                        color: #333;
                    }
                    .container {
                        text-align: center;
                        max-width: 400px;
                        padding: 40px;
                    }
                    .icon {
                        font-size: 64px;
                        margin-bottom: 20px;
                        opacity: 0.6;
                    }
                    h1 {
                        font-size: 24px;
                        font-weight: 500;
                        margin-bottom: 12px;
                        color: #1d1d1f;
                    }
                    p {
                        font-size: 16px;
                        line-height: 1.5;
                        color: #666;
                        margin-bottom: 24px;
                    }
                    .spinner {
                        border: 3px solid #f3f3f3;
                        border-top: 3px solid #007AFF;
                        border-radius: 50%;
                        width: 32px;
                        height: 32px;
                        animation: spin 1s linear infinite;
                        margin: 0 auto;
                    }
                    @keyframes spin {
                        0% { transform: rotate(0deg); }
                        100% { transform: rotate(360deg); }
                    }
                </style>
                <script>
                    // Auto-refresh every 3 seconds
                    setTimeout(function() {
                        window.location.reload();
                    }, 3000);
                </script>
            </head>
            <body>
                <div class="container">
                    <div class="icon">🔄</div>
                    <h1>Connecting to Open WebUI</h1>
                    <p>Starting your AI assistant...<br>This usually takes a few seconds.</p>
                    <div class="spinner"></div>
                </div>
            </body>
            </html>
            """

            webView.loadHTMLString(errorHTML, baseURL: nil)
        }

        deinit {
            // Clean up observers
            parent.webView?.removeObserver(self, forKeyPath: "canGoBack")
            parent.webView?.removeObserver(self, forKeyPath: "canGoForward")
            parent.webView?.removeObserver(self, forKeyPath: "isLoading")
        }
    }
}

// MARK: - WebView Controls
struct WebViewControls: View {
    let webView: WebView
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool

    var body: some View {
        HStack(spacing: 8) {
            Button(action: { webView.goBack() }) {
                Image(systemName: "chevron.left")
            }
            .disabled(!canGoBack)

            Button(action: { webView.goForward() }) {
                Image(systemName: "chevron.right")
            }
            .disabled(!canGoForward)

            Button(action: {
                if isLoading {
                    webView.stopLoading()
                } else {
                    webView.reload()
                }
            }) {
                Image(systemName: isLoading ? "stop" : "arrow.clockwise")
            }

            if isLoading {
                ProgressView()
                    .scaleEffect(0.6)
            }
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
    }
}

// MARK: - Preview
struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        WebView(url: URL(string: "http://localhost:3000")!)
            .frame(width: 800, height: 600)
    }
}
