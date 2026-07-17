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
        self.date = date
        self.note = note
        self.isImpulse = isImpulse
    }
}
