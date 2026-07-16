//
//  Ask_NumiApp.swift
//  Ask Numi
//
//  Created by Ruslan Abdulov on 12.07.26.
//

import SwiftUI
import UIKit

@main
struct Ask_NumiApp: App {
    private let container = AppContainer()
    @StateObject private var localization = LocalizationManager.shared
    @AppStorage(AppearanceSettings.darkModeStorageKey) private var isDarkModeEnabled = false
    @AppStorage(AppearanceSettings.accentColorStorageKey) private var accentColorID = AppearanceSettings.defaultAccentColorID

    init() {
        UIScrollView.appearance().bounces = false
        UIScrollView.appearance().alwaysBounceHorizontal = false
    }

    var body: some Scene {
        WindowGroup {
            ContentView(container: container)
                .environmentObject(localization)
                .id(localization.currentLanguage)
                .preferredColorScheme(isDarkModeEnabled ? .dark : .light)
                .tint(CategoryColor(rawValue: accentColorID)?.displayColor ?? .indigo)
        }
    }
}

enum AppearanceSettings {
    static let darkModeStorageKey = "app.appearance.darkMode"
    static let accentColorStorageKey = "app.appearance.accentColor"
    static let defaultAccentColorID = CategoryColor.blue.rawValue
}
