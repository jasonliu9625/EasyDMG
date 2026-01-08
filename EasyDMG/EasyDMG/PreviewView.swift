import SwiftUI

// MARK: - 文字标签模型

struct TextLabel: Identifiable, Equatable {
    let id = UUID()
    var text: String
    var position: CGPoint
    var fontSize: CGFloat = 16
    var fontName: String = "System"
    var fontWeight: Font.Weight = .medium
    var color: Color = .white
    var shadowEnabled: Bool = true
    
    static func == (lhs: TextLabel, rhs: TextLabel) -> Bool {
        lhs.id == rhs.id &&
        lhs.text == rhs.text &&
        lhs.position == rhs.position &&
        lhs.fontSize == rhs.fontSize &&
        lhs.fontName == rhs.fontName &&
        lhs.color == rhs.color &&
        lhs.shadowEnabled == rhs.shadowEnabled
    }
}

// MARK: - 可拖拽图标组件（使用 offset 而非 position）

struct DraggableIcon: View {
    let icon: NSImage
    let label: String
    let iconSize: CGFloat
    @Binding var iconPosition: CGPoint  // 图标中心点相对于背景图左上角的坐标
    
    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        VStack(spacing: 4) {
            Image(nsImage: icon)
                .resizable()
                .frame(width: iconSize, height: iconSize)
                .shadow(color: isDragging ? .blue.opacity(0.5) : .clear, radius: 8)
            
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.black)
                .shadow(color: .white, radius: 1)
        }
        .offset(x: dragOffset.width, y: dragOffset.height)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    dragOffset = value.translation
                }
                .onEnded { value in
                    // 更新最终位置，步进为5，且取整
                    let newX = iconPosition.x + value.translation.width
                    let newY = iconPosition.y + value.translation.height
                    iconPosition = CGPoint(
                        x: max(0, round(newX / 5) * 5),
                        y: max(0, round(newY / 5) * 5)
                    )
                    // 立即重置 dragOffset 和 isDragging，避免弹跳动画
                    dragOffset = .zero
                    isDragging = false
                }
        )
    }
}

// MARK: - 可拖拽文字组件

struct DraggableTextLabel: View {
    @Binding var label: TextLabel
    let onDelete: () -> Void
    
    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero
    @State private var isHovering = false
    @State private var showSettings = false
    
    private var textFont: Font {
        if label.fontName == "System" {
            return .system(size: label.fontSize, weight: label.fontWeight)
        } else {
            return .custom(label.fontName, size: label.fontSize)
        }
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Text(label.text)
                .font(textFont)
                .foregroundColor(label.color)
                .shadow(color: label.shadowEnabled ? .black.opacity(0.5) : .clear, radius: label.shadowEnabled ? 2 : 0)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isHovering || isDragging ? Color.blue : Color.clear, lineWidth: 1)
                )
                .onTapGesture(count: 2) {
                    showSettings = true
                }
            
            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .offset(x: 8, y: -8)
            }
        }
        .offset(x: dragOffset.width, y: dragOffset.height)
        .onHover { hovering in
            isHovering = hovering
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    dragOffset = value.translation
                }
                .onEnded { value in
                    let newX = label.position.x + value.translation.width
                    let newY = label.position.y + value.translation.height
                    label.position = CGPoint(
                        x: max(0, round(newX / 5) * 5),
                        y: max(0, round(newY / 5) * 5)
                    )
                    dragOffset = .zero
                    isDragging = false
                }
        )
        .popover(isPresented: $showSettings, arrowEdge: .bottom) {
            TextSettingsPopover(label: $label)
        }
    }
}

// MARK: - 文字设置弹出框

struct TextSettingsPopover: View {
    @Binding var label: TextLabel
    
    private let availableFonts = [
        "System",
        "Helvetica Neue",
        "Arial",
        "Avenir Next",
        "SF Pro",
        "Menlo",
        "Monaco",
        "Georgia",
        "Times New Roman"
    ]
    
    private let presetColors: [Color] = [
        .white, .black, .gray,
        .red, .orange, .yellow,
        .green, .blue, .purple
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 文字内容
            VStack(alignment: .leading, spacing: 6) {
                Text("文字内容")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("输入文字", text: $label.text)
                    .textFieldStyle(.roundedBorder)
            }
            
            Divider()
            
            // 字体选择
            VStack(alignment: .leading, spacing: 6) {
                Text("字体")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("", selection: $label.fontName) {
                    ForEach(availableFonts, id: \.self) { font in
                        Text(font).tag(font)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
            }
            
            // 字号
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("字号")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(label.fontSize)) pt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $label.fontSize, in: 10...72, step: 1)
            }
            
            Divider()
            
            // 颜色选择
            VStack(alignment: .leading, spacing: 8) {
                Text("颜色")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(28), spacing: 8), count: 5), spacing: 8) {
                    ForEach(presetColors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.accentColor, lineWidth: 2)
                                    .opacity(label.color == color ? 1 : 0)
                            )
                            .onTapGesture {
                                label.color = color
                            }
                    }
                    
                    ColorPicker("", selection: $label.color)
                        .labelsHidden()
                        .frame(width: 24, height: 24)
                }
            }
            
            Divider()
            
            // 阴影开关
            Toggle("文字阴影", isOn: $label.shadowEnabled)
                .font(.subheadline)
        }
        .padding()
        .frame(width: 220)
    }
}

// MARK: - DMG 预览视图

struct DMGPreviewView: View {
    @Binding var schema: DMGLayoutSchema
    let appMetadata: AppMetadata?
    var gridSpacing: CGFloat = 0
    @Binding var textLabels: [TextLabel]
    
    var backgroundImage: NSImage? {
        // 优先使用自定义背景
        if let customURL = schema.customBackgroundURL,
           let customImage = NSImage(contentsOf: customURL) {
            return customImage
        }
        
        // 从 Bundle 的 Data Set 中加载图像
        if let dataAsset = NSDataAsset(name: schema.backgroundAssetName),
           let image = NSImage(data: dataAsset.data) {
            return image
        }
        
        // 回退到传统的 NSImage(named:) 方法
        return NSImage(named: schema.backgroundAssetName)
    }
    
    var body: some View {
        GeometryReader { geo in
            // 背景图容器 - 作为坐标参照物
            ZStack(alignment: .topLeading) {
                // 1. 背景图
                Group {
                    if let bg = backgroundImage {
                        Image(nsImage: bg)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        
                        Text("Background: \(schema.backgroundAssetName)")
                            .foregroundColor(.secondary.opacity(0.3))
                            .padding()
                    }
                }
                .frame(width: schema.windowSize.width, height: schema.windowSize.height)
                
                // 2. 图标层 - 使用 overlay 确保与背景图完全对齐
                // 图标位置是相对于这个容器左上角的坐标
                
                // App Icon
                if let meta = appMetadata {
                    DraggableIcon(
                        icon: meta.icon,
                        label: meta.name,
                        iconSize: schema.iconSize,
                        iconPosition: $schema.appIconPosition
                    )
                    .position(x: schema.appIconPosition.x, y: schema.appIconPosition.y)
                }
                
                // Applications Icon
                DraggableIcon(
                    icon: NSWorkspace.shared.icon(forFile: "/Applications"),
                    label: "Applications",
                    iconSize: schema.iconSize,
                    iconPosition: $schema.applicationsLinkPosition
                )
                .position(x: schema.applicationsLinkPosition.x, y: schema.applicationsLinkPosition.y)
                
                // 文字标签
                ForEach($textLabels) { $label in
                    DraggableTextLabel(label: $label) {
                        textLabels.removeAll { $0.id == label.id }
                    }
                    .position(x: label.position.x, y: label.position.y)
                }
                
                // 网格辅助线
                if gridSpacing > 0 {
                    GridOverlay(size: schema.windowSize, gridSpacing: gridSpacing)
                }
            }
            .frame(width: schema.windowSize.width, height: schema.windowSize.height)
            .clipped()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            //.shadow(radius: 5)
            // 居中显示预览
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.3))
        .frame(minWidth: schema.windowSize.width, minHeight: schema.windowSize.height)
    }
}

// MARK: - 网格辅助线

struct GridOverlay: View {
    let size: CGSize
    let gridSpacing: CGFloat
    
    var body: some View {
        Canvas { context, canvasSize in
            let columns = Int(size.width / gridSpacing)
            let rows = Int(size.height / gridSpacing)
            
            // 垂直线
            for i in 0...columns {
                let x = CGFloat(i) * gridSpacing
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(.gray.opacity(0.3)), lineWidth: 0.5)
            }
            
            // 水平线
            for i in 0...rows {
                let y = CGFloat(i) * gridSpacing
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.gray.opacity(0.3)), lineWidth: 0.5)
            }
            
            // 中心线（更明显）
            let centerX = size.width / 2
            let centerY = size.height / 2
            
            var centerVPath = Path()
            centerVPath.move(to: CGPoint(x: centerX, y: 0))
            centerVPath.addLine(to: CGPoint(x: centerX, y: size.height))
            context.stroke(centerVPath, with: .color(.blue.opacity(0.5)), lineWidth: 1)
            
            var centerHPath = Path()
            centerHPath.move(to: CGPoint(x: 0, y: centerY))
            centerHPath.addLine(to: CGPoint(x: size.width, y: centerY))
            context.stroke(centerHPath, with: .color(.blue.opacity(0.5)), lineWidth: 1)
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }
}


// MARK: - Preview

#Preview("DMG Preview") {
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
            
            DMGPreviewView(schema: $schema, appMetadata: mockMeta, gridSpacing: 20, textLabels: $textLabels)
                .padding()
        }
    }
    
    return PreviewWrapper()
        .frame(width: 700, height: 450)
}

#Preview("Draggable Icon") {
    struct PreviewWrapper: View {
        @State private var position = CGPoint(x: 100, y: 100)
        
        var body: some View {
            ZStack {
                Color.gray.opacity(0.2)
                
                DraggableIcon(
                    icon: NSWorkspace.shared.icon(forFile: "/Applications"),
                    label: "Applications",
                    iconSize: 128,
                    iconPosition: $position
                )
                .position(position)
            }
        }
    }
    
    return PreviewWrapper()
        .frame(width: 300, height: 300)
}

struct PreviewToolbar: View {
    @Binding var gridSpacing: CGFloat
    @Binding var schema: DMGLayoutSchema
    @Binding var textLabels: [TextLabel]
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"
    
    @State private var showGridPopover = false
    @State private var showAddTextPopover = false
    @State private var newTextInput = ""
    
    private var currentAppearanceIcon: String {
        switch appearanceMode {
        case "light": return "sun.max.fill"
        case "dark": return "moon.fill"
        default: return "circle.lefthalf.filled"
        }
    }
    
    private var currentAppearanceLabel: String {
        switch appearanceMode {
        case "light": return "浅色"
        case "dark": return "深色"
        default: return "跟随系统"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 1. 网格显示
            ToolbarButton(icon: "square.grid.3x3", label: "网格", isActive: gridSpacing > 0) {
                showGridPopover.toggle()
            }
            .popover(isPresented: $showGridPopover, arrowEdge: .bottom) {
                GridSettingsPopover(gridSpacing: $gridSpacing)
            }
            
            // 2. 添加文字
            ToolbarButton(icon: "text.badge.plus", label: "文字", isActive: showAddTextPopover) {
                showAddTextPopover.toggle()
            }
            .popover(isPresented: $showAddTextPopover, arrowEdge: .bottom) {
                AddTextPopover(
                    textInput: $newTextInput,
                    onAdd: { text in
                        let newLabel = TextLabel(
                            text: text,
                            position: CGPoint(x: schema.windowWidth / 2, y: schema.windowHeight - 50)
                        )
                        textLabels.append(newLabel)
                        newTextInput = ""
                        showAddTextPopover = false
                    },
                    onCancel: {
                        newTextInput = ""
                        showAddTextPopover = false
                    }
                )
            }
            
            // 3. 重置位置
            ToolbarButton(icon: "arrow.counterclockwise", label: "重置") {
                resetIconPositions()
            }
            
            // 4. 外观模式切换
            Menu {
                Button {
                    setAppearance("system")
                } label: {
                    Label("跟随系统", systemImage: "circle.lefthalf.filled")
                }
                
                Button {
                    setAppearance("light")
                } label: {
                    Label("浅色模式", systemImage: "sun.max.fill")
                }
                
                Button {
                    setAppearance("dark")
                } label: {
                    Label("深色模式", systemImage: "moon.fill")
                }
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: currentAppearanceIcon)
                        .font(.system(size: 16, weight: .regular))
                        .frame(height: 20)
                }
                .foregroundColor(.secondary)
                .frame(width: 30, height: 24)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .help(currentAppearanceLabel)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        )
    }
    
    private func resetIconPositions() {
        let defaultSchema = DMGLayoutSchema.standard
        schema.appIconX = defaultSchema.appIconX
        schema.appIconY = defaultSchema.appIconY
        schema.applicationsLinkX = defaultSchema.applicationsLinkX
        schema.applicationsLinkY = defaultSchema.applicationsLinkY
    }
    
    private func setAppearance(_ mode: String) {
        appearanceMode = mode
        switch mode {
        case "light":
            NSApp.appearance = NSAppearance(named: .aqua)
        case "dark":
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            NSApp.appearance = nil
        }
    }
}

// MARK: - 网格设置弹出框

struct GridSettingsPopover: View {
    @Binding var gridSpacing: CGFloat
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.grid.3x3")
                .foregroundColor(.secondary)
            
            Slider(value: $gridSpacing, in: 0...100, step: 5)
                .frame(width: 120)
            
            Text("\(Int(gridSpacing))")
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - 添加文字弹出框

struct AddTextPopover: View {
    @Binding var textInput: String
    let onAdd: (String) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("添加文字")
                .font(.headline)
            
            TextField("输入文字内容", text: $textInput)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
            
            HStack {
                Button("取消") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("添加") {
                    if !textInput.isEmpty {
                        onAdd(textInput)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(textInput.isEmpty)
            }
        }
        .padding()
    }
}

struct ToolbarButton: View {
    let icon: String
    let label: String
    var isActive: Bool = false
    var action: () -> Void = {}
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .regular))
                    .frame(height: 20)
            }
            .foregroundColor(isActive ? .accentColor : (isHovering ? .primary : .secondary))
            .frame(width: 30, height: 24)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .help(label)
    }
}

#Preview("Toolbar") {
    struct PreviewWrapper: View {
        @State private var gridSpacing: CGFloat = 0
        @State private var schema = DMGLayoutSchema.standard
        @State private var textLabels: [TextLabel] = []
        
        var body: some View {
            ZStack {
                Color.gray
                PreviewToolbar(gridSpacing: $gridSpacing, schema: $schema, textLabels: $textLabels)
            }
        }
    }
    
    return PreviewWrapper()
        .frame(width: 400, height: 100)
}
