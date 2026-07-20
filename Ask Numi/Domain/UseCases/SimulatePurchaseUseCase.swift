//
//  SimulatePurchaseUseCase.swift
//  Ask Numi
//

import Foundation

enum PurchaseRecommendation: String, Equatable, Sendable {
    case buyNow
    case buyLater
    case skip
}

struct PurchaseBudgetImpact: Equatable, Sendable {
    let category: String
    let limit: Decimal
    let spentBeforePurchase: Decimal
    let projectedSpent: Decimal
    let overBy: Decimal
}

struct PurchaseGoalImpact: Equatable, Sendable {
    let name: String
    let originalTargetDate: Date
    let projectedTargetDate: Date
    let delayedByMonths: Int
}

struct PurchaseScenario: Equatable, Sendable {
    let date: Date?
    let scheduledPayments: Decimal
    let balanceAfterPurchaseAndPayments: Decimal
    let safePurchaseAmount: Decimal
    let budgetImpact: PurchaseBudgetImpact?
    let exceededBudgets: [PurchaseBudgetImpact]
    let goalImpact: PurchaseGoalImpact?
    let isSafe: Bool
}

struct PurchaseDecision: Equatable, Sendable {
    let amount: Decimal
    let desiredDate: Date
    let availableBalance: Decimal
    let category: String
    let currentMonthScheduledPayments: Decimal
    let remainingAfterCurrentMonthPayments: Decimal
    let safePurchaseAmount: Decimal
    let budgetImpact: PurchaseBudgetImpact?
    let exceededBudgets: [PurchaseBudgetImpact]
    let goalImpact: PurchaseGoalImpact?
    let betterDate: Date?
    let recommendation: PurchaseRecommendation
    let buyNow: PurchaseScenario
    let buyLater: PurchaseScenario
    let skip: PurchaseScenario
}

struct PurchaseDecisionReport: Sendable {
    let decision: PurchaseDecision
    let explanation: String?
}

struct SimulatePurchaseUseCase: Sendable {
    private let advisor: (any FinancialAdvisor)?

    init(advisor: (any FinancialAdvisor)? = nil) {
        self.advisor = advisor
    }

    func execute(
        amount: Decimal,
        desiredDate: Date,
        availableBalance: Decimal,
        category: String,
        transactions: [Transaction],
        budgets: [Budget],
        subscriptions: [Subscription],
        goals: [SavingsGoal],
        asOf date: Date = .now,
        calendar: Calendar = .current
    ) async throws -> PurchaseDecisionReport {
        let decision = try calculate(
            amount: amount,
            desiredDate: desiredDate,
            availableBalance: availableBalance,
            category: category,
            transactions: transactions,
            budgets: budgets,
            subscriptions: subscriptions,
            goals: goals,
            asOf: date,
            calendar: calendar
        )

        guard let advisor, advisor.availability == .available else {
            return PurchaseDecisionReport(decision: decision, explanation: nil)
        }

        let period = calendar.dateInterval(of: .month, for: date)
            ?? DateInterval(start: calendar.startOfDay(for: date), duration: 86_400)
        let summary = FinancialSummary(
            transactions: transactions.filter { period.contains($0.date) },
            period: period
        )
        let explanation = try? await advisor.advise(
            on: summary,
            question: nil,
            task: .purchaseDecision(decision)
        ).headline.trimmingCharacters(in: .whitespacesAndNewlines)

        return PurchaseDecisionReport(
            decision: decision,
            explanation: explanation?.isEmpty == false ? explanation : nil
        )
    }

    func calculate(
        amount: Decimal,
        desiredDate: Date,
        availableBalance: Decimal,
        category: String,
        transactions: [Transaction],
        budgets: [Budget],
        subscriptions: [Subscription],
        goals: [SavingsGoal],
        asOf date: Date = .now,
        calendar: Calendar = .current
    ) throws -> PurchaseDecision {
        let category = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let today = calendar.startOfDay(for: date)
        let desiredDate = calendar.startOfDay(for: desiredDate)
        guard amount > 0, availableBalance >= 0, !category.isEmpty else {
            throw DomainError.invalidAmount
        }
        guard desiredDate >= today else { throw DomainError.invalidDate }

        let currentMonth = calendar.dateInterval(of: .month, for: today)
            ?? DateInterval(start: today, duration: 86_400)
        let goal = goals
            .map { SavingsGoalProgress(goal: $0, asOf: today, calendar: calendar) }
            .filter { $0.state.isActive }
            .min { $0.goal.targetDate < $1.goal.targetDate }

        func scenario(on purchaseDate: Date?) -> PurchaseScenario {
            guard let purchaseDate else {
                let payments = scheduledPayments(
                    subscriptions: subscriptions,
                    from: today,
                    before: currentMonth.end,
                    calendar: calendar
                )
                return PurchaseScenario(
                    date: nil,
                    scheduledPayments: payments,
                    balanceAfterPurchaseAndPayments: availableBalance - payments,
                    safePurchaseAmount: 0,
                    budgetImpact: nil,
                    exceededBudgets: [],
                    goalImpact: nil,
                    isSafe: true
                )
            }

            let month = calendar.dateInterval(of: .month, for: purchaseDate)
                ?? DateInterval(start: purchaseDate, duration: 86_400)
            let payments = scheduledPayments(
                subscriptions: subscriptions,
                from: today,
                before: month.end,
                calendar: calendar
            )
            let cashAfterPayments = availableBalance - payments
            let protectedGoalContribution = goal?.monthlyContribution ?? 0
            let cashSafeAmount = max(cashAfterPayments - protectedGoalContribution, 0)
            let budgetImpact = budgetImpact(
                amount: amount,
                category: category,
                period: month,
                transactions: transactions,
                budgets: budgets
            )
            let budgetSafeAmount = budgetImpact.map {
                max($0.limit - $0.spentBeforePurchase, 0)
            } ?? cashSafeAmount
            let safeAmount = min(cashSafeAmount, budgetSafeAmount)
            let balanceAfterPurchase = cashAfterPayments - amount
            let delayedMonths = goal.map {
                balanceAfterPurchase < $0.monthlyContribution ? 1 : 0
            } ?? 0
            let goalImpact = goal.map { progress in
                PurchaseGoalImpact(
                    name: progress.goal.name,
                    originalTargetDate: progress.goal.targetDate,
                    projectedTargetDate: calendar.date(
                        byAdding: .month,
                        value: delayedMonths,
                        to: progress.goal.targetDate
                    ) ?? progress.goal.targetDate,
                    delayedByMonths: delayedMonths
                )
            }

            return PurchaseScenario(
                date: purchaseDate,
                scheduledPayments: payments,
                balanceAfterPurchaseAndPayments: balanceAfterPurchase,
                safePurchaseAmount: safeAmount,
                budgetImpact: budgetImpact,
                exceededBudgets: budgetImpact.map { $0.overBy > 0 ? [$0] : [] } ?? [],
                goalImpact: goalImpact,
                isSafe: amount <= safeAmount
            )
        }

        let buyNow = scenario(on: today)
        let desiredScenario = scenario(on: desiredDate)
        let firstLaterDate = desiredDate > today
            ? desiredDate
            : (calendar.date(byAdding: .month, value: 1, to: currentMonth.start) ?? desiredDate)
        var safeLaterScenario: PurchaseScenario?
        for offset in 0...12 {
            guard let candidate = offset == 0
                ? Optional(firstLaterDate)
                : calendar.date(byAdding: .month, value: offset, to: firstLaterDate)
            else { continue }
            let candidateScenario = scenario(on: candidate)
            if candidateScenario.isSafe {
                safeLaterScenario = candidateScenario
                break
            }
        }
        let buyLater = safeLaterScenario ?? scenario(on: firstLaterDate)
        let recommendation: PurchaseRecommendation = if buyNow.isSafe {
            .buyNow
        } else if safeLaterScenario != nil {
            .buyLater
        } else {
            .skip
        }
        let betterDate: Date? = switch recommendation {
        case .buyNow: today
        case .buyLater: buyLater.date
        case .skip: nil
        }
        let currentMonthPayments = scheduledPayments(
            subscriptions: subscriptions,
            from: today,
            before: currentMonth.end,
            calendar: calendar
        )

        return PurchaseDecision(
            amount: amount,
            desiredDate: desiredDate,
            availableBalance: availableBalance,
            category: category,
            currentMonthScheduledPayments: currentMonthPayments,
            remainingAfterCurrentMonthPayments: availableBalance - currentMonthPayments,
            safePurchaseAmount: desiredScenario.safePurchaseAmount,
            budgetImpact: desiredScenario.budgetImpact,
            exceededBudgets: desiredScenario.exceededBudgets,
            goalImpact: desiredScenario.goalImpact,
            betterDate: betterDate,
            recommendation: recommendation,
            buyNow: buyNow,
            buyLater: buyLater,
            skip: scenario(on: nil)
        )
    }

    private func budgetImpact(
        amount: Decimal,
        category: String,
        period: DateInterval,
        transactions: [Transaction],
        budgets: [Budget]
    ) -> PurchaseBudgetImpact? {
        let categoryKey = Budget.categoryKey(for: category)
        guard let budget = budgets.first(where: { $0.categoryKey == categoryKey }) else { return nil }
        let spent = transactions.reduce(Decimal.zero) { total, transaction in
            transaction.kind == .expense &&
                period.contains(transaction.date) &&
                Budget.categoryKey(for: transaction.category) == categoryKey
                ? total + transaction.amount
                : total
        }
        let projected = spent + amount
        return PurchaseBudgetImpact(
            category: budget.category,
            limit: budget.monthlyLimit,
            spentBeforePurchase: spent,
            projectedSpent: projected,
            overBy: max(projected - budget.monthlyLimit, 0)
        )
    }

    private func scheduledPayments(
        subscriptions: [Subscription],
        from start: Date,
        before end: Date,
        calendar: Calendar
    ) -> Decimal {
        subscriptions.reduce(Decimal.zero) { total, subscription in
            var amount = Decimal.zero
            var chargeDate = subscription.nextChargeDate
            while chargeDate < end && subscription.endDate.map({ chargeDate <= $0 }) != false {
                if chargeDate >= start { amount += subscription.amount }
                chargeDate = Subscription.followingChargeDate(
                    after: chargeDate,
                    billingDay: subscription.billingDay,
                    calendar: calendar
                )
            }
            return total + amount
        }
    }
}

#if DEBUG
extension SimulatePurchaseUseCase {
    static func assertSelfCheck() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        func date(_ month: Int, _ day: Int) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: month, day: day)) ?? .distantPast
        }

        let transactions = [
            Transaction(amount: 300, kind: .expense, category: "Groceries", date: date(7, 10))
        ]
        let subscriptions = [
            Subscription(name: "Phone", amount: 100, nextChargeDate: date(7, 25), calendar: calendar)
        ]
        let goals = [
            SavingsGoal(name: "Trip", targetAmount: 900, savedAmount: 300, targetDate: date(9, 30))
        ]
        let useCase = SimulatePurchaseUseCase()

        do {
            let later = try useCase.calculate(
                amount: 250,
                desiredDate: date(7, 20),
                availableBalance: 1_000,
                category: "groceries",
                transactions: transactions,
                budgets: [Budget(category: "Groceries", monthlyLimit: 500)],
                subscriptions: subscriptions,
                goals: goals,
                asOf: date(7, 20),
                calendar: calendar
            )
            assert(later.currentMonthScheduledPayments == 100)
            assert(later.remainingAfterCurrentMonthPayments == 900)
            assert(later.safePurchaseAmount == 200)
            assert(later.exceededBudgets.first?.overBy == 50)
            assert(later.recommendation == .buyLater)
            assert(later.betterDate == date(8, 1))

            let now = try useCase.calculate(
                amount: 150,
                desiredDate: date(7, 20),
                availableBalance: 1_000,
                category: "Groceries",
                transactions: transactions,
                budgets: [Budget(category: "Groceries", monthlyLimit: 500)],
                subscriptions: subscriptions,
                goals: goals,
                asOf: date(7, 20),
                calendar: calendar
            )
            assert(now.recommendation == .buyNow)
            assert(now.goalImpact?.delayedByMonths == 0)

            let skip = try useCase.calculate(
                amount: 900,
                desiredDate: date(7, 20),
                availableBalance: 1_000,
                category: "Groceries",
                transactions: transactions,
                budgets: [Budget(category: "Groceries", monthlyLimit: 500)],
                subscriptions: subscriptions,
                goals: goals,
                asOf: date(7, 20),
                calendar: calendar
            )
            assert(skip.recommendation == .skip)
            assert(skip.goalImpact?.delayedByMonths == 1)
        } catch {
            assertionFailure("Purchase simulator self-check failed: \(error)")
        }
    }
}
#endif
