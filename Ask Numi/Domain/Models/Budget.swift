//
//  Budget.swift
//  Ask Numi
//

import Foundation

struct Budget: Identifiable, Hashable, Sendable {
    let id: UUID
    var category: String
    var categoryIcon: String
    var monthlyLimit: Decimal

    nonisolated init(
        id: UUID = UUID(),
        category: String,
        categoryIcon: String = CategoryIcon.fallback,
        monthlyLimit: Decimal
    ) {
        self.id = id
        self.category = category
        self.categoryIcon = categoryIcon
        self.monthlyLimit = monthlyLimit
    }

    nonisolated var categoryKey: String {
        Self.categoryKey(for: category)
    }

    nonisolated static func categoryKey(for category: String) -> String {
        category
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
            .lowercased()
    }
}

enum BudgetPace: Equatable, Sendable {
    case onTrack
    case atRisk
    case over
}

struct BudgetProgress: Identifiable, Sendable {
    let budget: Budget
    let spent: Decimal
    let projectedSpend: Decimal
    let remaining: Decimal
    let progress: Double
    let dailyAllowance: Decimal
    let pace: BudgetPace

    nonisolated var id: UUID { budget.id }
}

/// Deterministic monthly budget math. Presentation only formats the finished values.
struct BudgetOverview: Sendable {
    let period: DateInterval
    let items: [BudgetProgress]
    let totalLimit: Decimal
    let totalSpent: Decimal
    let remaining: Decimal
    let dailyAllowance: Decimal
    let unbudgetedSpent: Decimal

    nonisolated init(
        budgets: [Budget],
        transactions: [Transaction],
        asOf date: Date = .now,
        calendar: Calendar = .current
    ) {
        let period = calendar.dateInterval(of: .month, for: date)
            ?? DateInterval(start: calendar.startOfDay(for: date), duration: 86_400)
        let totalDays = calendar.range(of: .day, in: .month, for: date)?.count ?? 1
        let currentDay = max(calendar.component(.day, from: date), 1)
        let daysRemaining = max(totalDays - currentDay + 1, 1)
        let expenses = transactions.filter {
            $0.kind == .expense && $0.date >= period.start && $0.date < period.end
        }

        var spendingByCategory: [String: Decimal] = [:]
        for transaction in expenses {
            spendingByCategory[Budget.categoryKey(for: transaction.category), default: 0] += transaction.amount
        }

        let items = budgets.map { budget in
            let spent = spendingByCategory[budget.categoryKey, default: 0]
            let remaining = budget.monthlyLimit - spent
            let progress = budget.monthlyLimit > 0
                ? NSDecimalNumber(decimal: spent / budget.monthlyLimit).doubleValue
                : 0
            let projectedSpend = spent * Decimal(totalDays) / Decimal(currentDay)
            let pace: BudgetPace = if spent > budget.monthlyLimit {
                .over
            } else if projectedSpend > budget.monthlyLimit {
                .atRisk
            } else {
                .onTrack
            }

            return BudgetProgress(
                budget: budget,
                spent: spent,
                projectedSpend: projectedSpend,
                remaining: remaining,
                progress: progress,
                dailyAllowance: max(remaining, 0) / Decimal(daysRemaining),
                pace: pace
            )
        }

        let budgetedKeys = Set(budgets.map(\.categoryKey))
        let totalLimit = budgets.reduce(Decimal.zero) { $0 + $1.monthlyLimit }
        let totalSpent = items.reduce(Decimal.zero) { $0 + $1.spent }
        let remaining = totalLimit - totalSpent

        self.period = period
        self.items = items
        self.totalLimit = totalLimit
        self.totalSpent = totalSpent
        self.remaining = remaining
        self.dailyAllowance = max(remaining, 0) / Decimal(daysRemaining)
        unbudgetedSpent = expenses.reduce(Decimal.zero) { partial, transaction in
            budgetedKeys.contains(Budget.categoryKey(for: transaction.category))
                ? partial
                : partial + transaction.amount
        }
    }
}

#if DEBUG
extension BudgetOverview {
    /// Small startup check for the budget math while the project has no test target.
    nonisolated static func assertSelfCheck() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 7, day: 13))!
        let groceries = Budget(category: "Groceries", categoryIcon: "cart", monthlyLimit: 310)
        let overview = BudgetOverview(
            budgets: [groceries],
            transactions: [
                Transaction(amount: 120, kind: .expense, category: "groceries", categoryIcon: "cart", date: date),
                Transaction(amount: 25, kind: .expense, category: "Taxi", categoryIcon: "car", date: date)
            ],
            asOf: date,
            calendar: calendar
        )

        assert(overview.totalSpent == 120)
        assert(overview.remaining == 190)
        assert(overview.unbudgetedSpent == 25)
        assert(overview.items.first?.dailyAllowance == 10)
    }
}
#endif
