import Foundation

struct AppleScriptGenerator {
    
    /// Generates the AppleScript required to style the DMG folder.
    /// 坐标系统说明：
    /// - schema 中存储的坐标是图标中心点相对于窗口内容区域左上角的位置
    /// - Finder 的 `set position` 也是设置图标中心点的位置
    /// - SwiftUI 的 `.position()` 也是设置视图中心点的位置
    /// - 三者使用相同的坐标系统，无需转换
    ///
    /// 窗口大小说明：
    /// - Finder 的 bounds 是窗口外框坐标 {左, 上, 右, 下}
    /// - 内容区域高度 = bounds高度，但 Finder 可能会自动调整
    /// - 使用 icon view options 的 arrangement 设置为 not arranged 防止自动排列
    static func generateInstallerScript(volumeName: String, schema: DMGLayoutSchema, backgroundFilename: String) -> String {
        let winW = Int(schema.windowSize.width)
        let winH = Int(schema.windowSize.height)
        let iconSize = Int(schema.iconSize)
        
        // Finder 窗口标题栏高度补偿
        // Finder 的 bounds 属性包含整个窗口框架（标题栏），而我们需要 ensure 内容区域高度为 winH
        // 用户反馈 28px 补偿后高度约为 370px (目标 400)，说明总 Chrome 高度约为 58-60px
        let titleBarHeight = 60
        let totalH = winH + titleBarHeight
        
        // 图标中心点坐标 - 直接使用，无需转换
        let appX = Int(schema.appIconPosition.x)
        // Y轴需要往下移一点，因为原点在标题栏上方，或者 Finder 内容区域起始点不同
        // 但根据之前的注释（Schema存储的是相对于内容区域左上角），如果 bounds 变大了，内容区域相对位置应该不变
        let appY = Int(schema.appIconPosition.y)
        
        let linkX = Int(schema.applicationsLinkPosition.x)
        let linkY = Int(schema.applicationsLinkPosition.y)
        
        return """
        tell application "Finder"
            tell disk "\(volumeName)"
                open
                
                -- 1. 设置窗口视图选项
                set current view of container window to icon view
                set toolbar visible of container window to false
                set statusbar visible of container window to false
                
                -- 增加延迟确保视图切换完成
                delay 0.5
                
                -- 2. 设置图标视图选项（在设置窗口大小之前）
                set opts to the icon view options of container window
                set arrangement of opts to not arranged
                set icon size of opts to \(iconSize)
                set text size of opts to 12
                set label position of opts to bottom
                
                -- 3. 设置背景图（在设置窗口大小之前，让 Finder 知道背景尺寸）
                set background picture of opts to file ".background:\(backgroundFilename)"
                
                -- 4. 设置窗口大小 {左, 上, 右, 下}
                -- bounds 包含窗口标题栏，所以高度需要加上标题栏高度
                set the bounds of container window to {400, 100, \(400 + winW), \(100 + totalH)}
                
                -- 5. 设置图标位置（中心点坐标）
                set position of item "\(volumeName).app" to {\(appX), \(appY)}
                set position of item "Applications" to {\(linkX), \(linkY)}
                
                -- 6. 将隐藏文件夹移到窗口下方（可视区域外）
                try
                    set position of item ".background" to {\(winW / 2 - 50), \(winH + 200)}
                end try
                try
                    set position of item ".fseventsd" to {\(winW / 2 + 50), \(winH + 200)}
                end try
                
                -- 7. 关闭并重新打开以确保设置生效
                close
                open
                
                -- 8. 再次设置窗口大小（确保尺寸正确，防止 Finder 自动调整）
                set the bounds of container window to {400, 100, \(400 + winW), \(100 + totalH)}
                
                update without registering applications
                delay 1
                close
            end tell
        end tell
        """
    }
    
    /// Runs the given AppleScript source.
    static func run(_ source: String) -> (success: Bool, error: String?) {
        var errorDict: NSDictionary?
        if let scriptObject = NSAppleScript(source: source) {
            let _ = scriptObject.executeAndReturnError(&errorDict)
            if let error = errorDict {
                let msg = error[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript Error"
                print("AppleScript Error: \(msg)")
                return (false, msg)
            }
            return (true, nil)
        }
        return (false, "Failed to initialize NSAppleScript")
    }
}
