import Foundation
import TelemetryDeck

class DMGBuilder {
    enum BuildError: Error {
        case fileSystemError(String)
        case hdiutilError(String)
        case scriptError(String)
    }
    
    /// Orchestrates the full DMG creation process
    /// - Parameters:
    ///   - appMetadata: The source app info
    ///   - schema: The layout configuration
    ///   - outputFolder: Where to save the final DMG
    ///   - backgroundURL: The URL of the background image to use
    static func createDMG(
        for appMetadata: AppMetadata,
        schema: DMGLayoutSchema,
        outputURL: URL,
        backgroundURL: URL,
        progress: ((Double) -> Void)? = nil
    ) throws {
        // 发送DMG创建开始事件
        TelemetryDeck.signal("dmg.creation.started", parameters: [
            "appName": appMetadata.name,
            "backgroundType": backgroundURL.pathExtension
        ])
        
        let startTime = Date()
        let fileManager = FileManager.default
        let appName = appMetadata.name
        let volumeName = appName // Use app name as volume name
        
        // 1. Create Temporary 'Setup' Folder
        progress?(0.05)
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("EasyDMG_Build_\(UUID().uuidString)")
        let stagingFolder = tempDir.appendingPathComponent("Staging")
        
        do {
            try fileManager.createDirectory(at: stagingFolder, withIntermediateDirectories: true)
            
            // 2. Copy App Bundle
            progress?(0.1)
            let destAppURL = stagingFolder.appendingPathComponent("\(appName).app")
            try fileManager.copyItem(at: appMetadata.url, to: destAppURL)
            
            // 3. Create /Applications Symlink
            progress?(0.2)
            let linkURL = stagingFolder.appendingPathComponent("Applications")
            try fileManager.createSymbolicLink(at: linkURL, withDestinationURL: URL(fileURLWithPath: "/Applications"))
            
            // 4. Setup Background
            progress?(0.25)
            let bgFolder = stagingFolder.appendingPathComponent(".background")
            try fileManager.createDirectory(at: bgFolder, withIntermediateDirectories: true)
            
            // Use tiff extension (standard for DMG backgrounds)
            let bgExt = backgroundURL.pathExtension.isEmpty ? "tiff" : backgroundURL.pathExtension
            let bgDestURL = bgFolder.appendingPathComponent("\(schema.backgroundAssetName).\(bgExt)")
            try fileManager.copyItem(at: backgroundURL, to: bgDestURL)
            
            // 5. Create Writable DMG (UDRW)
            progress?(0.4)
            let tempDMG = tempDir.appendingPathComponent("temp.dmg")
            let createArgs = [
                "create",
                "-srcfolder", stagingFolder.path,
                "-volname", volumeName,
                "-fs", "HFS+",
                "-fsargs", "-c c=64,a=16,e=16",
                "-format", "UDRW",
                tempDMG.path
            ]
            try runHDIUtil(args: createArgs)
            
            // 6. Mount Writable DMG to apply styles
            progress?(0.5)
            let mountArgs = ["attach", tempDMG.path, "-readwrite", "-noverify", "-noautoopen"]
            try runHDIUtil(args: mountArgs)
            
            // Wait a moment for mount
            Thread.sleep(forTimeInterval: 1.0)
            
            // 7. Run AppleScript to style it
            progress?(0.65)
            let bgFilename = "\(schema.backgroundAssetName).\(bgExt)"
            let script = AppleScriptGenerator.generateInstallerScript(volumeName: volumeName, schema: schema, backgroundFilename: bgFilename)
            let (success, errorMsg) = AppleScriptGenerator.run(script)
            
            if !success {
                // Try to detach if script fails
                let _ = try? runHDIUtil(args: ["detach", "/Volumes/\(volumeName)"])
                
                // 发送脚本错误事件
                TelemetryDeck.signal("dmg.creation.script_error", parameters: [
                    "error": errorMsg ?? "Unknown script error"
                ])
                
                throw BuildError.scriptError(errorMsg ?? "Unknown")
            }
            
            // 8. Unmount
            progress?(0.8)
            let detachArgs = ["detach", "/Volumes/\(volumeName)", "-force"]
            try runHDIUtil(args: detachArgs)
            
            // 9. Convert to Final Compressed DMG (UDZO)
            progress?(0.9)
            let finalDMGURL = outputURL
            
            // Remove existing if any
            if fileManager.fileExists(atPath: finalDMGURL.path) {
                try fileManager.removeItem(at: finalDMGURL)
            }
            
            let convertArgs = [
                "convert", tempDMG.path,
                "-format", "UDZO",
                "-imagekey", "zlib-level=9",
                "-o", finalDMGURL.path
            ]
            try runHDIUtil(args: convertArgs)
            
            // Cleanup Temp
            progress?(1.0)
            try? fileManager.removeItem(at: tempDir)
            
            // 计算创建时间并发送成功事件
            let duration = Date().timeIntervalSince(startTime)
            TelemetryDeck.signal("dmg.creation.completed", parameters: [
                "appName": appMetadata.name,
                "duration": String(format: "%.2f", duration),
                "backgroundType": backgroundURL.pathExtension
            ])
            
        } catch {
            // Cleanup on error
            try? fileManager.removeItem(at: tempDir)
            
            // 发送错误事件
            let duration = Date().timeIntervalSince(startTime)
            TelemetryDeck.signal("dmg.creation.failed", parameters: [
                "appName": appMetadata.name,
                "error": error.localizedDescription,
                "duration": String(format: "%.2f", duration)
            ])
            
            throw error
        }
    }
    
    static func runHDIUtil(args: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = args
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            throw BuildError.hdiutilError("Exit Code: \(process.terminationStatus)\nOutput: \(output)")
        }
    }
}
