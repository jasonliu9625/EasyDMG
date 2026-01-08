import SwiftUI
import UniformTypeIdentifiers
import TelemetryDeck

struct SettingsView: View {
    @Binding var schema: DMGLayoutSchema
    let appVersion: String
    let isBuilding: Bool
    let buildProgress: Double
    let onBuild: () -> Void
    
    private let builtInBackgrounds = ["dmg-background", "dmg-background1", "dmg-background2"]
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // MARK: - Background Section
                    VStack(alignment: .leading, spacing: 12) {
                        HeaderView(title: "Background Image", icon: "photo.on.rectangle.angled")
                        
                        // Horizontal Collection for Backgrounds
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // 1. Built-in Backgrounds
                                ForEach(builtInBackgrounds, id: \.self) { name in
                                    BackgroundThumbnail(
                                        name: name,
                                        isSelected: schema.backgroundAssetName == name && schema.customBackgroundURL == nil,
                                        onSelect: {
                                            // 发送背景选择事件
                                            TelemetryDeck.signal("settings.background.builtin_selected", parameters: [
                                                "backgroundName": name
                                            ])
                                            
                                            withAnimation(.spring()) {
                                                schema.backgroundAssetName = name
                                                schema.customBackgroundURL = nil
                                            }
                                        },
                                        downsampler: self.downsample
                                    )
                                }
                                
                                // 2. Saved Custom Backgrounds
                                ForEach(schema.customBackgrounds, id: \.self) { url in
                                    CustomBackgroundThumbnail(
                                        url: url,
                                        isSelected: schema.customBackgroundURL == url,
                                        onSelect: {
                                            // 发送自定义背景选择事件
                                            TelemetryDeck.signal("settings.background.custom_selected")
                                            
                                            withAnimation(.spring()) {
                                                schema.customBackgroundURL = url
                                                schema.backgroundAssetName = ""
                                            }
                                        },
                                        onDelete: {
                                            // 发送自定义背景删除事件
                                            TelemetryDeck.signal("settings.background.custom_deleted")
                                            deleteCustomBackground(at: url)
                                        },
                                        downsampler: self.downsample
                                    )
                                }
                                
                                // 3. Add Custom Button (if < 3)
                                if schema.customBackgrounds.count < 3 {
                                    Button(action: {
                                        // 发送添加自定义背景事件
                                        TelemetryDeck.signal("settings.background.add_custom_clicked")
                                        selectCustomBackground()
                                    }) {
                                        VStack {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color.secondary.opacity(0.1))
                                                    .frame(width: 100, height: 62)
                                                
                                                Image(systemName: "plus")
                                                    .font(.title2)
                                                    .foregroundColor(.secondary)
                                            }
                                            Text("Add")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                        }
                        
                        // Design Online Link
                        Button(action: {
                            // 发送在线设计背景事件
                            TelemetryDeck.signal("settings.background.design_online_clicked")
                            openDesignWebsite()
                        }) {
                            HStack {
                                Image(systemName: "safari")
                                Text("Design Background Online")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption2)
                            }
                            .font(.subheadline)
                            .padding(10)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Divider().opacity(0.5)
                    
                    // MARK: - Export Section
                    VStack(alignment: .leading, spacing: 16) {
                        HeaderView(title: "Export Configuration", icon: "archivebox")
                        
                        // Output Directory
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Output Directory")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .padding(.leading, 2)
                            
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.secondary)
                                Text(schema.outputDirectory.path)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .font(.caption)
                                
                                Spacer()
                                
                                Button("Change") {
                                    // 发送输出目录更改事件
                                    TelemetryDeck.signal("settings.output_directory.changed")
                                    selectOutputDirectory()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            .padding(10)
                            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
                            .cornerRadius(8)
                        }
                        
                        // Version Info
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: Binding(
                                get: { schema.includeVersionInFilename },
                                set: { newValue in
                                    // 发送版本号设置事件
                                    TelemetryDeck.signal("settings.version_in_filename.toggled", parameters: [
                                        "enabled": newValue ? "true" : "false"
                                    ])
                                    schema.includeVersionInFilename = newValue
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Include Version in Filename")
                                        .font(.subheadline)
                                    Text("Current: \(appVersion.isEmpty ? "1.0" : appVersion)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .toggleStyle(.checkbox)
                        }
                        .padding(10)
                        .background(Color(nsColor: .windowBackgroundColor).opacity(0.3))
                        .cornerRadius(8)
                        
                        // MARK: - Icon Size
                        VStack(alignment: .leading, spacing: 8) {
                            HeaderView(title: "Icon Size", icon: "arrow.up.left.and.arrow.down.right")
                            
                            HStack(spacing: 12) {
                                Slider(value: $schema.iconSize, in: 64...256, step: 8)
                                
                                Text("\(Int(schema.iconSize)) px")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 50, alignment: .trailing)
                            }
                            .padding(10)
                            .background(Color(nsColor: .windowBackgroundColor).opacity(0.3))
                            .cornerRadius(8)
                        }
                        
                        // MARK: - Layout Debug (Coordinates)
                        VStack(alignment: .leading, spacing: 8) {
                            HeaderView(title: "Icon Coordinates", icon: "scope")
                            
                            HStack(spacing: 12) {
                                // App Icon Pos
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("App Icon")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("X: \(Int(schema.appIconX))  Y: \(Int(schema.appIconY))")
                                        .font(.system(.caption, design: .monospaced))
                                        .padding(6)
                                        .background(Color.accentColor.opacity(0.1))
                                        .cornerRadius(4)
                                }
                                
                                Spacer()
                                
                                // Apps Link Pos
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Applications")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("X: \(Int(schema.applicationsLinkX))  Y: \(Int(schema.applicationsLinkY))")
                                        .font(.system(.caption, design: .monospaced))
                                        .padding(6)
                                        .background(Color.accentColor.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                            .padding(10)
                            .background(Color(nsColor: .windowBackgroundColor).opacity(0.3))
                            .cornerRadius(8)
                        }
                        
                        
                    }
                    
                }
                .padding(20)
            }
            
            // MARK: - Footer/Action
            VStack(spacing: 0) {
                Divider()
                Button(action: onBuild) {
                    HStack(spacing: 8) {
                        if isBuilding {
                            ProgressView()
                                .controlSize(.small)
                            
                            Text("\(Int(buildProgress * 100))%")
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.bold)
                        }
                        Text(isBuilding ? "Building..." : "Create DMG")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .disabled(isBuilding)
                .padding(20)
            }
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
        }
    }
    
    // MARK: - Helpers
    
    private func selectOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Select"
        
        if panel.runModal() == .OK, let url = panel.url {
            schema.outputDirectory = url
            
            // 发送输出目录选择成功事件
            TelemetryDeck.signal("settings.output_directory.selected", parameters: [
                "isDesktop": url.path.contains("Desktop") ? "true" : "false"
            ])
        }
    }
    
    private func selectCustomBackground() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.png, .jpeg, .tiff]
        panel.prompt = "Upload"
        
        if panel.runModal() == .OK, let url = panel.url {
            // 发送自定义背景选择成功事件
            TelemetryDeck.signal("settings.background.custom_file_selected", parameters: [
                "fileExtension": url.pathExtension.lowercased()
            ])
            saveCustomBackground(from: url)
        }
    }
    
    private func saveCustomBackground(from sourceURL: URL) {
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let backgroundsDir = appSupport.appendingPathComponent("EasyDMG/CustomBackgrounds", isDirectory: true)
        
        try? fileManager.createDirectory(at: backgroundsDir, withIntermediateDirectories: true)
        
        let destinationURL = backgroundsDir.appendingPathComponent("\(UUID().uuidString).jpg")
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: sourceURL),
               let resizedData = self.resizeImageForStorage(data: data, maxPixelSize: 2560) {
                
                try? resizedData.write(to: destinationURL)
                
                DispatchQueue.main.async {
                    withAnimation(.spring()) {
                        schema.customBackgrounds.append(destinationURL)
                        schema.customBackgroundURL = destinationURL
                        schema.backgroundAssetName = ""
                    }
                    
                    // 发送自定义背景保存成功事件
                    TelemetryDeck.signal("settings.background.custom_saved")
                }
            }
        }
    }
    
    private func deleteCustomBackground(at url: URL) {
        withAnimation {
            if schema.customBackgroundURL == url {
                schema.customBackgroundURL = nil
                schema.backgroundAssetName = builtInBackgrounds.first ?? ""
            }
            schema.customBackgrounds.removeAll(where: { $0 == url })
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    private func resizeImageForStorage(data: Data, maxPixelSize: CGFloat) -> Data? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else { return nil }
        
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else { return nil }
        
        let rep = NSBitmapImageRep(cgImage: downsampledImage)
        return rep.representation(using: .jpeg, properties: [:])
    }
    
    private func openDesignWebsite() {
        if let url = URL(string: "https://dmg-background.easydmg.com/") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func downsample(data: Data, to pointSize: CGSize) -> NSImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else { return nil }
        
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * 2 // Retina factor
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else { return nil }
        return NSImage(cgImage: downsampledImage, size: pointSize)
    }
}



// MARK: - Reusable Components

struct HeaderView: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
        }
    }
}

struct CustomBackgroundThumbnail: View {
    let url: URL
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let downsampler: (Data, CGSize) -> NSImage?
    
    @State private var isHovering = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onSelect) {
                VStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 100, height: 62)
                        
                        if let data = try? Data(contentsOf: url),
                           let image = downsampler(data, CGSize(width: 200, height: 124)) {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 62)
                                .clipped()
                                .cornerRadius(10)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                    )
                    
                    Text("Custom")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .primary : .secondary)
                }
            }
            .buttonStyle(.plain)
            
            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .background(Color.white.clipShape(Circle()))
                }
                .buttonStyle(.plain)
                .padding(4)
                .transition(.opacity)
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

struct BackgroundThumbnail: View {
    let name: String
    let isSelected: Bool
    let onSelect: () -> Void
    let downsampler: (Data, CGSize) -> NSImage?
    
    var body: some View {
        Button(action: onSelect) {
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [.gray.opacity(0.2), .gray.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 100, height: 62)
                    
                    if let image = loadImage(name: name) {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 62)
                            .clipped()
                            .cornerRadius(10)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                )
                
                Text(name.replacingOccurrences(of: "dmg-background", with: "Style "))
                    .font(.caption2)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
    
    private func loadImage(name: String) -> NSImage? {
        if let dataAsset = NSDataAsset(name: name) {
            return downsampler(dataAsset.data, CGSize(width: 200, height: 124))
        }
        return NSImage(named: name)
    }
}

