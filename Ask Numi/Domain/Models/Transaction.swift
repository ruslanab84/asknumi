//
//  Transaction.swift
//  Ask Numi
//

import Foundation

enum TransactionKind: String, Codable, CaseIterable, Sendable {
    case income
    case expense
}

struct Transaction: Identifiable, Hashable, Sendable {
    let id: UUID
    var amount: Decimal        // always positive; `kind` defines direction
    var kind: TransactionKind
    var category: String
    var categoryIcon: String
    var categoryColor: CategoryColor
    var fundingSource: String?
    var date: Date
    var note: String?
    var isImpulse: Bool

    nonisolated init(
        id: UUID = UUID(),
        amount: Decimal,
        kind: TransactionKind,
        category: String,
        categoryIcon: String = CategoryIcon.fallback,
        categoryColor: CategoryColor? = nil,
        fundingSource: String? = nil,
        date: Date = .now,
        note: String? = nil,
        isImpulse: Bool = false
    ) {
        self.id = id
        self.amount = amount
        self.kind = kind
        self.category = category
        self.categoryIcon = categoryIcon
        self.categoryColor = categoryColor ?? CategoryColor.defaultColor(for: kind)
        let trimmedFundingSource = fundingSource?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.fundingSource = kind == .expense && !(trimmedFundingSource?.isEmpty ?? true)
            ? trimmedFundingSource
            : nil
        self.date = date
        self.note = note
        self.isImpulse = isImpulse
    }

    nonisolated static func assertSelfCheck() {
        assert(Transaction(amount: 1, kind: .expense, category: "Food", fundingSource: " Card ").fundingSource == "Card")
        assert(Transaction(amount: 1, kind: .income, category: "Salary", fundingSource: "Card").fundingSource == nil)
    }
}
