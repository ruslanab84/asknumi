//
//  FinancialTwin.swift
//  Ask Numi
//

import Foundation

struct FinancialTwinReport: Sendable {
    let insights: [FinancialTwinInsight]
    let transactionCount: Int
    let budgetCount: Int
    let subscriptionCount: Int

    nonisolated static let empty = FinancialTwinReport(
        insights: [],
        transactionCount: 0,
        budgetCount: 0,
        subscriptionCount: 0
    )
}

enum FinancialTwinInsight: Sendable, Identifiable {
    enum Kind: String, Sendable {
        case cashFlowSnapshot
        case paydaySpending
        case impulseTiming
        case budgetOverrun
        case monthEndBalance
        case unplannedRecurring
    }

    case cashFlowSnapshot(CashFlowSnapshotInsight)
    case paydaySpending(PaydaySpendingInsight)
    case impulseTiming(ImpulseTimingInsight)
    case budgetOverrun(BudgetOverrunInsight)
    case monthEndBalance(MonthEndBalanceInsight)
    case unplannedRecurring(UnplannedRecurringInsight)

    nonisolated var id: Kind {
        switch self {
        case .cashFlowSnapshot: .cashFlowSnapshot
        case .paydaySpending: .paydaySpending
        case .impulseTiming: .impulseTiming
        case .budgetOverrun: .budgetOverrun
        case .monthEndBalance: .monthEndBalance
        case .unplannedRecurring: .unplannedRecurring
        }
    }
}

struct CashFlowSnapshotInsight: Sendable {
    let totalIncome: Decimal
    let totalExpenses: Decimal
    let balance: Decimal
    let transactionCount: Int
    let topExpenseCategory: String?
    let topExpenseAmount: Decimal
    let topExpenseSharePercent: Int
}

struct FinancialTwinTransactionSample: Sendable {
    let date: Date
    let amount: Decimal
}

enum FinancialTwinDayPart: String, Hashable, Sendable {
    case morning
    case afternoon
    case evening
    case night
}

struct ImpulseTimingInsight: Sendable {
    let weekday: Int
    let dayPart: FinancialTwinDayPart
    let matchingCount: Int
    let totalCount: Int
    let matchingAmount: Decimal
    let samples: [FinancialTwinTransactionSample]
}

struct PaydaySpendingInsight: Sendable {
    let category: String
    let increasePercent: Int
    let paydayCount: Int
    let firstFiveDayAverage: Decimal
    let baselineFiveDayAverage: Decimal
    let paydayDates: [Date]
}

struct BudgetCrossing: Sendable {
    let category: String
    let limit: Decimal
    let date: Date
    let spentAtCrossing: Decimal
}

struct BudgetOverrunInsight: Sendable {
    let crossings: [BudgetCrossing]
}

struct MonthEndSample: Sendable {
    let month: Date
    let income: Decimal
    let expenses: Decimal
    let balance: Decimal
}

struct MonthEndBalanceInsight: Sendable {
    let medianBalance: Decimal
    let samples: [MonthEndSample]
}

struct RecurringExpenseCandidate: Sendable {
    let name: String
    let typicalAmount: Decimal
    let occurrenceCount: Int
    let samples: [FinancialTwinTransactionSample]
}

struct UnplannedRecurringInsight: Sendable {
    let candidates: [RecurringExpenseCandidate]
}
