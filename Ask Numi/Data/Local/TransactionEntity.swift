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
    var fundingSourceRaw: String?
    var date: Date
    var note: String?
    var isImpulse: Bool?
    var receiptID: UUID?
    var receiptItemName: String?
    var receiptQuantity: Decimal?
    var receiptUnitPrice: Decimal?

    init(
        id: UUID,
        amount: Decimal,
        kindRaw: String,
        categoryRaw: String,
        categoryIconRaw: String?,
        categoryColorRaw: String?,
        fundingSourceRaw: String?,
        date: Date,
        note: String?,
        isImpulse: Bool?,
        receiptID: UUID?,
        receiptItemName: String?,
        receiptQuantity: Decimal?,
        receiptUnitPrice: Decimal?
    ) {
        self.id = id
        self.amount = amount
        self.kindRaw = kindRaw
        self.categoryRaw = categoryRaw
        self.categoryIconRaw = categoryIconRaw
        self.categoryColorRaw = categoryColorRaw
        self.fundingSourceRaw = fundingSourceRaw
        self.date = date
        self.note = note
        self.isImpulse = isImpulse
        self.receiptID = receiptID
        self.receiptItemName = receiptItemName
        self.receiptQuantity = receiptQuantity
        self.receiptUnitPrice = receiptUnitPrice
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
            fundingSourceRaw: transaction.fundingSource,
            date: transaction.date,
            note: transaction.note,
            isImpulse: transaction.isImpulse,
            receiptID: transaction.receiptItem?.receiptID,
            receiptItemName: transaction.receiptItem?.name,
            receiptQuantity: transaction.receiptItem?.quantity,
            receiptUnitPrice: transaction.receiptItem?.unitPrice
        )
    }

    /// `nil` when the stored kind is unrecognized (corrupt row) —
    /// callers drop such rows via `compactMap`.
    func toDomain() -> Transaction? {
        guard let kind = TransactionKind(rawValue: kindRaw) else { return nil }
        let receiptItem: ReceiptItem?
        if let receiptID, let receiptItemName, let receiptQuantity, let receiptUnitPrice {
            receiptItem = ReceiptItem(
                receiptID: receiptID,
                name: receiptItemName,
                quantity: receiptQuantity,
                unitPrice: receiptUnitPrice
            )
        } else {
            receiptItem = nil
        }
        return Transaction(
            id: id,
            amount: amount,
            kind: kind,
            category: categoryRaw,
            categoryIcon: categoryIconRaw ?? CategoryIcon.suggested(for: categoryRaw, kind: kind),
            categoryColor: categoryColorRaw.flatMap(CategoryColor.init(rawValue:)),
            fundingSource: fundingSourceRaw,
            date: date,
            note: note,
            isImpulse: isImpulse ?? false,
            receiptItem: receiptItem
        )
    }
}

#if DEBUG
extension TransactionEntity {
    static func assertSelfCheck() {
        let receiptID = UUID()
        let transaction = Transaction(
            amount: 3,
            kind: .expense,
            category: "Groceries",
            note: "Milk",
            receiptItem: ReceiptItem(receiptID: receiptID, name: "Milk", quantity: 2, unitPrice: 1.5)
        )
        let restored = TransactionEntity(transaction).toDomain()
        assert(restored?.receiptItem?.receiptID == receiptID)
        assert(restored?.receiptItem?.name == "Milk")
        assert(restored?.receiptItem?.quantity == 2)
        assert(restored?.receiptItem?.unitPrice == 1.5)
    }
}
#endif
