//
//  FinancialAdvisor.swift
//  Ask Numi
//
//  Domain port for the AI assistant. The Foundation Models adapter
//  lives in Infrastructure/AI; this protocol keeps the domain free
//  of any FoundationModels import.
//

import Foundation

protocol FinancialAdvisor: Sendable {
    var availability: AdvisorAvailability { get }
    func advise(on summary: FinancialSummary) async throws -> FinancialAdvice
}
