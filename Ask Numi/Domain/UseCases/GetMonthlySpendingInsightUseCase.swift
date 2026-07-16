//
//  GetMonthlySpendingInsightUseCase.swift
//  Ask Numi
//

import Foundation

struct MonthlySpendingTrend: Equatable, Sendable {
    let category: String
    let currentAmount: Decimal
    let previousAmount: Decimal
    let percentageChange: Int
}

struct GetMonthlySpendingInsightUseCase: Sendable {
    private let advisor: FinancialAdvisor

    init(advisor: FinancialAdvisor) {
        self.advisor = advisor
    }

    var advisorAvailability: AdvisorAvailability { advisor.availability }

    func execute(
        transactions: [Transaction],
        now: Date = .now,
        calendar: Calendar = .current
    ) async throws -> FinancialAdvice {
        guard let currentPeriod = calendar.dateInterval(of: .month, for: now),
              let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentPeriod.start),
              let previousPeriod = calendar.dateInterval(of: .month, for: previousMonth) else {
            throw DomainError.notEnoughData
        }

        let currentTransactions = transactions.filter {
            $0.date >= currentPeriod.start && $0.date < currentPeriod.end
        }
        let previousTransactions = transactions.filter {
            $0.date >= previousPeriod.start && $0.date < previousPeriod.end
        }
        guard let trend = Self.mostRelevantTrend(
            current: currentTransactions,
            previous: previousTransactions
        ) else {
            throw DomainError.notEnoughData
        }

        let summary = FinancialSummary(transactions: currentTransactions, period: currentPeriod)
        return try await advisor.advise(
            on: summary,
            question: nil,
            task: .monthlySpendingTrend(trend)
        )
    }

    private static func mostRelevantTrend(
        current: [Transaction],
        previous: [Transaction]
    ) -> MonthlySpendingTrend? {
        let currentTotals = expenseTotals(in: current)
        let previousTotals = expenseTotals(in: previous)

        return Set(currentTotals.keys).union(previousTotals.keys).compactMap { key in
            let currentItem = currentTotals[key]
            let previousItem = previousTotals[key]
            let currentAmount = currentItem?.amount ?? 0
            let previousAmount = previousItem?.amount ?? 0
            guard previousAmount > 0,
                  currentAmount != previousAmount,
                  let category = currentItem?.category ?? previousItem?.category else { return nil }

            let percentage = NSDecimalNumber(
                decimal: (currentAmount - previousAmount) / previousAmount * 100
            ).doubleValue.rounded()
            guard percentage.isFinite,
                  percentage >= Double(Int.min),
                  percentage <= Double(Int.max),
                  percentage != 0 else { return nil }

            return MonthlySpendingTrend(
                category: category,
                currentAmount: currentAmount,
                previousAmount: previousAmount,
                percentageChange: Int(percentage)
            )
        }
        .max {
            abs($0.currentAmount - $0.previousAmount) < abs($1.currentAmount - $1.previousAmount)
        }
    }

    private static func expenseTotals(in transactions: [Transaction]) -> [String: CategoryTotal] {
        transactions.reduce(into: [:]) { totals, transaction in
            guard transaction.kind == .expense else { return }
            let key = transaction.category.folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: .current
            ).lowercased()
            totals[key, default: CategoryTotal(category: transaction.category, amount: 0)].amount += transaction.amount
        }
    }

    #if DEBUG
    static func assertSelfCheck() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        guard let currentDate = calendar.date(from: DateComponents(year: 2026, month: 7, day: 5)),
              let previousDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 5)) else {
            assertionFailure("Self-check dates must be valid")
            return
        }
        let trend = mostRelevantTrend(
            current: [Transaction(amount: 120, kind: .expense, category: "Coffee", date: currentDate)],
            previous: [Transaction(amount: 100, kind: .expense, category: "coffee", date: previousDate)]
        )

        assert(trend?.category == "Coffee")
        assert(trend?.percentageChange == 20)
    }
    #endif

    private struct CategoryTotal {
        let category: String
        var amount: Decimal
    }
}
