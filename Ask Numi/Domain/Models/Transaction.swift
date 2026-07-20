//
//  Transaction.swift
//  Ask Numi
//

import Foundation

enum TransactionKind: String, Codable, CaseIterable, Sendable {
    case income
    case expense
}

struct ReceiptItem: Hashable, Sendable {
    let receiptID: UUID
    var name: String
    var quantity: Decimal
    var unitPrice: Decimal

    nonisolated init(receiptID: UUID, name: String, quantity: Decimal, unitPrice: Decimal) {
        self.receiptID = receiptID
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.quantity = quantity
        self.unitPrice = unitPrice
    }

    nonisolated var total: Decimal { quantity * unitPrice }
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
    var receiptItem: ReceiptItem?

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
        isImpulse: Bool = false,
        receiptItem: ReceiptItem? = nil
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
        self.receiptItem = kind == .expense ? receiptItem : nil
    }

    nonisolated var hasValidReceiptItem: Bool {
        guard let receiptItem else { return true }
        return !receiptItem.name.isEmpty &&
            receiptItem.quantity > 0 &&
            receiptItem.unitPrice > 0 &&
            receiptItem.total == amount
    }

    nonisolated static func assertSelfCheck() {
        assert(Transaction(amount: 1, kind: .expense, category: "Food", fundingSource: " Card ").fundingSource == "Card")
        assert(Transaction(amount: 1, kind: .income, category: "Salary", fundingSource: "Card").fundingSource == nil)
        let item = ReceiptItem(receiptID: UUID(), name: " Milk ", quantity: 2, unitPrice: 1.25)
        assert(item.name == "Milk" && item.total == 2.5)
        assert(Transaction(amount: 2.5, kind: .expense, category: "Food", receiptItem: item).hasValidReceiptItem)
        assert(Transaction(amount: 3, kind: .expense, category: "Food", receiptItem: item).hasValidReceiptItem == false)
        let income = Transaction(amount: 2.5, kind: .income, category: "Salary", receiptItem: item)
        assert(income.receiptItem.map { _ in false } ?? true)
    }
}
