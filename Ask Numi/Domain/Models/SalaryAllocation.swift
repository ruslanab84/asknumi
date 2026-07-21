//
//  SalaryAllocation.swift
//  Ask Numi
//

import Foundation

enum SalaryAllocationBucket: CaseIterable, Sendable {
    case requiredPayments
    case budgets
    case cushion
    case goals
    case freeMoney
}

enum SalaryAllocationBasis: Sendable {
    case payment(dueDate: Date)
    case budget(spent: Decimal, limit: Decimal)
    case goal(targetDate: Date, remaining: Decimal)
    case remainder
}

struct SalaryAllocationItem: Identifiable, Sendable {
    let id: String
    let name: String
    let amount: Decimal
    let basis: SalaryAllocationBasis
    let goalID: UUID?
}

struct SalaryAllocationProposal: Sendable {
    let income: Decimal
    let items: [SalaryAllocationBucket: [SalaryAllocationItem]]

    func amount(for bucket: SalaryAllocationBucket) -> Decimal {
        items[bucket, default: []].reduce(Decimal.zero) { $0 + $1.amount }
    }

    var goalContributions: [UUID: Decimal] {
        items.values.joined().reduce(into: [:]) { result, item in
            guard let goalID = item.goalID, item.amount > 0 else { return }
            result[goalID, default: 0] += item.amount
        }
    }
}

struct CalculateSalaryAllocationUseCase: Sendable {
    func execute(
        income: Transaction,
        transactions: [Transaction],
        subscriptions: [Subscription],
        budgets: [Budget],
        goals: [SavingsGoal],
        calendar: Calendar = .current
    ) -> SalaryAllocationProposal {
        precondition(income.kind == .income && income.amount > 0)

        let start = calendar.startOfDay(for: income.date)
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
        var available = currencyAmount(income.amount)

        func allocated(_ requested: Decimal) -> Decimal {
            let amount = min(max(currencyAmount(requested), 0), available)
            available -= amount
            return amount
        }

        let payments = subscriptions
            .flatMap { subscription in
                subscription.chargeDates(from: start, before: end, calendar: calendar).map {
                    (subscription, $0)
                }
            }
            .sorted { $0.1 < $1.1 }
            .map { subscription, dueDate in
                SalaryAllocationItem(
                    id: "payment-\(subscription.id)-\(dueDate.timeIntervalSinceReferenceDate)",
                    name: subscription.name,
                    amount: allocated(subscription.amount),
                    basis: .payment(dueDate: dueDate),
                    goalID: nil
                )
            }

        let overview = BudgetOverview(
            budgets: budgets,
            transactions: transactions,
            asOf: income.date,
            calendar: calendar
        )
        let budgetItems = overview.items
            .sorted { $0.budget.category.localizedStandardCompare($1.budget.category) == .orderedAscending }
            .map { progress in
                SalaryAllocationItem(
                    id: "budget-\(progress.id)",
                    name: progress.budget.category,
                    amount: allocated(max(progress.remaining, 0)),
                    basis: .budget(spent: progress.spent, limit: progress.budget.monthlyLimit),
                    goalID: nil
                )
            }

        let progress = goals
            .map { SavingsGoalProgress(goal: $0, asOf: income.date, calendar: calendar) }
            .filter { $0.state.isActive }
            .sorted { $0.goal.targetDate < $1.goal.targetDate }
        let cushion = goalItems(progress.filter { $0.goal.symbol == "shield.fill" }, available: &available)
        let goalItems = goalItems(progress.filter { $0.goal.symbol != "shield.fill" }, available: &available)
        let freeMoney = SalaryAllocationItem(
            id: "free-money",
            name: "",
            amount: available,
            basis: .remainder,
            goalID: nil
        )

        return SalaryAllocationProposal(
            income: currencyAmount(income.amount),
            items: [
                .requiredPayments: payments,
                .budgets: budgetItems,
                .cushion: cushion,
                .goals: goalItems,
                .freeMoney: [freeMoney]
            ]
        )
    }

    private func goalItems(
        _ progress: [SavingsGoalProgress],
        available: inout Decimal
    ) -> [SalaryAllocationItem] {
        progress.map { progress in
            let amount = min(max(currencyAmount(progress.monthlyContribution), 0), available)
            available -= amount
            return SalaryAllocationItem(
                id: "goal-\(progress.id)",
                name: progress.goal.name,
                amount: amount,
                basis: .goal(targetDate: progress.goal.targetDate, remaining: progress.remaining),
                goalID: progress.id
            )
        }
    }
}

private func currencyAmount(_ amount: Decimal) -> Decimal {
    var source = amount
    var rounded = Decimal.zero
    NSDecimalRound(&rounded, &source, 2, .bankers)
    return rounded
}

#if DEBUG
extension CalculateSalaryAllocationUseCase {
    static func assertSelfCheck() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let payday = calendar.date(from: DateComponents(year: 2026, month: 7, day: 22))!
        let dueDate = calendar.date(from: DateComponents(year: 2026, month: 7, day: 25))!
        let deadline = calendar.date(from: DateComponents(year: 2026, month: 9, day: 30))!
        let income = Transaction(amount: 1_000, kind: .income, category: "Salary", date: payday)
        let proposal = CalculateSalaryAllocationUseCase().execute(
            income: income,
            transactions: [income, Transaction(amount: 100, kind: .expense, category: "Food", date: payday)],
            subscriptions: [Subscription(name: "Rent", amount: 400, nextChargeDate: dueDate, calendar: calendar)],
            budgets: [Budget(category: "Food", monthlyLimit: 300)],
            goals: [
                SavingsGoal(name: "Cushion", symbol: "shield.fill", targetAmount: 600, targetDate: deadline),
                SavingsGoal(name: "Trip", targetAmount: 300, targetDate: deadline)
            ],
            calendar: calendar
        )

        assert(proposal.amount(for: .requiredPayments) == 400)
        assert(proposal.amount(for: .budgets) == 200)
        assert(proposal.amount(for: .cushion) == 200)
        assert(proposal.amount(for: .goals) == 100)
        assert(proposal.amount(for: .freeMoney) == 100)
        assert(proposal.items.values.joined().reduce(Decimal.zero) { $0 + $1.amount } == income.amount)
    }
}
#endif
