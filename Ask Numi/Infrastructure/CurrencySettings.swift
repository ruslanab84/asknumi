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
        return supportedCodes.contains(code) ? code : defaultCode
    }

    static let supportedCodes = flags.keys.sorted()

    static func flag(for code: String) -> String {
        flags[code] ?? "🌐"
    }

    static func symbol(for code: String) -> String {
        symbols[code] ?? code
    }

    private static let symbols = Dictionary(uniqueKeysWithValues: supportedCodes.map { code in
        let symbol = Locale.availableIdentifiers.lazy
            .map(Locale.init(identifier:))
            .filter { $0.currency?.identifier == code }
            .compactMap { locale in
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.locale = locale
                formatter.currencyCode = code
                return formatter.currencySymbol
            }
            .min { $0.count < $1.count } ?? code
        return (code, symbol)
    })

    private static let flags: [String: String] = [
        "AED": "🇦🇪", "AFN": "🇦🇫", "ALL": "🇦🇱", "AMD": "🇦🇲",
        "ARS": "🇦🇷", "AUD": "🇦🇺", "AWG": "🇦🇼", "AZN": "🇦🇿",
        "BAM": "🇧🇦", "BBD": "🇧🇧", "BDT": "🇧🇩", "BGN": "🇧🇬",
        "BHD": "🇧🇭", "BMD": "🇧🇲", "BOB": "🇧🇴", "BRL": "🇧🇷",
        "BZD": "🇧🇿", "CAD": "🇨🇦", "CHF": "🇨🇭", "CLP": "🇨🇱",
        "CNY": "🇨🇳", "COP": "🇨🇴", "CRC": "🇨🇷", "CZK": "🇨🇿",
        "DKK": "🇩🇰", "DOP": "🇩🇴", "DZD": "🇩🇿", "EGP": "🇪🇬",
        "ETB": "🇪🇹", "EUR": "🇪🇺", "GBP": "🇬🇧", "GEL": "🇬🇪",
        "GHS": "🇬🇭", "GNF": "🇬🇳", "GTQ": "🇬🇹", "HKD": "🇭🇰",
        "HNL": "🇭🇳", "HUF": "🇭🇺", "IDR": "🇮🇩", "ILS": "🇮🇱",
        "INR": "🇮🇳", "IQD": "🇮🇶", "IRR": "🇮🇷", "ISK": "🇮🇸",
        "JMD": "🇯🇲", "JOD": "🇯🇴", "JPY": "🇯🇵", "KES": "🇰🇪",
        "KGS": "🇰🇬", "KHR": "🇰🇭", "KRW": "🇰🇷", "KWD": "🇰🇼",
        "KZT": "🇰🇿", "LAK": "🇱🇦", "LBP": "🇱🇧", "LKR": "🇱🇰",
        "MAD": "🇲🇦", "MDL": "🇲🇩", "MMK": "🇲🇲", "MNT": "🇲🇳",
        "MXN": "🇲🇽", "MYR": "🇲🇾", "NGN": "🇳🇬", "NIO": "🇳🇮",
        "NOK": "🇳🇴", "NPR": "🇳🇵", "NZD": "🇳🇿", "OMR": "🇴🇲",
        "PAB": "🇵🇦", "PEN": "🇵🇪", "PHP": "🇵🇭", "PKR": "🇵🇰",
        "PLN": "🇵🇱", "PYG": "🇵🇾", "QAR": "🇶🇦", "RON": "🇷🇴",
        "RSD": "🇷🇸", "RUB": "🇷🇺", "RWF": "🇷🇼", "SAR": "🇸🇦",
        "SEK": "🇸🇪", "SGD": "🇸🇬", "THB": "🇹🇭", "TRY": "🇹🇷",
        "TTD": "🇹🇹", "TWD": "🇹🇼", "TZS": "🇹🇿", "UAH": "🇺🇦",
        "UGX": "🇺🇬", "USD": "🇺🇸", "UYU": "🇺🇾", "UZS": "🇺🇿",
        "VES": "🇻🇪", "VND": "🇻🇳", "XAF": "🇨🇲", "XCD": "🇦🇬",
        "XOF": "🇸🇳", "XPF": "🇵🇫", "YER": "🇾🇪", "ZAR": "🇿🇦"
    ]
}
