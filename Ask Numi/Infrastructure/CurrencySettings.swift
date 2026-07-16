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
