import Foundation
import SwiftUI
import AppKit

/// The Single Source of Truth for DMG Layout.
/// Refactored to use Double for storage to play nicely with SwiftUI TextFields.
struct DMGLayoutSchema: Equatable {
    // Storage (Double for easy SwiftUI binding)
    var windowWidth: Double = 660
    var windowHeight: Double = 400
    
    var iconSize: Double = 128
    
    // 图标中心点坐标（相对于窗口/背景图左上角）
    var appIconX: Double = 165
    var appIconY: Double = 215
    
    var applicationsLinkX: Double = 510
    var applicationsLinkY: Double = 215
    
    var backgroundAssetName: String = "dmg-background"
    var customBackgroundURL: URL? = nil
    var customBackgrounds: [URL] = []
    var includeVersionInFilename: Bool = true
    var outputDirectory: URL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
    
    // Computed Helpers for consumers (Preview, Builder, Script)
    var windowSize: CGSize {
        get { CGSize(width: windowWidth, height: windowHeight) }
        set {
            windowWidth = newValue.width
            windowHeight = newValue.height
        }
    }
    
    var appIconPosition: CGPoint {
        get { CGPoint(x: appIconX, y: appIconY) }
        set {
            appIconX = newValue.x
            appIconY = newValue.y
        }
    }
    
    var applicationsLinkPosition: CGPoint {
        get { CGPoint(x: applicationsLinkX, y: applicationsLinkY) }
        set {
            applicationsLinkX = newValue.x
            applicationsLinkY = newValue.y
        }
    }
    
    /// Standard default configuration
    static let standard = DMGLayoutSchema()
}

/// Metadata parsed from the dropped .app bundle
struct AppMetadata: Equatable, Identifiable {
    let id = UUID()
    let name: String
    let icon: NSImage
    let version: String
    let url: URL
    
    // Helper to load from a URL
    static func from(url: URL) -> AppMetadata? {
        let fileManager = FileManager.default
        guard url.pathExtension == "app" else { return nil }
        
        let bundleParams = Bundle(url: url)
        
        // 1. Name
        let name = bundleParams?.infoDictionary?["CFBundleDisplayName"] as? String
            ?? bundleParams?.infoDictionary?["CFBundleName"] as? String
            ?? url.deletingPathExtension().lastPathComponent
        
        // 2. Version
        let version = bundleParams?.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        // 3. Icon
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        
        return AppMetadata(name: name, icon: icon, version: version, url: url)
    }
}
