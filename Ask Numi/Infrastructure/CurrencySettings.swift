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

    static func flag(for code: String) -> String {
        switch code {
        case "AED": return "🇦🇪"
        case "AMD": return "🇦🇲"
        case "AUD": return "🇦🇺"
        case "AZN": return "🇦🇿"
        case "BGN": return "🇧🇬"
        case "BRL": return "🇧🇷"
        case "BYN": return "🇧🇾"
        case "CAD": return "🇨🇦"
        case "CHF": return "🇨🇭"
        case "CNY": return "🇨🇳"
        case "CZK": return "🇨🇿"
        case "DKK": return "🇩🇰"
        case "EGP": return "🇪🇬"
        case "EUR": return "🇪🇺"
        case "GBP": return "🇬🇧"
        case "GEL": return "🇬🇪"
        case "HKD": return "🇭🇰"
        case "HUF": return "🇭🇺"
        case "ILS": return "🇮🇱"
        case "INR": return "🇮🇳"
        case "JPY": return "🇯🇵"
        case "KZT": return "🇰🇿"
        case "KRW": return "🇰🇷"
        case "MDL": return "🇲🇩"
        case "MXN": return "🇲🇽"
        case "NOK": return "🇳🇴"
        case "PLN": return "🇵🇱"
        case "RON": return "🇷🇴"
        case "RUB": return "🇷🇺"
        case "SAR": return "🇸🇦"
        case "SEK": return "🇸🇪"
        case "TRY": return "🇹🇷"
        case "TMT": return "🇹🇲"
        case "UAH": return "🇺🇦"
        case "USD": return "🇺🇸"
        case "UZS": return "🇺🇿"
        case "ZAR": return "🇿🇦"
        default: return "🌐"
        }
    }
}
