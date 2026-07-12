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
    var date: Date
    var note: String?

    nonisolated init(
        id: UUID = UUID(),
        amount: Decimal,
        kind: TransactionKind,
        category: String,
        categoryIcon: String = CategoryIcon.fallback,
        date: Date = .now,
        note: String? = nil
    ) {
        self.id = id
        self.amount = amount
        self.kind = kind
        self.category = category
        self.categoryIcon = categoryIcon
        self.date = date
        self.note = note
    }
}
