//
//  SetupView.swift
//  OpenWebUI-Desktop
//
//  Created on December 22, 2024.
//  Setup Progress View - Level 3 Complete Abstraction
//

import SwiftUI

struct SetupView: View {
    @EnvironmentObject private var containerManager: ContainerManager
    @State private var animateIcon = false

    var body: some View {
        VStack(spacing: 40) {
            // App Icon with Animation
            ZStack {
                // Background circle
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)

                // Main icon
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.accentColor)
                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: animateIcon
                    )
            }

            // Status Information
            VStack(spacing: 16) {
                Text("Setting up Open WebUI")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(containerManager.statusMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
                    .lineLimit(3)

                // Progress Section
                VStack(spacing: 12) {
                    ProgressView(value: containerManager.setupProgress)
                        .progressViewStyle(CustomProgressViewStyle())
                        .frame(width: 360)

                    HStack {
                        Text("\(Int(containerManager.setupProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(progressStageText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 360)
                }
            }

            // Additional Information Based on State
            additionalInfoView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            animateIcon = true
        }
    }

    @ViewBuilder
    private var additionalInfoView: some View {
        VStack(spacing: 8) {
            switch containerManager.state {
            case .extractingRuntime:
                VStack(spacing: 8) {
                    Text("First-time setup")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)

                    Text("This happens only once - preparing container runtime...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                }

            case .loadingImage:
                VStack(spacing: 8) {
                    Text("Loading AI models")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)

                    Text("Setting up the Open WebUI interface and AI capabilities...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                }

            case .startingContainer:
                VStack(spacing: 8) {
                    Text("Almost ready")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)

                    Text("Starting your AI assistant...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                }

            case .initializing:
                VStack(spacing: 8) {
                    Text("Checking system")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)

                    Text("Verifying your Mac is ready for Open WebUI...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                }

            default:
                EmptyView()
            }
        }
        .padding(.horizontal, 20)
    }

    private var progressStageText: String {
        switch containerManager.state {
        case .initializing:
            return "Initializing"
        case .extractingRuntime:
            return "Runtime Setup"
        case .loadingImage:
            return "Loading Models"
        case .startingContainer:
            return "Starting"
        default:
            return "Processing"
        }
    }
}

// MARK: - Custom Progress View Style
struct CustomProgressViewStyle: ProgressViewStyle {
    /// Creates a custom progress bar view with a rounded background and animated gradient fill reflecting the current progress.
    /// - Parameter configuration: The progress view configuration containing the current completion fraction.
    /// - Returns: A view representing the styled progress bar.
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            // Background track
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 8)

            // Progress fill
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [.accentColor, .accentColor.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: CGFloat(configuration.fractionCompleted ?? 0) * 360, height: 8)
                .animation(.easeInOut(duration: 0.3), value: configuration.fractionCompleted)
        }
    }
}

// MARK: - Shimmer Effect for Loading States
struct ShimmerEffect: View {
    @State private var animateShimmer = false

    var body: some View {
        LinearGradient(
            colors: [
                Color.clear,
                Color.white.opacity(0.3),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .rotationEffect(.degrees(20))
        .offset(x: animateShimmer ? 400 : -400)
        .onAppear {
            withAnimation(
                Animation.linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                animateShimmer = true
            }
        }
    }
}

// MARK: - Preview
struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Initializing state
            SetupView()
                .environmentObject({
                    let manager = ContainerManager()
                    manager.state = .initializing
                    manager.setupProgress = 0.1
                    manager.statusMessage = "Checking system requirements..."
                    return manager
                }())
                .previewDisplayName("Initializing")

            // Runtime extraction state
            SetupView()
                .environmentObject({
                    let manager = ContainerManager()
                    manager.state = .extractingRuntime(progress: 0.4)
                    manager.setupProgress = 0.4
                    manager.statusMessage = "Setting up container runtime (first time only)..."
                    return manager
                }())
                .previewDisplayName("Extracting Runtime")

            // Loading image state
            SetupView()
                .environmentObject({
                    let manager = ContainerManager()
                    manager.state = .loadingImage(progress: 0.7)
                    manager.setupProgress = 0.7
                    manager.statusMessage = "Loading Open WebUI image..."
                    return manager
                }())
                .previewDisplayName("Loading Image")

            // Starting container state
            SetupView()
                .environmentObject({
                    let manager = ContainerManager()
                    manager.state = .startingContainer(progress: 0.9)
                    manager.setupProgress = 0.9
                    manager.statusMessage = "Starting Open WebUI..."
                    return manager
                }())
                .previewDisplayName("Starting Container")
        }
        .frame(width: 800, height: 600)
    }
}
