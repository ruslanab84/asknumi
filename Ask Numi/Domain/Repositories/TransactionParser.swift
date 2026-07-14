//
//  TransactionParser.swift
//  Ask Numi
//
//  Domain port for turning free-form text ("spent 350 on coffee at Surf")
//  into a transaction draft. The Foundation Models adapter lives in
//  Infrastructure/AI; this protocol keeps the domain free of any
//  FoundationModels import. Availability is reused from the advisor so
//  Presentation never has to know which framework backs it.
//

import Foundation

protocol TransactionParser: Sendable {
    var availability: AdvisorAvailability { get }
    func parse(_ text: String) async throws -> ParsedTransactionDraft
}
