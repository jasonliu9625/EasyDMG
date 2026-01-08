import SwiftUI
import UniformTypeIdentifiers

struct DragDropZone: View {
    @Binding var appMetadata: AppMetadata?
    @State private var isHovering = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(lineWidth: 3, dash: [10]))
                .foregroundColor(isHovering ? .accentColor : .secondary.opacity(0.5))
            
            VStack(spacing: 16) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 48))
                    .foregroundColor(isHovering ? .accentColor : .secondary)
                
                Text(isHovering ? "Drop App Here" : "Drag & Drop .app Here")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text("Supports macOS App Bundles")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.8))
            }
        }
        .padding(40)
        .background(Color(nsColor: .windowBackgroundColor))
        .contentShape(Rectangle())
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
                        self.appMetadata = meta
                    }
                }
            }
            return true
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
                    self.appMetadata = meta
                }
            }
        }
    }
}


// MARK: - Preview

#Preview("Default") {
    struct PreviewWrapper: View {
        @State private var appMetadata: AppMetadata?
        
        var body: some View {
            DragDropZone(appMetadata: $appMetadata)
        }
    }
    
    return PreviewWrapper()
        .frame(width: 350, height: 350)
}
