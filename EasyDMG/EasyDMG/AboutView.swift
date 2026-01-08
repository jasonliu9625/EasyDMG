//
//  AboutView.swift
//  EasyDMG
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var updater: UpdaterController
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Hero Section
            VStack(spacing: 16) {
                if let appIcon = NSApplication.shared.applicationIconImage {
                    Image(nsImage: appIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
                }
                
                VStack(spacing: 4) {
                    Text("EasyDMG")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    
                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 40)
            .padding(.bottom, 24)
            
            // Info Content
//            Text("EasyDMG is a free tool designed to make DMG creation effortless and beautiful for macOS developers.")
//                .font(.system(size: 13))
//                .foregroundColor(.secondary)
//                .multilineTextAlignment(.center)
//                .lineSpacing(4)
//                .padding(.horizontal, 40)
//                .fixedSize(horizontal: false, vertical: true)
//                .padding(.bottom, 24)
            
            // Update Check Section
            HStack(spacing: 12) {
                Button(action: {
                    updater.checkForUpdates()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12, weight: .bold))
                        Text("Check for Updates")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .disabled(!updater.canCheckForUpdates)
                
                if let lastDate = updater.lastUpdateCheckDate {
                    Text(lastDate, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 24)
            
            Spacer()
            
            // Action Links
            HStack(spacing: 16) {
                AboutLinkButton(
                    title: "GitHub",
                    imageName: "GitHub",
                    systemImage: false,
                    description: "Source Code",
                    action: {
                        TelemetryManager.githubClicked()
                        openURL("https://github.com/jasonliu9625")
                    }
                )
                
                AboutLinkButton(
                    title: "Ko-fi",
                    imageName: "kofi_symbol",
                    systemImage: false,
                    description: "Support Us",
                    action: {
                        TelemetryManager.kofiClicked()
                        openURL("https://ko-fi.com/huatingliu")
                    }
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            
            // Footer
            VStack(spacing: 16) {
                Divider()
                    .padding(.horizontal, 32)
                
                HStack {
                    Text("© 2026 EasyDMG")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Close") {
                        TelemetryManager.aboutClosed()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .keyboardShortcut(.cancelAction)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .frame(width: 360, height: 460)
        .background(
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                
                // Subtle gradient accent
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.05),
                        Color.clear,
                        Color.purple.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .onAppear {
            TelemetryManager.aboutOpened()
        }
    }
    
    private func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}

struct AboutLinkButton: View {
    let title: String
    let imageName: String
    let systemImage: Bool
    let description: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if systemImage {
                    Image(systemName: imageName)
                        .font(.system(size: 24))
                        .foregroundColor(.primary)
                } else if let assetImage = NSImage(named: imageName) {
                    Image(nsImage: assetImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                } else {
                    // Fallback
                    Image(systemName: "link")
                        .font(.system(size: 24))
                        .foregroundColor(.primary)
                }
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isHovered ? Color.secondary.opacity(0.1) : Color.secondary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isHovered ? Color.secondary.opacity(0.2) : Color.secondary.opacity(0.1), lineWidth: 1)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Preview

#Preview {
    AboutView()
}
