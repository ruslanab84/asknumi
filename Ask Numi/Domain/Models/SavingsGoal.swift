//
//  SavingsGoal.swift
//  Ask Numi
//

import Foundation

struct SavingsGoal: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var symbol: String
    var targetAmount: Decimal
    var savedAmount: Decimal
    var targetDate: Date

    nonisolated init(
        id: UUID = UUID(),
        name: String,
        symbol: String = "target",
        targetAmount: Decimal,
        savedAmount: Decimal = 0,
        targetDate: Date
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.targetAmount = targetAmount
        self.savedAmount = savedAmount
        self.targetDate = targetDate
    }
}

enum SavingsGoalState: Sendable {
    case active
    case overdue
    case complete

    nonisolated var isActive: Bool {
        if case .active = self { true } else { false }
    }

    nonisolated var isComplete: Bool {
        if case .complete = self { true } else { false }
    }

    nonisolated var isOverdue: Bool {
        if case .overdue = self { true } else { false }
    }
}

struct SavingsGoalProgress: Identifiable, Sendable {
    let goal: SavingsGoal
    let remaining: Decimal
    let fractionComplete: Double
    let monthsRemaining: Int
    let monthlyContribution: Decimal
    let state: SavingsGoalState

    nonisolated var id: UUID { goal.id }

    nonisolated init(
        goal: SavingsGoal,
        asOf date: Date = .now,
        calendar: Calendar = .current
    ) {
        let saved = max(goal.savedAmount, 0)
        let target = max(goal.targetAmount, 0)
        let remaining = max(target - saved, 0)
        let today = calendar.startOfDay(for: date)
        let deadline = calendar.startOfDay(for: goal.targetDate)

        let state: SavingsGoalState
        if remaining == 0 {
            state = .complete
        } else if deadline < today {
            state = .overdue
        } else {
            state = .active
        }

        let currentMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today
        let deadlineMonth = calendar.dateInterval(of: .month, for: deadline)?.start ?? deadline
        let monthDistance = calendar.dateComponents([.month], from: currentMonth, to: deadlineMonth).month ?? 0
        let monthsRemaining = state.isActive ? max(monthDistance + 1, 1) : 0

        self.goal = goal
        self.remaining = remaining
        fractionComplete = target > 0
            ? NSDecimalNumber(decimal: saved / target).doubleValue
            : 0
        self.monthsRemaining = monthsRemaining
        monthlyContribution = monthsRemaining > 0 ? remaining / Decimal(monthsRemaining) : 0
        self.state = state
    }
}

enum SavingsPlanHealth: Sendable {
    case complete
    case noHistory
    case feasible
    case strained

    nonisolated var isFeasible: Bool {
        if case .feasible = self { true } else { false }
    }
}

/// Goal math plus a reality check against the last three completed months of recorded cash flow.
struct SavingsGoalsOverview: Sendable {
    let items: [SavingsGoalProgress]
    let totalSaved: Decimal
    let totalTarget: Decimal
    let monthlyNeeded: Decimal
    let averageMonthlySurplus: Decimal?
    let monthlyGap: Decimal?
    let hasOverdueGoals: Bool
    let health: SavingsPlanHealth

    nonisolated init(
        goals: [SavingsGoal],
        transactions: [Transaction],
        asOf date: Date = .now,
        calendar: Calendar = .current
    ) {
        let progress = goals
            .map { SavingsGoalProgress(goal: $0, asOf: date, calendar: calendar) }
            .sorted { lhs, rhs in
                if lhs.state.isComplete != rhs.state.isComplete {
                    return !lhs.state.isComplete
                }
                return lhs.goal.targetDate < rhs.goal.targetDate
            }
        let monthlyNeeded = progress.reduce(Decimal.zero) { partial, item in
            item.state.isActive ? partial + item.monthlyContribution : partial
        }
        let hasOverdueGoals = progress.contains { $0.state.isOverdue }

        let currentMonth = calendar.dateInterval(of: .month, for: date)?.start
            ?? calendar.startOfDay(for: date)
        let monthlyNets = (1...3).compactMap { offset -> Decimal? in
            guard
                let month = calendar.date(byAdding: .month, value: -offset, to: currentMonth),
                let interval = calendar.dateInterval(of: .month, for: month)
            else { return nil }

            var net = Decimal.zero
            var hasActivity = false
            for transaction in transactions where transaction.date >= interval.start && transaction.date < interval.end {
                hasActivity = true
                net += transaction.kind == .income ? transaction.amount : -transaction.amount
            }
            return hasActivity ? net : nil
        }
        let averageMonthlySurplus = monthlyNets.isEmpty
            ? nil
            : monthlyNets.reduce(Decimal.zero, +) / Decimal(monthlyNets.count)
        let usableSurplus = max(averageMonthlySurplus ?? 0, 0)

        let health: SavingsPlanHealth
        if progress.allSatisfy({ $0.state.isComplete }) {
            health = .complete
        } else if hasOverdueGoals {
            health = .strained
        } else if averageMonthlySurplus == nil {
            health = .noHistory
        } else if monthlyNeeded <= usableSurplus {
            health = .feasible
        } else {
            health = .strained
        }

        self.items = progress
        totalSaved = goals.reduce(Decimal.zero) { $0 + max($1.savedAmount, 0) }
        totalTarget = goals.reduce(Decimal.zero) { $0 + max($1.targetAmount, 0) }
        self.monthlyNeeded = monthlyNeeded
        self.averageMonthlySurplus = averageMonthlySurplus
        monthlyGap = averageMonthlySurplus.map { max(monthlyNeeded - max($0, 0), 0) }
        self.hasOverdueGoals = hasOverdueGoals
        self.health = health
    }
}

#if DEBUG
extension SavingsGoalsOverview {
    nonisolated static func assertSelfCheck() {
        var calendar = Calendar(identifier: .gregorian)
        if let utc = TimeZone(secondsFromGMT: 0) {
            calendar.timeZone = utc
        }
        guard
            let today = calendar.date(from: DateComponents(year: 2026, month: 7, day: 13)),
            let deadline = calendar.date(from: DateComponents(year: 2026, month: 9, day: 30)),
            let june = calendar.date(from: DateComponents(year: 2026, month: 6, day: 10))
        else {
            assertionFailure("Could not create SavingsGoalsOverview self-check dates")
            return
        }

        let goal = SavingsGoal(
            name: "Emergency fund",
            targetAmount: 900,
            savedAmount: 300,
            targetDate: deadline
        )
        let overview = SavingsGoalsOverview(
            goals: [goal],
            transactions: [
                Transaction(amount: 1_200, kind: .income, category: "Salary", date: june),
                Transaction(amount: 700, kind: .expense, category: "Living", date: june)
            ],
            asOf: today,
            calendar: calendar
        )

        assert(overview.items.first?.monthsRemaining == 3)
        assert(overview.monthlyNeeded == 200)
        assert(overview.averageMonthlySurplus == 500)
        assert(overview.health.isFeasible)
    }
}
#endif
