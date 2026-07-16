//
//  CategoryColor+SwiftUI.swift
//  Ask Numi
//

import SwiftUI

extension CategoryColor {
    var displayColor: Color {
        switch self {
        case .red: .red
        case .pink: .pink
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .mint: .mint
        case .cyan: .cyan
        case .blue: .blue
        case .purple: .purple
        }
    }
}
