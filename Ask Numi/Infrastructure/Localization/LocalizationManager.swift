//
//  LocalizationManager.swift
//  Ask Numi
//

import Foundation
import Combine

@MainActor
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    static let supportedLanguages = ["ru", "en"]

    private let storageKey = "app.selected.language"

    @Published private(set) var currentLanguage: String

    private init() {
        let stored = UserDefaults.standard.string(forKey: storageKey)
        let system = Locale.current.language.languageCode?.identifier
        // Clamp to shipped languages — a system-language fallback to a missing
        // .lproj would trip the missing-key assertion on every lookup.
        let candidate = stored ?? system ?? "ru"
        currentLanguage = Self.supportedLanguages.contains(candidate) ? candidate : "ru"
        Bundle.setLanguage(currentLanguage)
    }

    func setLanguage(_ code: String) {
        guard currentLanguage != code, Self.supportedLanguages.contains(code) else { return }
        UserDefaults.standard.set(code, forKey: storageKey)
        currentLanguage = code
        Bundle.setLanguage(code)
    }

    func localizedString(for key: String) -> String {
        let value = Bundle.localized.localizedString(forKey: key, value: "__MISSING__", table: "Localizable")
        if value == "__MISSING__" {
            #if DEBUG
            assertionFailure("⚠️ Missing localization key: \(key) for language: \(currentLanguage)")
            #endif
            return Bundle.main.localizedString(forKey: key, value: key, table: "Localizable")
        }
        return value
    }
}
