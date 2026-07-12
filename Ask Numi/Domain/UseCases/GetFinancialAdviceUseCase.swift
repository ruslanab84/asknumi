//
//  GetFinancialAdviceUseCase.swift
//  Ask Numi
//
//  The full AI pipeline: fetch transactions → aggregate deterministically
//  in Swift → hand the compact summary to the advisor for phrasing.
//

import Foundation

/// The deterministic numbers and the model's phrasing, together, so the UI
/// can chart the summary next to the advice without a second fetch.
struct FinancialAdviceReport: Sendable {
    let summary: FinancialSummary
    let advice: FinancialAdvice
}

struct GetFinancialAdviceUseCase: Sendable {
    private let transactions: TransactionRepository
    private let advisor: FinancialAdvisor

    init(transactions: TransactionRepository, advisor: FinancialAdvisor) {
        self.transactions = transactions
        self.advisor = advisor
    }

    var advisorAvailability: AdvisorAvailability { advisor.availability }

    func execute(question: String? = nil, for period: DateInterval) async throws -> FinancialAdviceReport {
        let items = try await transactions.fetch(in: period)
        guard !items.isEmpty else { throw DomainError.notEnoughData }
        let summary = FinancialSummary(transactions: items, period: period)
        let advice = try await advisor.advise(on: summary, question: question)
        return FinancialAdviceReport(summary: summary, advice: advice)
    }
}
