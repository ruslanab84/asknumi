//
//  TransactionEntity.swift
//  Ask Numi
//
//  SwiftData persistence model. Never leaves the Data layer —
//  repositories map it to/from the domain `Transaction`.
//

import Foundation
import SwiftData

@Model
final class TransactionEntity {
    @Attribute(.unique) var id: UUID
    var amount: Decimal
    var kindRaw: String
    var categoryRaw: String
    var categoryIconRaw: String?
    var categoryColorRaw: String?
    var date: Date
    var note: String?

    init(
        id: UUID,
        amount: Decimal,
        kindRaw: String,
        categoryRaw: String,
        categoryIconRaw: String?,
        categoryColorRaw: String?,
        date: Date,
        note: String?
    ) {
        self.id = id
        self.amount = amount
        self.kindRaw = kindRaw
        self.categoryRaw = categoryRaw
        self.categoryIconRaw = categoryIconRaw
        self.categoryColorRaw = categoryColorRaw
        self.date = date
        self.note = note
    }
}

extension TransactionEntity {
    convenience init(_ transaction: Transaction) {
        self.init(
            id: transaction.id,
            amount: transaction.amount,
            kindRaw: transaction.kind.rawValue,
            categoryRaw: transaction.category,
            categoryIconRaw: transaction.categoryIcon,
            categoryColorRaw: transaction.categoryColor.rawValue,
            date: transaction.date,
            note: transaction.note
        )
    }

    /// `nil` when the stored kind is unrecognized (corrupt row) —
    /// callers drop such rows via `compactMap`.
    func toDomain() -> Transaction? {
        guard let kind = TransactionKind(rawValue: kindRaw) else { return nil }
        return Transaction(
            id: id,
            amount: amount,
            kind: kind,
            category: categoryRaw,
            categoryIcon: categoryIconRaw ?? CategoryIcon.suggested(for: categoryRaw, kind: kind),
            categoryColor: categoryColorRaw.flatMap(CategoryColor.init(rawValue:)),
            date: date,
            note: note
        )
    }
}
