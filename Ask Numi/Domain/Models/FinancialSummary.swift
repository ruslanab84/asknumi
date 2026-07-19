//
//  FinancialSummary.swift
//  Ask Numi
//

import Foundation

/// Deterministic aggregate of a period's transactions.
/// All arithmetic happens here, in Swift. The on-device model receives
/// these finished numbers and never computes anything itself — small
/// language models are unreliable at math.
struct FinancialSummary: Sendable {
    let period: DateInterval
    let transactionCount: Int
    let totalIncome: Decimal
    let totalExpenses: Decimal
    /// Expense totals per category, sorted descending by amount.
    let expensesByCategory: [(category: String, amount: Decimal)]

    var balance: Decimal { totalIncome - totalExpenses }

    /// Share of income left unspent, 0…1. `nil` when there is no income.
    var savingsRate: Double? {
        guard totalIncome > 0 else { return nil }
        let rate = (totalIncome - totalExpenses) / totalIncome
        return NSDecimalNumber(decimal: rate).doubleValue
    }

    init(transactions: [Transaction], period: DateInterval) {
        self.period = period
        transactionCount = transactions.count

        var income: Decimal = 0
        var expenses: Decimal = 0
        var byCategory: [String: Decimal] = [:]

        for transaction in transactions {
            switch transaction.kind {
            case .income:
                income += transaction.amount
            case .expense:
                expenses += transaction.amount
                byCategory[transaction.category, default: 0] += transaction.amount
            }
        }

        totalIncome = income
        totalExpenses = expenses
        expensesByCategory = byCategory
            .map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }
}
