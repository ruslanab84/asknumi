//
//  SimulateFinancialTimeMachineUseCase.swift
//  Ask Numi
//

import Foundation

struct FinancialTimeMachineAssumptions: Equatable, Sendable {
    let spendingCategory: String
    let spendingReductionPercent: Int
    let incomeCategory: String
    let incomeDelayDays: Int
    let subscriptionIncreasePercent: Int
    let monthlySavings: Decimal
    let horizonMonths: Int
}

struct FinancialTimeMachineIncomeShift: Equatable, Sendable {
    let category: String
    let amount: Decimal
    let originalDate: Date
    let delayedDate: Date
}

struct FinancialTimeMachineMonth: Identifiable, Equatable, Sendable {
    let start: Date
    let baselineNetCashFlow: Decimal
    let scenarioNetCashFlow: Decimal
    let baselineCumulativeCashFlow: Decimal
    let scenarioCumulativeCashFlow: Decimal

    var id: Date { start }
}

struct FinancialTimeMachineReport: Equatable, Sendable {
    let assumptions: FinancialTimeMachineAssumptions
    let forecastPeriod: DateInterval
    let sampleMonthCount: Int
    let spendingSaved: Decimal
    let additionalSubscriptionCost: Decimal
    let plannedSavings: Decimal
    let incomeShift: FinancialTimeMachineIncomeShift?
    let baselineEndingCashFlow: Decimal
    let scenarioEndingCashFlow: Decimal
    let difference: Decimal
    let months: [FinancialTimeMachineMonth]
}

struct SimulateFinancialTimeMachineUseCase: Sendable {
    func execute(
        assumptions: FinancialTimeMachineAssumptions,
        transactions: [Transaction],
        subscriptions: [Subscription],
        asOf date: Date = .now,
        calendar: Calendar = .current
    ) throws -> FinancialTimeMachineReport {
        guard (1...12).contains(assumptions.horizonMonths),
              (0...100).contains(assumptions.spendingReductionPercent),
              (0...31).contains(assumptions.incomeDelayDays),
              (0...100).contains(assumptions.subscriptionIncreasePercent),
              assumptions.monthlySavings >= 0
        else { throw DomainError.invalidAmount }

        let spendingCategory = assumptions.spendingCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        let incomeCategory = assumptions.incomeCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        guard assumptions.spendingReductionPercent == 0 || !spendingCategory.isEmpty,
              assumptions.incomeDelayDays == 0 || !incomeCategory.isEmpty
        else { throw DomainError.categoryNotFound }

        let currentMonth = calendar.dateInterval(of: .month, for: date)
            ?? DateInterval(start: calendar.startOfDay(for: date), duration: 86_400)
        let forecastStart = currentMonth.end
        let forecastEnd = calendar.date(
            byAdding: .month,
            value: assumptions.horizonMonths,
            to: forecastStart
        ) ?? forecastStart
        let forecastPeriod = DateInterval(start: forecastStart, end: forecastEnd)
        let recorded = transactions.filter { $0.date <= date }
        let samples = samplePeriods(from: recorded, asOf: date, calendar: calendar)
        let sampleTransactions = recorded.filter { transaction in
            samples.contains { transaction.date >= $0.start && transaction.date < $0.end }
        }
        let subscriptionKeys = Set(subscriptions.map { Budget.categoryKey(for: $0.name) })
        let sampleCount = Decimal(samples.count)

        var regularExpensesByCategory: [String: (name: String, total: Decimal)] = [:]
        var incomeTemplates: [IncomeTemplateKey: (name: String, total: Decimal)] = [:]
        if sampleCount > 0 {
            for transaction in sampleTransactions {
                let key = Budget.categoryKey(for: transaction.category)
                guard !key.isEmpty else { continue }

                switch transaction.kind {
                case .expense where !subscriptionKeys.contains(key):
                    let current = regularExpensesByCategory[key]
                    regularExpensesByCategory[key] = (
                        current?.name ?? transaction.category,
                        (current?.total ?? 0) + transaction.amount
                    )
                case .income:
                    let templateKey = IncomeTemplateKey(
                        category: key,
                        day: calendar.component(.day, from: transaction.date)
                    )
                    let current = incomeTemplates[templateKey]
                    incomeTemplates[templateKey] = (
                        current?.name ?? transaction.category,
                        (current?.total ?? 0) + transaction.amount
                    )
                case .expense:
                    break
                }
            }
        }

        let regularExpense = regularExpensesByCategory.values.reduce(Decimal.zero) {
            $0 + $1.total / sampleCountOrOne(sampleCount)
        }
        let spendingKey = Budget.categoryKey(for: spendingCategory)
        let selectedExpense = regularExpensesByCategory[spendingKey]?.total ?? 0
        let monthlySpendingSaved = selectedExpense / sampleCountOrOne(sampleCount)
            * Decimal(assumptions.spendingReductionPercent) / 100
        let spendingSaved = monthlySpendingSaved * Decimal(assumptions.horizonMonths)

        let intervals = (0..<assumptions.horizonMonths).compactMap { offset -> DateInterval? in
            guard let month = calendar.date(byAdding: .month, value: offset, to: forecastStart) else {
                return nil
            }
            return calendar.dateInterval(of: .month, for: month)
        }
        var baselineIncome = Array(repeating: Decimal.zero, count: intervals.count)
        var projectedIncomeEvents: [ProjectedIncomeEvent] = []
        for (index, interval) in intervals.enumerated() {
            for (key, value) in incomeTemplates {
                let event = ProjectedIncomeEvent(
                    date: projectedDate(in: interval, day: key.day, calendar: calendar),
                    categoryKey: key.category,
                    category: value.name,
                    amount: value.total / sampleCountOrOne(sampleCount)
                )
                projectedIncomeEvents.append(event)
                baselineIncome[index] += event.amount
            }
        }

        var scenarioIncome = baselineIncome
        let incomeKey = Budget.categoryKey(for: incomeCategory)
        let shiftedEvent = assumptions.incomeDelayDays > 0
            ? projectedIncomeEvents
                .filter { $0.categoryKey == incomeKey }
                .min { $0.date < $1.date }
            : nil
        let incomeShift = shiftedEvent.map { event in
            let delayedDate = calendar.date(
                byAdding: .day,
                value: assumptions.incomeDelayDays,
                to: event.date
            ) ?? event.date
            if let source = monthIndex(containing: event.date, intervals: intervals) {
                scenarioIncome[source] -= event.amount
            }
            if let destination = monthIndex(containing: delayedDate, intervals: intervals) {
                scenarioIncome[destination] += event.amount
            }
            return FinancialTimeMachineIncomeShift(
                category: event.category,
                amount: event.amount,
                originalDate: event.date,
                delayedDate: delayedDate
            )
        }

        var baselineSubscriptions = Array(repeating: Decimal.zero, count: intervals.count)
        for subscription in subscriptions {
            for chargeDate in subscription.chargeDates(
                from: forecastStart,
                before: forecastEnd,
                calendar: calendar
            ) {
                if let index = monthIndex(containing: chargeDate, intervals: intervals) {
                    baselineSubscriptions[index] += subscription.amount
                }
            }
        }
        let subscriptionMultiplier = Decimal(assumptions.subscriptionIncreasePercent) / 100
        let additionalSubscriptionCost = baselineSubscriptions.reduce(Decimal.zero, +)
            * subscriptionMultiplier
        let plannedSavings = assumptions.monthlySavings * Decimal(intervals.count)

        var baselineCumulative = Decimal.zero
        var scenarioCumulative = Decimal.zero
        let months = intervals.indices.map { index in
            let baselineNet = baselineIncome[index] - regularExpense - baselineSubscriptions[index]
            let scenarioNet = scenarioIncome[index]
                - (regularExpense - monthlySpendingSaved)
                - baselineSubscriptions[index] * (1 + subscriptionMultiplier)
                - assumptions.monthlySavings
            baselineCumulative += baselineNet
            scenarioCumulative += scenarioNet
            return FinancialTimeMachineMonth(
                start: intervals[index].start,
                baselineNetCashFlow: baselineNet,
                scenarioNetCashFlow: scenarioNet,
                baselineCumulativeCashFlow: baselineCumulative,
                scenarioCumulativeCashFlow: scenarioCumulative
            )
        }

        return FinancialTimeMachineReport(
            assumptions: assumptions,
            forecastPeriod: forecastPeriod,
            sampleMonthCount: samples.count,
            spendingSaved: spendingSaved,
            additionalSubscriptionCost: additionalSubscriptionCost,
            plannedSavings: plannedSavings,
            incomeShift: incomeShift,
            baselineEndingCashFlow: baselineCumulative,
            scenarioEndingCashFlow: scenarioCumulative,
            difference: scenarioCumulative - baselineCumulative,
            months: months
        )
    }

    private func samplePeriods(
        from transactions: [Transaction],
        asOf date: Date,
        calendar: Calendar
    ) -> [DateInterval] {
        let currentMonth = calendar.dateInterval(of: .month, for: date)
            ?? DateInterval(start: calendar.startOfDay(for: date), duration: 86_400)
        let completed = (1...3).compactMap { offset -> DateInterval? in
            guard let month = calendar.date(byAdding: .month, value: -offset, to: currentMonth.start) else {
                return nil
            }
            return calendar.dateInterval(of: .month, for: month)
        }
        let active = completed.filter { interval in
            transactions.contains { $0.date >= interval.start && $0.date < interval.end }
        }
        if !active.isEmpty { return active }

        guard transactions.contains(where: {
            $0.date >= currentMonth.start && $0.date <= date
        }) else { return [] }
        return [DateInterval(start: currentMonth.start, end: date.addingTimeInterval(1))]
    }

    private func projectedDate(in interval: DateInterval, day: Int, calendar: Calendar) -> Date {
        let days = calendar.range(of: .day, in: .month, for: interval.start)?.count ?? day
        var components = calendar.dateComponents([.year, .month], from: interval.start)
        components.day = min(day, days)
        return calendar.date(from: components) ?? interval.start
    }

    private func monthIndex(containing date: Date, intervals: [DateInterval]) -> Int? {
        intervals.firstIndex { date >= $0.start && date < $0.end }
    }

    private func sampleCountOrOne(_ count: Decimal) -> Decimal {
        max(count, 1)
    }
}

private struct IncomeTemplateKey: Hashable {
    let category: String
    let day: Int
}

private struct ProjectedIncomeEvent {
    let date: Date
    let categoryKey: String
    let category: String
    let amount: Decimal
}

#if DEBUG
extension SimulateFinancialTimeMachineUseCase {
    static func assertSelfCheck() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        func date(_ month: Int, _ day: Int) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: month, day: day)) ?? .distantPast
        }

        let transactions = (3...5).flatMap { month in
            [
                Transaction(amount: 1_000, kind: .income, category: "Salary", date: date(month, 28)),
                Transaction(amount: 200, kind: .expense, category: "Restaurants", date: date(month, 10)),
                Transaction(amount: 100, kind: .expense, category: "Music", date: date(month, 15))
            ]
        }
        let assumptions = FinancialTimeMachineAssumptions(
            spendingCategory: "restaurants",
            spendingReductionPercent: 15,
            incomeCategory: "salary",
            incomeDelayDays: 7,
            subscriptionIncreasePercent: 20,
            monthlySavings: 200,
            horizonMonths: 3
        )

        do {
            let report = try SimulateFinancialTimeMachineUseCase().execute(
                assumptions: assumptions,
                transactions: transactions,
                subscriptions: [
                    Subscription(name: "Music", amount: 100, nextChargeDate: date(7, 15), calendar: calendar)
                ],
                asOf: date(6, 30),
                calendar: calendar
            )

            assert(report.sampleMonthCount == 3)
            assert(report.spendingSaved == 90)
            assert(report.additionalSubscriptionCost == 60)
            assert(report.plannedSavings == 600)
            assert(report.incomeShift?.originalDate == date(7, 28))
            assert(report.incomeShift?.delayedDate == date(8, 4))
            assert(report.months.map(\.baselineCumulativeCashFlow) == [700, 1_400, 2_100])
            assert(report.months.map(\.scenarioCumulativeCashFlow) == [-490, 1_020, 1_530])
            assert(report.difference == -570)
        } catch {
            assertionFailure("Financial Time Machine self-check failed: \(error)")
        }
    }
}
#endif
