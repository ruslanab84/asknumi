//
//  ReceiptPriceInsights.swift
//  Ask Numi
//

import Foundation

struct ReceiptBasketPriceChange: Sendable {
    let previousTotal: Decimal
    let currentTotal: Decimal
    let percent: Int
    let itemCount: Int
}

struct ReceiptProductPriceIncrease: Identifiable, Sendable {
    let name: String
    let increaseCount: Int
    let addedCost: Decimal

    var id: String { ReceiptPriceInsights.normalizedName(name) }
}

struct ReceiptPriceComparison: Sendable {
    let previousUnitPrice: Decimal
    let currentUnitPrice: Decimal
    let percent: Int

    nonisolated var shouldVerify: Bool { abs(percent) >= 30 }
}

struct ReceiptPriceInsights: Sendable {
    let basketChange: ReceiptBasketPriceChange?
    let topIncreasingItems: [ReceiptProductPriceIncrease]
    private let latestUnitPrices: [String: Decimal]

    var hasInsights: Bool {
        basketChange != nil || !topIncreasingItems.isEmpty
    }

    nonisolated init(transactions: [Transaction]) {
        let points = transactions.compactMap { transaction -> ReceiptPricePoint? in
            guard let item = transaction.receiptItem,
                  item.quantity > 0,
                  item.unitPrice > 0
            else { return nil }
            return ReceiptPricePoint(
                receiptID: item.receiptID,
                name: item.name,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                date: transaction.date
            )
        }

        let histories = Dictionary(grouping: points, by: { Self.normalizedName($0.name) })
            .mapValues(Self.receiptObservations)
        var latestUnitPrices: [String: Decimal] = [:]
        var basketPairs: [(previous: Decimal, current: Decimal)] = []
        var increases: [ReceiptProductPriceIncrease] = []

        for (key, history) in histories where !key.isEmpty {
            guard let latest = history.last else { continue }
            latestUnitPrices[key] = latest.unitPrice

            if history.count >= 2 {
                basketPairs.append((history[history.count - 2].unitPrice, latest.unitPrice))
            }

            var increaseCount = 0
            var addedCost: Decimal = 0
            for (previous, current) in zip(history, history.dropFirst()) where current.unitPrice > previous.unitPrice {
                increaseCount += 1
                addedCost += (current.unitPrice - previous.unitPrice) * current.quantity
            }
            if increaseCount > 0 {
                increases.append(ReceiptProductPriceIncrease(
                    name: latest.name,
                    increaseCount: increaseCount,
                    addedCost: addedCost
                ))
            }
        }

        if basketPairs.count >= 2 {
            let previousTotal = basketPairs.reduce(Decimal.zero) { $0 + $1.previous }
            let currentTotal = basketPairs.reduce(Decimal.zero) { $0 + $1.current }
            basketChange = ReceiptBasketPriceChange(
                previousTotal: previousTotal,
                currentTotal: currentTotal,
                percent: Self.percent(from: previousTotal, to: currentTotal),
                itemCount: basketPairs.count
            )
        } else {
            basketChange = nil
        }

        topIncreasingItems = increases
            .sorted {
                if $0.increaseCount != $1.increaseCount { return $0.increaseCount > $1.increaseCount }
                if $0.addedCost != $1.addedCost { return $0.addedCost > $1.addedCost }
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
            .prefix(3)
            .map { $0 }
        self.latestUnitPrices = latestUnitPrices
    }

    nonisolated func comparison(for name: String, currentUnitPrice: Decimal) -> ReceiptPriceComparison? {
        guard currentUnitPrice > 0,
              let previous = latestUnitPrices[Self.normalizedName(name)]
        else { return nil }
        return ReceiptPriceComparison(
            previousUnitPrice: previous,
            currentUnitPrice: currentUnitPrice,
            percent: Self.percent(from: previous, to: currentUnitPrice)
        )
    }

    nonisolated static func normalizedName(_ name: String) -> String {
        name
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
            .joined(separator: " ")
    }

    private nonisolated static func receiptObservations(_ points: [ReceiptPricePoint]) -> [ReceiptPricePoint] {
        Dictionary(grouping: points, by: \.receiptID)
            .compactMap { _, receiptPoints in
                guard let sample = receiptPoints.max(by: { $0.date < $1.date }) else { return nil }
                let quantity = receiptPoints.reduce(Decimal.zero) { $0 + $1.quantity }
                guard quantity > 0 else { return nil }
                let total = receiptPoints.reduce(Decimal.zero) { $0 + $1.quantity * $1.unitPrice }
                return ReceiptPricePoint(
                    receiptID: sample.receiptID,
                    name: sample.name,
                    quantity: quantity,
                    unitPrice: total / quantity,
                    date: sample.date
                )
            }
            .sorted { $0.date < $1.date }
    }

    private nonisolated static func percent(from previous: Decimal, to current: Decimal) -> Int {
        guard previous > 0 else { return 0 }
        return Int((NSDecimalNumber(decimal: (current - previous) / previous * 100).doubleValue).rounded())
    }
}

private struct ReceiptPricePoint: Sendable {
    let receiptID: UUID
    let name: String
    let quantity: Decimal
    let unitPrice: Decimal
    let date: Date
}

#if DEBUG
extension ReceiptPriceInsights {
    nonisolated static func assertSelfCheck() {
        let firstReceipt = UUID()
        let secondReceipt = UUID()
        let firstDate = Date(timeIntervalSince1970: 1)
        let secondDate = Date(timeIntervalSince1970: 2)

        func transaction(_ name: String, _ price: Decimal, receiptID: UUID, date: Date) -> Transaction {
            Transaction(
                amount: price,
                kind: .expense,
                category: "Groceries",
                date: date,
                note: name,
                receiptItem: ReceiptItem(receiptID: receiptID, name: name, quantity: 1, unitPrice: price)
            )
        }

        let insights = ReceiptPriceInsights(transactions: [
            transaction("Milk", 1, receiptID: firstReceipt, date: firstDate),
            transaction("Bread", 2, receiptID: firstReceipt, date: firstDate),
            transaction("MILK", Decimal(string: "1.20")!, receiptID: secondReceipt, date: secondDate),
            transaction("Bread", Decimal(string: "2.20")!, receiptID: secondReceipt, date: secondDate)
        ])

        assert(insights.basketChange?.itemCount == 2)
        assert(insights.basketChange?.percent == 13)
        assert(insights.topIncreasingItems.count == 2)
        assert(insights.comparison(for: " milk ", currentUnitPrice: 2)?.shouldVerify == true)
    }
}
#endif
