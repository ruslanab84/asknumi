//
//  CurrencySettings.swift
//  Ask Numi
//

import Foundation

enum CurrencySettings {
    static let storageKey = "app.selected.currency"
    static let defaultCode = "AZN"

    static var selectedCode: String {
        let code = UserDefaults.standard.string(forKey: storageKey) ?? defaultCode
        return Locale.commonISOCurrencyCodes.contains(code) ? code : defaultCode
    }

    static var supportedCodes: [String] {
        Locale.commonISOCurrencyCodes.sorted {
            displayName(for: $0).localizedStandardCompare(displayName(for: $1)) == .orderedAscending
        }
    }

    static func displayName(for code: String) -> String {
        let locale = Locale(identifier: LocalizationManager.shared.currentLanguage)
        return locale.localizedString(forCurrencyCode: code) ?? code
    }
}
