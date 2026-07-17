//
//  GetFinancialTwinUseCase.swift
//  Ask Numi
//

import Foundation

struct GetFinancialTwinUseCase: Sendable {
    func execute(
        transactions: [Transaction],
        budgets: [Budget],
        subscriptions: [Subscription],
        asOf date: Date = .now,
        calendar: Calendar = .current
    ) -> FinancialTwinReport {
        let recorded = transactions.filter { $0.date <= date }
        var insights: [FinancialTwinInsight] = []

        if let insight = paydayInsight(in: recorded, asOf: date, calendar: calendar) {
            insights.append(.paydaySpending(insight))
        }
        if let insight = impulseInsight(in: recorded, calendar: calendar) {
            insights.append(.impulseTiming(insight))
        }
        if let insight = budgetInsight(in: recorded, budgets: budgets, asOf: date, calendar: calendar) {
            insights.append(.budgetOverrun(insight))
        }
        if let insight = monthEndInsight(in: recorded, asOf: date, calendar: calendar) {
            insights.append(.monthEndBalance(insight))
        }
        if let insight = recurringInsight(
            in: recorded,
            subscriptions: subscriptions,
            asOf: date,
            calendar: calendar
        ) {
            insights.append(.unplannedRecurring(insight))
        }
        if insights.isEmpty, let insight = cashFlowSnapshot(in: recorded) {
            insights.append(.cashFlowSnapshot(insight))
        }

        return FinancialTwinReport(
            insights: insights,
            transactionCount: recorded.count,
            budgetCount: budgets.count,
            subscriptionCount: subscriptions.count
        )
    }

    private func cashFlowSnapshot(in transactions: [Transaction]) -> CashFlowSnapshotInsight? {
        guard !transactions.isEmpty else { return nil }

        let income = transactions
            .filter { $0.kind == .income }
            .reduce(Decimal.zero) { $0 + $1.amount }
        let expenses = transactions
            .filter { $0.kind == .expense }
            .reduce(Decimal.zero) { $0 + $1.amount }
        var categories: [String: (name: String, amount: Decimal)] = [:]
        for transaction in transactions where transaction.kind == .expense {
            let key = normalized(transaction.category)
            guard !key.isEmpty else { continue }
            let current = categories[key]
            categories[key] = (
                current?.name ?? transaction.category,
                (current?.amount ?? 0) + transaction.amount
            )
        }
        let topCategory = categories.values.max { $0.amount < $1.amount }
        let topAmount = topCategory?.amount ?? 0
        let topShare = expenses > 0
            ? Int((NSDecimalNumber(decimal: topAmount / expenses).doubleValue * 100).rounded())
            : 0

        return CashFlowSnapshotInsight(
            totalIncome: income,
            totalExpenses: expenses,
            balance: income - expenses,
            transactionCount: transactions.count,
            topExpenseCategory: topCategory?.name,
            topExpenseAmount: topAmount,
            topExpenseSharePercent: topShare
        )
    }

    private func impulseInsight(
        in transactions: [Transaction],
        calendar: Calendar
    ) -> ImpulseTimingInsight? {
        let marked = transactions.filter { $0.kind == .expense && $0.isImpulse }
        guard marked.count >= 3 else { return nil }

        let grouped = Dictionary(grouping: marked) { transaction in
            ImpulseBucket(
                weekday: calendar.component(.weekday, from: transaction.date),
                dayPart: dayPart(for: transaction.date, calendar: calendar)
            )
        }
        guard let winner = grouped.max(by: { lhs, rhs in
            if lhs.value.count == rhs.value.count {
                return total(lhs.value) < total(rhs.value)
            }
            return lhs.value.count < rhs.value.count
        }), winner.value.count >= 2 else { return nil }

        return ImpulseTimingInsight(
            weekday: winner.key.weekday,
            dayPart: winner.key.dayPart,
            matchingCount: winner.value.count,
            totalCount: marked.count,
            matchingAmount: total(winner.value),
            samples: winner.value
                .sorted { $0.date > $1.date }
                .prefix(5)
                .map { FinancialTwinTransactionSample(date: $0.date, amount: $0.amount) }
        )
    }

    private func paydayInsight(
        in transactions: [Transaction],
        asOf date: Date,
        calendar: Calendar
    ) -> PaydaySpendingInsight? {
        let lookback = calendar.date(byAdding: .month, value: -12, to: date) ?? .distantPast
        let paydayStarts = Set(transactions
            .filter { transaction in
                transaction.kind == .income &&
                    transaction.date >= lookback &&
                    isSalary(transaction)
            }
            .map { calendar.startOfDay(for: $0.date) }
            .filter { start in
                guard let end = calendar.date(byAdding: .day, value: 5, to: start) else { return false }
                return end <= date
            })
            .sorted()
        guard paydayStarts.count >= 2, let observationStart = paydayStarts.first else { return nil }

        let totalDays = max(
            calendar.dateComponents(
                [.day],
                from: observationStart,
                to: calendar.startOfDay(for: date)
            ).day ?? 0,
            0
        ) + 1
        let postPaydayDays = Set(paydayStarts.flatMap { start in
            (0..<5).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        })
        let baselineDays = totalDays - postPaydayDays.count
        guard baselineDays >= 5 else { return nil }

        var categories: [String: PaydayCategoryAccumulator] = [:]
        let expenses = transactions.filter {
            $0.kind == .expense && $0.date >= observationStart && $0.date <= date
        }
        for transaction in expenses {
            let key = normalized(transaction.category)
            guard !key.isEmpty else { continue }
            var value = categories[key] ?? PaydayCategoryAccumulator(name: transaction.category)
            if let window = paydayStarts.firstIndex(where: { start in
                guard let end = calendar.date(byAdding: .day, value: 5, to: start) else { return false }
                return transaction.date >= start && transaction.date < end
            }) {
                value.postPaydayTotal += transaction.amount
                value.windows.insert(window)
            } else {
                value.baselineTotal += transaction.amount
            }
            categories[key] = value
        }

        let candidates = categories.values.compactMap { value -> PaydaySpendingInsight? in
            guard value.windows.count >= 2, value.baselineTotal > 0 else { return nil }
            let postAverage = value.postPaydayTotal / Decimal(paydayStarts.count)
            let baselineAverage = value.baselineTotal / Decimal(baselineDays) * 5
            guard baselineAverage > 0 else { return nil }
            let ratio = NSDecimalNumber(decimal: postAverage / baselineAverage).doubleValue
            let increase = Int(((ratio - 1) * 100).rounded())
            guard increase >= 20 else { return nil }
            return PaydaySpendingInsight(
                category: value.name,
                increasePercent: increase,
                paydayCount: paydayStarts.count,
                firstFiveDayAverage: postAverage,
                baselineFiveDayAverage: baselineAverage,
                paydayDates: Array(paydayStarts.suffix(6).reversed())
            )
        }
        return candidates.max { $0.increasePercent < $1.increasePercent }
    }

    private func budgetInsight(
        in transactions: [Transaction],
        budgets: [Budget],
        asOf date: Date,
        calendar: Calendar
    ) -> BudgetOverrunInsight? {
        guard let month = calendar.dateInterval(of: .month, for: date) else { return nil }
        let expenses = transactions
            .filter { $0.kind == .expense && month.contains($0.date) && $0.date <= date }
            .sorted { $0.date < $1.date }

        let crossings = budgets.compactMap { budget -> BudgetCrossing? in
            var spent: Decimal = 0
            for transaction in expenses where Budget.categoryKey(for: transaction.category) == budget.categoryKey {
                spent += transaction.amount
                if spent > budget.monthlyLimit {
                    return BudgetCrossing(
                        category: budget.category,
                        limit: budget.monthlyLimit,
                        date: transaction.date,
                        spentAtCrossing: spent
                    )
                }
            }
            return nil
        }
        guard !crossings.isEmpty else { return nil }
        return BudgetOverrunInsight(crossings: crossings.sorted { $0.date < $1.date })
    }

    private func monthEndInsight(
        in transactions: [Transaction],
        asOf date: Date,
        calendar: Calendar
    ) -> MonthEndBalanceInsight? {
        guard let currentMonth = calendar.dateInterval(of: .month, for: date) else { return nil }
        let completed = transactions.filter { $0.date < currentMonth.start }
        let grouped = Dictionary(grouping: completed) { transaction in
            calendar.dateInterval(of: .month, for: transaction.date)?.start ?? transaction.date
        }
        let samples = grouped.compactMap { month, values -> MonthEndSample? in
            let income = values.filter { $0.kind == .income }.reduce(Decimal.zero) { $0 + $1.amount }
            let expenses = values.filter { $0.kind == .expense }.reduce(Decimal.zero) { $0 + $1.amount }
            guard income > 0, expenses > 0 else { return nil }
            return MonthEndSample(
                month: month,
                income: income,
                expenses: expenses,
                balance: income - expenses
            )
        }
        .sorted { $0.month > $1.month }
        .prefix(6)

        guard samples.count >= 2 else { return nil }
        let balances = samples.map(\.balance).sorted()
        let middle = balances.count / 2
        let median = balances.count.isMultiple(of: 2)
            ? (balances[middle - 1] + balances[middle]) / 2
            : balances[middle]
        return MonthEndBalanceInsight(medianBalance: median, samples: Array(samples))
    }

    private func recurringInsight(
        in transactions: [Transaction],
        subscriptions: [Subscription],
        asOf date: Date,
        calendar: Calendar
    ) -> UnplannedRecurringInsight? {
        let lookback = calendar.date(byAdding: .month, value: -12, to: date) ?? .distantPast
        let scheduled = Set(subscriptions.map { normalized($0.name) })
        let expenses = transactions.filter {
            $0.kind == .expense && $0.date >= lookback && $0.date <= date
        }
        let grouped = Dictionary(grouping: expenses) { transaction in
            normalized(transaction.note?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? transaction.category)
        }

        let candidates = grouped.compactMap { key, values -> RecurringExpenseCandidate? in
            guard !key.isEmpty,
                  !scheduled.contains(key),
                  !values.contains(where: { scheduled.contains(normalized($0.category)) }) else {
                return nil
            }
            let byMonth = Dictionary(grouping: values) { MonthKey(date: $0.date, calendar: calendar) }
            guard byMonth.count >= 3,
                  byMonth.values.allSatisfy({ $0.count == 1 }) else { return nil }

            let monthOrdinals = byMonth.keys.map(\.ordinal).sorted()
            guard let firstMonth = monthOrdinals.first,
                  let lastMonth = monthOrdinals.last,
                  lastMonth - firstMonth <= monthOrdinals.count else { return nil }

            let ordered = values.sorted { $0.date > $1.date }
            let amounts = ordered.map(\.amount).sorted()
            guard let minimum = amounts.first,
                  let maximum = amounts.last,
                  maximum <= minimum * 11 / 10 else { return nil }

            let days = ordered.map { calendar.component(.day, from: $0.date) }
            guard let minimumDay = days.min(),
                  let maximumDay = days.max(),
                  maximumDay - minimumDay <= 4 else { return nil }

            let middle = amounts.count / 2
            let typical = amounts.count.isMultiple(of: 2)
                ? (amounts[middle - 1] + amounts[middle]) / 2
                : amounts[middle]
            let name = ordered.first?.note?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
                ?? ordered.first?.category
                ?? key
            return RecurringExpenseCandidate(
                name: name,
                typicalAmount: typical,
                occurrenceCount: ordered.count,
                samples: ordered.prefix(6).map {
                    FinancialTwinTransactionSample(date: $0.date, amount: $0.amount)
                }
            )
        }
        .sorted {
            if $0.occurrenceCount == $1.occurrenceCount {
                return $0.typicalAmount > $1.typicalAmount
            }
            return $0.occurrenceCount > $1.occurrenceCount
        }
        .prefix(3)

        guard !candidates.isEmpty else { return nil }
        return UnplannedRecurringInsight(candidates: Array(candidates))
    }

    private func isSalary(_ transaction: Transaction) -> Bool {
        let value = normalized([transaction.category, transaction.note].compactMap { $0 }.joined(separator: " "))
        return ["salary", "payroll", "wage", "зарплат"].contains { value.contains($0) }
    }

    private func dayPart(for date: Date, calendar: Calendar) -> FinancialTwinDayPart {
        switch calendar.component(.hour, from: date) {
        case 5..<12: .morning
        case 12..<17: .afternoon
        case 17..<22: .evening
        default: .night
        }
    }

    private func total(_ transactions: [Transaction]) -> Decimal {
        transactions.reduce(Decimal.zero) { $0 + $1.amount }
    }

    private func normalized(_ value: String) -> String {
        value
            .folding(
                options: [.caseInsensitive, .diacriticInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct ImpulseBucket: Hashable {
    let weekday: Int
    let dayPart: FinancialTwinDayPart
}

private struct PaydayCategoryAccumulator {
    let name: String
    var postPaydayTotal: Decimal = 0
    var baselineTotal: Decimal = 0
    var windows: Set<Int> = []
}

private struct MonthKey: Hashable {
    let year: Int
    let month: Int

    init(date: Date, calendar: Calendar) {
        year = calendar.component(.year, from: date)
        month = calendar.component(.month, from: date)
    }

    var ordinal: Int { year * 12 + month }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

#if DEBUG
extension GetFinancialTwinUseCase {
    static func assertSelfCheck() {
        var calendar = Calendar(identifier: .gregorian)
        guard let timeZone = TimeZone(secondsFromGMT: 0) else {
            assertionFailure("UTC time zone is unavailable")
            return
        }
        calendar.timeZone = timeZone
        func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
            calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)) ?? .distantPast
        }

        let transactions = [
            Transaction(amount: 2_000, kind: .income, category: "Salary", date: date(2026, 1, 1)),
            Transaction(amount: 100, kind: .expense, category: "Restaurants", date: date(2026, 1, 2)),
            Transaction(amount: 20, kind: .expense, category: "Restaurants", date: date(2026, 1, 15)),
            Transaction(amount: 30, kind: .expense, category: "Gym", date: date(2026, 1, 10)),
            Transaction(amount: 15, kind: .expense, category: "Coffee", date: date(2026, 1, 9, 19), isImpulse: true),
            Transaction(amount: 2_000, kind: .income, category: "Salary", date: date(2026, 2, 1)),
            Transaction(amount: 120, kind: .expense, category: "Restaurants", date: date(2026, 2, 2)),
            Transaction(amount: 20, kind: .expense, category: "Restaurants", date: date(2026, 2, 15)),
            Transaction(amount: 30, kind: .expense, category: "Gym", date: date(2026, 2, 10)),
            Transaction(amount: 25, kind: .expense, category: "Coffee", date: date(2026, 2, 13, 19), isImpulse: true),
            Transaction(amount: 30, kind: .expense, category: "Gym", date: date(2026, 3, 10)),
            Transaction(amount: 35, kind: .expense, category: "Coffee", date: date(2026, 3, 13, 19), isImpulse: true),
            Transaction(amount: 60, kind: .expense, category: "Groceries", date: date(2026, 4, 3)),
            Transaction(amount: 50, kind: .expense, category: "Groceries", date: date(2026, 4, 5))
        ]
        let report = GetFinancialTwinUseCase().execute(
            transactions: transactions,
            budgets: [Budget(category: "Groceries", monthlyLimit: 100)],
            subscriptions: [],
            asOf: date(2026, 4, 20),
            calendar: calendar
        )
        let kinds = Set(report.insights.map(\.id))
        assert(kinds == [
            .paydaySpending,
            .impulseTiming,
            .budgetOverrun,
            .monthEndBalance,
            .unplannedRecurring
        ])

        let sparseReport = GetFinancialTwinUseCase().execute(
            transactions: Array(transactions.prefix(2)),
            budgets: [],
            subscriptions: [],
            asOf: date(2026, 1, 20),
            calendar: calendar
        )
        guard case .cashFlowSnapshot(let snapshot) = sparseReport.insights.first else {
            assertionFailure("sparse history must produce a cash-flow result")
            return
        }
        assert(snapshot.totalIncome == 2_000)
        assert(snapshot.totalExpenses == 100)
        assert(snapshot.topExpenseCategory == "Restaurants")
    }
}
#endif
