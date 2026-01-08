//
//  UpdaterController.swift
//  EasyDMG
//
//  Created by EasyDMG on 1/7/26.
//

import Foundation
import SwiftUI
import Sparkle
import Combine

/// A wrapper around Sparkle's SPUStandardUpdaterController to interface with SwiftUI
class UpdaterController: ObservableObject {
    private let updaterController: SPUStandardUpdaterController
    
    @Published var canCheckForUpdates = false
    
    init() {
        // Initializes the updater controller with default configuration
        // This expects SUFeedURL and SUPublicEDKey to be in Info.plist
        self.updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        
        // Observe availability to enable/disable UI
        self.updaterController.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
    
    /// Trigger a user-initiated update check
    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
    
    /// Accessor for automatic update checks preference
    var automaticallyChecksForUpdates: Bool {
        get {
            updaterController.updater.automaticallyChecksForUpdates
        }
        set {
            updaterController.updater.automaticallyChecksForUpdates = newValue
        }
    }
    
    /// Accessor for last update check date
    var lastUpdateCheckDate: Date? {
        updaterController.updater.lastUpdateCheckDate
    }
}
