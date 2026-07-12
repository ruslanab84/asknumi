//
//  Bundle+Localization.swift
//  Ask Numi
//

import Foundation

private var overrideBundle: Bundle?

extension Bundle {
    static var localized: Bundle {
        overrideBundle ?? .main
    }

    static func setLanguage(_ languageCode: String) {
        guard
            let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else { return }
        overrideBundle = bundle
    }
}
