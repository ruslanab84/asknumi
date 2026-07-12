//
//  FinancialAdvice.swift
//  Ask Numi
//

import Foundation

/// Advice produced by the on-device assistant.
struct FinancialAdvice: Equatable, Sendable {
    let headline: String
    let tips: [String]
}

/// Domain-level view of the assistant's availability, so Presentation
/// never has to import FoundationModels.
enum AdvisorAvailability: Equatable, Sendable {
    case available
    case downloading   // model assets not ready yet
    case unavailable   // device not eligible or Apple Intelligence disabled
}
