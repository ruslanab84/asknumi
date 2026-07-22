//
//  CalculateSafeToSpendUseCase.swift
//  Ask Numi
//

import Foundation

enum SafeToSpendMissingInput: CaseIterable, Equatable, Sendable {
    case currentBalance
    case expectedIncome
    case reserve
    case payday
    case scheduledPayments
    case goals
}

struct SafeToSpendResult: Sendable {
    let payday: Date?
    let daysRemaining: Int?
    let total: Decimal?
    let perDay: Decimal?
    let scheduledPayments: Decimal
    let protectedGoals: Decimal
    let missingInputs: [SafeToSpendMissingInput]
}

struct CalculateSafeToSpendUseCase: Sendable {
    func execute(
        currentBalance: Decimal?,
        expectedIncome: Decimal?,
        reserve: Decimal?,
        payday: Date?,
        subscriptions: [Subscription]?,
        goals: [SavingsGoal]?,
        asOf date: Date = .now,
        calendar: Calendar = .current
    ) -> SafeToSpendResult {
        let today = calendar.startOfDay(for: date)
        let payday = payday.map { calendar.startOfDay(for: $0) }
        let missingInputs = SafeToSpendMissingInput.allCases.filter { input in
            switch input {
            case .currentBalance: currentBalance.map { $0 < 0 } ?? true
            case .expectedIncome: expectedIncome.map { $0 < 0 } ?? true
            case .reserve: reserve.map { $0 < 0 } ?? true
            case .payday: payday.map { $0 < today } ?? true
            case .scheduledPayments: subscriptions == nil
            case .goals: goals == nil
            }
        }

        guard
            missingInputs.isEmpty,
            let currentBalance,
            let expectedIncome,
            let reserve,
            let payday,
            let subscriptions,
            let goals,
            let end = calendar.date(byAdding: .day, value: 1, to: payday)
        else {
            return SafeToSpendResult(
                payday: payday,
                daysRemaining: nil,
                total: nil,
                perDay: nil,
                scheduledPayments: 0,
                protectedGoals: 0,
                missingInputs: missingInputs
            )
        }

        let scheduledPayments = subscriptions.reduce(Decimal.zero) { total, subscription in
            total + Decimal(subscription.chargeDates(from: today, before: end, calendar: calendar).count)
                * subscription.amount
        }
        let protectedGoals = SavingsGoalsOverview(
            goals: goals,
            transactions: [],
            asOf: today,
            calendar: calendar
        ).monthlyNeeded
        let daysRemaining = max(
            (calendar.dateComponents([.day], from: today, to: payday).day ?? 0) + 1,
            1
        )
        let total = max(
            currentBalance + expectedIncome - scheduledPayments - reserve - protectedGoals,
            0
        )

        return SafeToSpendResult(
            payday: payday,
            daysRemaining: daysRemaining,
            total: total,
            perDay: total / Decimal(daysRemaining),
            scheduledPayments: scheduledPayments,
            protectedGoals: protectedGoals,
            missingInputs: []
        )
    }
}

#if DEBUG
extension CalculateSafeToSpendUseCase {
    static func assertSelfCheck() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        func date(_ day: Int) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: 7, day: day)) ?? .distantPast
        }

        let result = CalculateSafeToSpendUseCase().execute(
            currentBalance: 400,
            expectedIncome: 100,
            reserve: 100,
            payday: date(31),
            subscriptions: [
                Subscription(name: "Loan", amount: 100, nextChargeDate: date(25), calendar: calendar)
            ],
            goals: [
                SavingsGoal(name: "Trip", targetAmount: 200, targetDate: date(31))
            ],
            asOf: date(22),
            calendar: calendar
        )
        assert(result.daysRemaining == 10)
        assert(result.scheduledPayments == 100)
        assert(result.protectedGoals == 200)
        assert(result.total == 100)
        assert(result.perDay == 10)

        let protected = CalculateSafeToSpendUseCase().execute(
            currentBalance: 50,
            expectedIncome: 0,
            reserve: 100,
            payday: date(22),
            subscriptions: [],
            goals: [],
            asOf: date(22),
            calendar: calendar
        )
        assert(protected.total == 0)
        assert(protected.perDay == 0)

        let missing = CalculateSafeToSpendUseCase().execute(
            currentBalance: nil,
            expectedIncome: nil,
            reserve: nil,
            payday: nil,
            subscriptions: [],
            goals: [],
            asOf: date(22),
            calendar: calendar
        )
        assert(missing.missingInputs == [.currentBalance, .expectedIncome, .reserve, .payday])
        assert(missing.perDay == nil)

        let unavailable = CalculateSafeToSpendUseCase().execute(
            currentBalance: 100,
            expectedIncome: 0,
            reserve: 0,
            payday: date(31),
            subscriptions: nil,
            goals: nil,
            asOf: date(22),
            calendar: calendar
        )
        assert(unavailable.missingInputs == [.scheduledPayments, .goals])
        assert(unavailable.perDay == nil)
    }
}
#endif
