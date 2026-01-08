import SwiftUI
import UniformTypeIdentifiers
import AppKit
import TelemetryDeck

struct PreviewWithAboutView: View {
    @Binding var schema: DMGLayoutSchema
    @Binding var textLabels: [TextLabel]
    let appMetadata: AppMetadata?
    
    @State private var gridSpacing: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 预览内容
            ZStack(alignment: .top) {
                DMGPreviewView(schema: $schema, appMetadata: appMetadata, gridSpacing: gridSpacing, textLabels: $textLabels)
                
                PreviewToolbar(gridSpacing: $gridSpacing, schema: $schema, textLabels: $textLabels)
                    .padding(.top, 4)
            }
        }
    }
}

struct ContentView: View {
    @State private var appMetadata: AppMetadata?
    @State private var schema = DMGLayoutSchema.standard
    @State private var textLabels: [TextLabel] = []
    @State private var isBuilding = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var isAdvancedMode = false
    @State private var buildProgress: Double = 0
    @State private var showingAbout = false
    
    var body: some View {
        ZStack {
            if isAdvancedMode {
                if let meta = appMetadata {
                    NavigationSplitView {
                        SettingsView(
                            schema: $schema,
                            appVersion: meta.version,
                            isBuilding: isBuilding,
                            buildProgress: buildProgress
                        ) {
                            startBuildProcess(meta: meta)
                        }
                        .navigationSplitViewColumnWidth(min: 250, ideal: 300)
                    } detail: {
                        PreviewWithAboutView(schema: $schema, textLabels: $textLabels, appMetadata: meta)
                            .padding()
                    }
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button(action: {
                                TelemetryManager.aboutButtonClicked()
                                showingAbout = true
                            }) {
                                Image(systemName: "info.circle")
                                    .font(.title3)
                            }
                            .help("About EasyDMG")
                        }
                    }
                } else {
                    DragDropZone(appMetadata: $appMetadata)
                }
            } else {
                CompactView(
                    appMetadata: $appMetadata,
                    schema: $schema,
                    isBuilding: isBuilding,
                    progress: buildProgress,
                    onBuild: {
                        if let meta = appMetadata {
                            startBuildProcess(meta: meta)
                        }
                    },
                    onAdvancedSettings: {
                        // 发送高级模式切换事件
                        TelemetryDeck.signal("ui.advanced_mode.enabled")
                        
                        withAnimation {
                            isAdvancedMode = true
                            resizeWindow(to: NSSize(width: 800, height: 530))
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onChange(of: appMetadata) { oldValue, newValue in
            // Reset progress when app changes
            buildProgress = 0
            
            // 发送应用选择事件
            if let app = newValue {
                TelemetryDeck.signal("app.selected", parameters: [
                    "appName": app.name,
                    "appVersion": app.version,
                    "hasVersion": !app.version.isEmpty ? "true" : "false"
                ])
            }
            
            // Only auto-resize if we are already in advanced mode
            if isAdvancedMode {
                if newValue != nil {
                    resizeWindow(to: NSSize(width: 800, height: 530))
                } else {
                    resizeWindow(to: NSSize(width: 500, height: 400)) // Smaller but still advanced
                }
            }
        }
    }
    
    // MARK: - 窗口大小调整
    
    private func resizeWindow(to size: NSSize) {
        guard let window = NSApplication.shared.windows.first else { return }
        
        // 获取当前窗口中心点
        let currentFrame = window.frame
        let centerX = currentFrame.midX
        let centerY = currentFrame.midY
        
        // 计算新的窗口位置（保持中心点不变）
        let newOriginX = centerX - size.width / 2
        let newOriginY = centerY - size.height / 2
        
        let newFrame = NSRect(x: newOriginX, y: newOriginY, width: size.width, height: size.height)
        window.setFrame(newFrame, display: true, animate: true)
    }

    
    // MARK: - Build Logic
    
    func startBuildProcess(meta: AppMetadata) {
        // 发送构建开始事件
        TelemetryDeck.signal("build.initiated", parameters: [
            "appName": meta.name,
            "includeVersion": schema.includeVersionInFilename ? "true" : "false",
            "customBackground": schema.customBackgroundURL != nil ? "true" : "false"
        ])
        
        // 根据设置生成文件名
        let fileName: String
        if schema.includeVersionInFilename && !meta.version.isEmpty {
            fileName = "\(meta.name) \(meta.version).dmg"
        } else {
            fileName = "\(meta.name).dmg"
        }
        
        let outputURL = schema.outputDirectory.appendingPathComponent(fileName)
        
        // 检查文件是否已存在
        if FileManager.default.fileExists(atPath: outputURL.path) {
            // 发送文件覆盖提示事件
            TelemetryDeck.signal("build.file_exists_prompt")
            
            let alert = NSAlert()
            alert.messageText = "File Already Exists"
            alert.informativeText = "Do you want to replace \"\(fileName)\"?"
            alert.addButton(withTitle: "Replace")
            alert.addButton(withTitle: "Cancel")
            alert.alertStyle = .warning
            
            if alert.runModal() == .alertFirstButtonReturn {
                TelemetryDeck.signal("build.file_replaced")
                self.runBuild(meta: meta, outputURL: outputURL)
            } else {
                TelemetryDeck.signal("build.cancelled_by_user")
            }
        } else {
            self.runBuild(meta: meta, outputURL: outputURL)
        }
    }
    
    func runBuild(meta: AppMetadata, outputURL: URL) {
        isBuilding = true
        buildProgress = 0
        
        // 捕获当前的 textLabels
        let currentTextLabels = self.textLabels
        
        // Run in background
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 1. Generate Info
                let bgURL = try self.ensureBackgroundAsset(name: self.schema.backgroundAssetName, size: self.schema.windowSize, textLabels: currentTextLabels)
                
                // 2. Build
                try DMGBuilder.createDMG(
                    for: meta,
                    schema: self.schema,
                    outputURL: outputURL,
                    backgroundURL: bgURL,
                    progress: { p in
                        DispatchQueue.main.async {
                            self.buildProgress = p
                        }
                    }
                )
                
                DispatchQueue.main.async {
                    self.isBuilding = false
                    self.buildProgress = 1.0
                    
                    // 发送构建成功事件
                    TelemetryDeck.signal("build.success", parameters: [
                        "appName": meta.name,
                        "outputPath": outputURL.lastPathComponent
                    ])
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isBuilding = false
                    self.alertTitle = "Build Failed"
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                    
                    // 发送构建失败事件
                    TelemetryDeck.signal("build.failed", parameters: [
                        "appName": meta.name,
                        "error": error.localizedDescription
                    ])
                }
            }
        }
    }
    
    // Helper to extract background from Assets/Bundle or custom URL
    func ensureBackgroundAsset(name: String, size: CGSize, textLabels: [TextLabel] = []) throws -> URL {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("EasyDMG_Assets")
        try? fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let fileURL = tempDir.appendingPathComponent("\(UUID().uuidString).tiff")
        
        // Helper to resize, render text labels, and save as TIFF
        func resizeAndSave(_ sourceImage: NSImage) throws -> URL {
            let targetImage = NSImage(size: size)
            targetImage.lockFocus()
            
            // 绘制背景图
            sourceImage.draw(in: NSRect(origin: .zero, size: size),
                           from: NSRect(origin: .zero, size: sourceImage.size),
                           operation: .copy,
                           fraction: 1.0)
            
            // 绘制文字标签
            for label in textLabels {
                drawTextLabel(label, in: size)
            }
            
            targetImage.unlockFocus()
            
            if let tiffData = targetImage.tiffRepresentation {
                try tiffData.write(to: fileURL)
                return fileURL
            }
            throw NSError(domain: "EasyDMG", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create TIFF"])
        }
        
        // 1. Check for custom background URL first
        if let customURL = schema.customBackgroundURL,
           let customImage = NSImage(contentsOf: customURL) {
            return try resizeAndSave(customImage)
        }
        
        // 2. Try to load from Data Set first
        if let dataAsset = NSDataAsset(name: name),
           let image = NSImage(data: dataAsset.data) {
            return try resizeAndSave(image)
        }
        
        // 3. Try to load from bundle by name
        if let image = NSImage(named: name) {
            return try resizeAndSave(image)
        }
        
        // 4. Fallback: Color rectangle
        let fallbackImage = NSImage(size: size)
        fallbackImage.lockFocus()
        NSColor.windowBackgroundColor.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        
        // 绘制文字标签
        for label in textLabels {
            drawTextLabel(label, in: size)
        }
        
        fallbackImage.unlockFocus()
        
        if let tiffData = fallbackImage.tiffRepresentation {
            try tiffData.write(to: fileURL)
        }
        return fileURL
    }
    
    // 绘制单个文字标签
    private func drawTextLabel(_ label: TextLabel, in size: CGSize) {
        // 创建字体
        let font: NSFont
        if label.fontName == "System" {
            font = NSFont.systemFont(ofSize: label.fontSize, weight: fontWeightToNSFontWeight(label.fontWeight))
        } else {
            font = NSFont(name: label.fontName, size: label.fontSize) ?? NSFont.systemFont(ofSize: label.fontSize)
        }
        
        // 创建属性
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(label.color)
        ]
        
        // 添加阴影
        if label.shadowEnabled {
            let shadow = NSShadow()
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
            shadow.shadowOffset = NSSize(width: 0, height: -1)
            shadow.shadowBlurRadius = 2
            attributes[.shadow] = shadow
        }
        
        let attributedString = NSAttributedString(string: label.text, attributes: attributes)
        let textSize = attributedString.size()
        
        // 计算绘制位置（position 是中心点，需要转换为左下角）
        // SwiftUI 坐标系 Y 轴向下，NSImage 坐标系 Y 轴向上
        let drawX = label.position.x - textSize.width / 2
        let drawY = size.height - label.position.y - textSize.height / 2
        
        attributedString.draw(at: NSPoint(x: drawX, y: drawY))
    }
    
    // 转换 SwiftUI Font.Weight 到 NSFont.Weight
    private func fontWeightToNSFontWeight(_ weight: Font.Weight) -> NSFont.Weight {
        switch weight {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
        }
    }
}


// MARK: - Preview

#Preview("Preview with About") {
    struct PreviewWrapper: View {
        @State private var schema = DMGLayoutSchema.standard
        @State private var textLabels: [TextLabel] = []
        
        var body: some View {
            let mockMeta = AppMetadata(
                name: "TestApp",
                icon: NSWorkspace.shared.icon(forFile: "/Applications/Safari.app"),
                version: "1.0.0",
                url: URL(fileURLWithPath: "/Applications/Safari.app")
            )
            
            PreviewWithAboutView(schema: $schema, textLabels: $textLabels, appMetadata: mockMeta)
        }
    }
    
    return PreviewWrapper()
        .frame(width: 700, height: 450)
}


// MARK: - Preview

#Preview("Initial State") {
    ContentView()
        .frame(width: 350, height: 350)
}

