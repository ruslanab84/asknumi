//
//  GetFinancialAdviceUseCase.swift
//  Ask Numi
//
//  The full AI pipeline: fetch transactions → aggregate deterministically
//  in Swift → hand the compact summary to the advisor for phrasing.
//

import Foundation

struct GetFinancialAdviceUseCase: Sendable {
    private let transactions: TransactionRepository
    private let advisor: FinancialAdvisor

    init(transactions: TransactionRepository, advisor: FinancialAdvisor) {
        self.transactions = transactions
        self.advisor = advisor
    }

    var advisorAvailability: AdvisorAvailability { advisor.availability }

    func execute(for period: DateInterval) async throws -> FinancialAdvice {
        let items = try await transactions.fetch(in: period)
        guard !items.isEmpty else { throw DomainError.notEnoughData }
        let summary = FinancialSummary(transactions: items, period: period)
        return try await advisor.advise(on: summary)
    }
}
