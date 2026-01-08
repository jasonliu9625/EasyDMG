# TelemetryDeck 集成文档

## 概述

EasyDMG 已成功集成 TelemetryDeck 遥测服务，用于收集应用使用情况和性能数据。

## 配置信息

- **App ID**: `11BEA628-786C-425E-932B-6DE5A593C303`
- **Organization Namespace**: `com.icheese`
- **TelemetryDeck SDK版本**: 2.0.0+

## 集成的遥测事件

### 应用生命周期
- `app.launched` - 应用启动
- `app.entered_background` - 应用进入后台
- `app.became_active` - 应用进入前台

### 用户界面交互
- `ui.advanced_mode.enabled` - 切换到高级模式
- `app.selected` - 用户选择应用文件

### DMG构建过程
- `build.initiated` - 开始构建DMG
- `build.success` - 构建成功
- `build.failed` - 构建失败
- `build.file_exists_prompt` - 文件已存在提示
- `build.file_replaced` - 用户选择替换文件
- `build.cancelled_by_user` - 用户取消构建

### 设置相关
- `settings.background.builtin_selected` - 选择内置背景
- `settings.background.custom_selected` - 选择自定义背景
- `settings.background.custom_deleted` - 删除自定义背景
- `settings.background.add_custom_clicked` - 点击添加自定义背景
- `settings.background.custom_file_selected` - 选择自定义背景文件
- `settings.background.custom_saved` - 自定义背景保存成功
- `settings.background.design_online_clicked` - 点击在线设计背景
- `settings.output_directory.changed` - 更改输出目录
- `settings.output_directory.selected` - 输出目录选择成功
- `settings.version_in_filename.toggled` - 版本号文件名设置切换

### DMG创建详细过程
- `dmg.creation.started` - DMG创建开始
- `dmg.creation.completed` - DMG创建完成
- `dmg.creation.failed` - DMG创建失败
- `dmg.creation.script_error` - AppleScript执行错误

### 关于窗口
- `about.button_clicked` - 点击关于按钮
- `about.opened` - 关于窗口打开
- `about.closed` - 关于窗口关闭
- `about.github_clicked` - 点击GitHub链接
- `about.kofi_clicked` - 点击Ko-fi链接

## 实现细节

### 1. 依赖添加
项目已添加 TelemetryDeck Swift SDK 作为 Swift Package 依赖。

### 2. 初始化
在 `EasyDMGApp.swift` 的 `init()` 方法中初始化 TelemetryDeck：

```swift
let configuration = TelemetryDeck.Config(
    appID: "11BEA628-786C-425E-932B-6DE5A593C303"
)
TelemetryDeck.initialize(config: configuration)
```

### 3. 遥测管理器
创建了 `TelemetryManager.swift` 来统一管理所有遥测事件，提供类型安全的API。

### 4. 事件参数
大多数事件都包含相关的上下文参数，如：
- 应用名称
- 构建持续时间
- 错误信息
- 用户设置状态

## 隐私考虑

- 所有遥测数据都是匿名的
- 不收集个人身份信息
- 遵循 Apple 的隐私准则
- 用户可以通过系统设置禁用分析数据共享

## 数据用途

收集的遥测数据将用于：
- 了解功能使用情况
- 识别和修复错误
- 优化用户体验
- 指导产品开发方向

## 开发注意事项

1. 在添加新功能时，考虑添加相应的遥测事件
2. 使用 `TelemetryManager` 类的静态方法而不是直接调用 TelemetryDeck
3. 确保事件名称遵循现有的命名约定
4. 为重要事件添加有意义的参数