//
//  EasyDMGApp.swift
//  EasyDMG
//
//  Created by sillyaboy on 12/30/25.
//

import SwiftUI
import SwiftData
import TelemetryDeck

@main
struct EasyDMGApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // 初始化 TelemetryDeck
        let configuration = TelemetryDeck.Config(
            appID: "11BEA628-786C-425E-932B-6DE5A593C303"
        )
        TelemetryDeck.initialize(config: configuration)
        
        // 发送应用启动事件
        TelemetryDeck.signal("app.launched")
    }

    @StateObject private var updaterController = UpdaterController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(updaterController)
        }
        .modelContainer(sharedModelContainer)
        .defaultSize(width: 300, height: 350)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController)
            }
        }
    }
}

// Separate view for menu item to observe object
struct CheckForUpdatesView: View {
    @ObservedObject var updater: UpdaterController
    
    var body: some View {
        Button("Check for Updates...") {
            updater.checkForUpdates()
        }
        .disabled(!updater.canCheckForUpdates)
    }
}
