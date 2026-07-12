//
//  Transaction.swift
//  Ask Numi
//

import Foundation

enum TransactionKind: String, Codable, CaseIterable, Sendable {
    case income
    case expense
}

enum TransactionCategory: String, Codable, CaseIterable, Sendable {
    case salary
    case business
    case gifts
    case groceries
    case restaurants
    case transport
    case housing
    case utilities
    case health
    case entertainment
    case shopping
    case education
    case other
}

struct Transaction: Identifiable, Hashable, Sendable {
    let id: UUID
    var amount: Decimal        // always positive; `kind` defines direction
    var kind: TransactionKind
    var category: TransactionCategory
    var date: Date
    var note: String?

    init(
        id: UUID = UUID(),
        amount: Decimal,
        kind: TransactionKind,
        category: TransactionCategory,
        date: Date = .now,
        note: String? = nil
    ) {
        self.id = id
        self.amount = amount
        self.kind = kind
        self.category = category
        self.date = date
        self.note = note
    }
}
