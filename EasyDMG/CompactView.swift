import SwiftUI
import UniformTypeIdentifiers

struct CompactView: View {
    @Binding var appMetadata: AppMetadata?
    @Binding var schema: DMGLayoutSchema
    let isBuilding: Bool
    let progress: Double
    let onBuild: () -> Void
    let onAdvancedSettings: () -> Void
    
    @State private var isHovering = false
    @State private var isHoveringGear = false
    @State private var isHoveringAbout = false
    @State private var showingAbout = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top: Drag & Drop Zone
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .foregroundColor(isHovering ? .accentColor : .secondary.opacity(0.3))
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isHovering ? Color.accentColor.opacity(0.05) : Color.clear)
                    )
                
                if let meta = appMetadata {
                    VStack(spacing: 12) {
                        Image(nsImage: meta.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 90, height: 90)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        
                        VStack(spacing: 4) {
                            Text(meta.name)
                                .font(.headline)
                            
                            Text(meta.version)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                appMetadata = nil
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.secondary.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                        .help("Remove App")
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(y: 10)),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 44))
                            .foregroundColor(isHovering ? .accentColor : .secondary)
                        
                        Text("Drop or Click to Creat DMG")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 1.1)))
                }
            }
            .contentShape(Rectangle())
            .padding(20)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.3)) {
                    isHovering = hovering
                }
            }
            .onTapGesture {
                selectFile()
            }
            .onDrop(of: [UTType.fileURL], isTargeted: $isHovering) { providers in
                guard let provider = providers.first else { return false }
                
                provider.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, error in
                    guard let data = data,
                          let urlString = String(data: data, encoding: .utf8),
                          let url = URL(string: urlString) else { return }
                    
                    DispatchQueue.main.async {
                        if let meta = AppMetadata.from(url: url) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
                                self.appMetadata = meta
                            }
                        }
                    }
                }
                return true
            }
            
            if isBuilding || progress > 0 {
                VStack(spacing: 4) {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(.linear)
                        .controlSize(.small)
                        .tint(progress >= 1.0 ? .green : .accentColor)
                        .animation(.spring, value: progress)
                    
                    HStack {
                        if progress >= 1.0 {
                            Label("Complete!", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Text("Building DMG...")
                        }
                        Spacer()
                        Text("\(Int(progress * 100))%")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 15)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Divider()
            
            // Bottom Bar
            HStack(spacing: 15) {
                // 关于按钮
                Button(action: {
                    TelemetryManager.aboutButtonClicked()
                    showingAbout = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(isHoveringAbout ? .accentColor : .secondary)
                        .font(.title2)
                        .scaleEffect(isHoveringAbout ? 1.2 : 1.0)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isHoveringAbout = hovering
                    }
                }
                .help("About EasyDMG")
                
                Button(action: onAdvancedSettings) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(isHoveringGear ? .accentColor : .secondary)
                        .rotationEffect(.degrees(isHoveringGear ? 45 : 0))
                        .scaleEffect(isHoveringGear ? 1.4 : 1.2)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isHoveringGear = hovering
                    }
                }
                .help("Advanced Settings")
                
//                Toggle("Version", isOn: $schema.includeVersionInFilename)
//                    .toggleStyle(.checkbox)
//                    .disabled(appMetadata == nil)
//                
                Spacer()
                
                Button(action: onBuild) {
                    if isBuilding {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.horizontal, 4)
                    } else {
                        Text("Create")
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(appMetadata == nil || isBuilding)
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        }
        .frame(width: 310, height: 350)
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
    
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.application]
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                if let meta = AppMetadata.from(url: url) {
                    withAnimation {
                        self.appMetadata = meta
                    }
                }
            }
        }
    }
}

#Preview("Compact View") {
    CompactView(
        appMetadata: .constant(nil),
        schema: .constant(.standard),
        isBuilding: false,
        progress: 0,
        onBuild: {},
        onAdvancedSettings: {}
    )
}

#Preview("Compact View with App") {
    let mockMeta = AppMetadata(
        name: "TestApp",
        icon: NSWorkspace.shared.icon(forFile: "/Applications/Safari.app"),
        version: "1.0.0",
        url: URL(fileURLWithPath: "/Applications/Safari.app")
    )
    
    CompactView(
        appMetadata: .constant(mockMeta),
        schema: .constant(.standard),
        isBuilding: false,
        progress: 0,
        onBuild: {},
        onAdvancedSettings: {}
    )
}
