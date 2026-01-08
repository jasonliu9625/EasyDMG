//
//  TelemetryManager.swift
//  EasyDMG
//
//  Created by Kiro on 1/7/26.
//

import Foundation
import TelemetryDeck

/// 遥测管理器，用于统一管理应用的遥测事件
class TelemetryManager {
    
    // MARK: - 应用生命周期事件
    
    /// 应用启动
    static func appLaunched() {
        TelemetryDeck.signal("app.launched")
    }
    
    /// 应用进入后台
    static func appDidEnterBackground() {
        TelemetryDeck.signal("app.entered_background")
    }
    
    /// 应用进入前台
    static func appDidBecomeActive() {
        TelemetryDeck.signal("app.became_active")
    }
    
    // MARK: - 用户界面事件
    
    /// 切换到高级模式
    static func advancedModeEnabled() {
        TelemetryDeck.signal("ui.advanced_mode.enabled")
    }
    
    /// 应用被选择
    static func appSelected(name: String, version: String) {
        TelemetryDeck.signal("app.selected", parameters: [
            "appName": name,
            "appVersion": version,
            "hasVersion": !version.isEmpty ? "true" : "false"
        ])
    }
    
    // MARK: - DMG构建事件
    
    /// DMG构建开始
    static func dmgBuildStarted(appName: String, includeVersion: Bool, hasCustomBackground: Bool) {
        TelemetryDeck.signal("build.initiated", parameters: [
            "appName": appName,
            "includeVersion": includeVersion ? "true" : "false",
            "customBackground": hasCustomBackground ? "true" : "false"
        ])
    }
    
    /// DMG构建成功
    static func dmgBuildSucceeded(appName: String, duration: TimeInterval) {
        TelemetryDeck.signal("build.success", parameters: [
            "appName": appName,
            "duration": String(format: "%.2f", duration)
        ])
    }
    
    /// DMG构建失败
    static func dmgBuildFailed(appName: String, error: String, duration: TimeInterval) {
        TelemetryDeck.signal("build.failed", parameters: [
            "appName": appName,
            "error": error,
            "duration": String(format: "%.2f", duration)
        ])
    }
    
    /// 文件已存在提示
    static func fileExistsPrompt() {
        TelemetryDeck.signal("build.file_exists_prompt")
    }
    
    /// 用户选择替换文件
    static func fileReplaced() {
        TelemetryDeck.signal("build.file_replaced")
    }
    
    /// 用户取消构建
    static func buildCancelled() {
        TelemetryDeck.signal("build.cancelled_by_user")
    }
    
    // MARK: - 设置相关事件
    
    /// 选择内置背景
    static func builtinBackgroundSelected(name: String) {
        TelemetryDeck.signal("settings.background.builtin_selected", parameters: [
            "backgroundName": name
        ])
    }
    
    /// 选择自定义背景
    static func customBackgroundSelected() {
        TelemetryDeck.signal("settings.background.custom_selected")
    }
    
    /// 删除自定义背景
    static func customBackgroundDeleted() {
        TelemetryDeck.signal("settings.background.custom_deleted")
    }
    
    /// 点击添加自定义背景
    static func addCustomBackgroundClicked() {
        TelemetryDeck.signal("settings.background.add_custom_clicked")
    }
    
    /// 自定义背景文件选择
    static func customBackgroundFileSelected(extension: String) {
        TelemetryDeck.signal("settings.background.custom_file_selected", parameters: [
            "fileExtension": `extension`.lowercased()
        ])
    }
    
    /// 自定义背景保存成功
    static func customBackgroundSaved() {
        TelemetryDeck.signal("settings.background.custom_saved")
    }
    
    /// 点击在线设计背景
    static func designOnlineClicked() {
        TelemetryDeck.signal("settings.background.design_online_clicked")
    }
    
    /// 更改输出目录
    static func outputDirectoryChanged() {
        TelemetryDeck.signal("settings.output_directory.changed")
    }
    
    /// 输出目录选择成功
    static func outputDirectorySelected(isDesktop: Bool) {
        TelemetryDeck.signal("settings.output_directory.selected", parameters: [
            "isDesktop": isDesktop ? "true" : "false"
        ])
    }
    
    /// 版本号文件名设置切换
    static func versionInFilenameToggled(enabled: Bool) {
        TelemetryDeck.signal("settings.version_in_filename.toggled", parameters: [
            "enabled": enabled ? "true" : "false"
        ])
    }
    
    // MARK: - DMG创建过程事件
    
    /// DMG创建开始
    static func dmgCreationStarted(appName: String, backgroundType: String) {
        TelemetryDeck.signal("dmg.creation.started", parameters: [
            "appName": appName,
            "backgroundType": backgroundType
        ])
    }
    
    /// DMG创建完成
    static func dmgCreationCompleted(appName: String, duration: TimeInterval, backgroundType: String) {
        TelemetryDeck.signal("dmg.creation.completed", parameters: [
            "appName": appName,
            "duration": String(format: "%.2f", duration),
            "backgroundType": backgroundType
        ])
    }
    
    /// DMG创建失败
    static func dmgCreationFailed(appName: String, error: String, duration: TimeInterval) {
        TelemetryDeck.signal("dmg.creation.failed", parameters: [
            "appName": appName,
            "error": error,
            "duration": String(format: "%.2f", duration)
        ])
    }
    
    /// AppleScript错误
    static func scriptError(error: String) {
        TelemetryDeck.signal("dmg.creation.script_error", parameters: [
            "error": error
        ])
    }
    
    // MARK: - 关于窗口事件
    
    /// 点击关于按钮
    static func aboutButtonClicked() {
        TelemetryDeck.signal("about.button_clicked")
    }
    
    /// 关于窗口打开
    static func aboutOpened() {
        TelemetryDeck.signal("about.opened")
    }
    
    /// 关于窗口关闭
    static func aboutClosed() {
        TelemetryDeck.signal("about.closed")
    }
    
    /// 点击GitHub链接
    static func githubClicked() {
        TelemetryDeck.signal("about.github_clicked")
    }
    
    /// 点击Ko-fi链接
    static func kofiClicked() {
        TelemetryDeck.signal("about.kofi_clicked")
    }
}