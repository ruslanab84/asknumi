//
//  ReceiptImportService.swift
//  Ask Numi
//

import Foundation
import UIKit
import Vision

struct ReceiptExpenseDraft: Equatable, Sendable {
    let name: String
    let quantity: Decimal
    let unitPrice: Decimal
    let category: ClassifiedTransactionCategory

    var amount: Decimal { quantity * unitPrice }
}

enum ReceiptImportError: Error {
    case unreadableImage
    case noLineItems
}

struct ReceiptImportService {
    private let classifier: any TransactionClassifier

    init(classifier: any TransactionClassifier) {
        self.classifier = classifier
    }

    func expenses(from images: [UIImage]) async throws -> [ReceiptExpenseDraft] {
        var lines: [String] = []

        for image in images {
            try Task.checkCancellation()
            guard let cgImage = image.cgImage else { throw ReceiptImportError.unreadableImage }

            var request = RecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.automaticallyDetectsLanguage = true
            request.usesLanguageCorrection = true

            let observations = try await request.perform(on: cgImage)
            lines.append(contentsOf: Self.reconstructedLines(from: observations))
        }

        let receipt = ReceiptLineItemParser.parse(lines)
        guard !receipt.items.isEmpty else { throw ReceiptImportError.noLineItems }

        let merchantCategory: ClassifiedTransactionCategory?
        if let merchant = receipt.merchant {
            merchantCategory = await classifier.classify(text: merchant)?.category
        } else {
            merchantCategory = nil
        }

        var expenses: [ReceiptExpenseDraft] = []
        expenses.reserveCapacity(receipt.items.count)

        for item in receipt.items {
            try Task.checkCancellation()
            let predicted = await classifier.classify(text: item.name)?.category ?? merchantCategory ?? .other
            expenses.append(ReceiptExpenseDraft(
                name: item.name,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                category: predicted == .income ? .other : predicted
            ))
        }

        return expenses
    }

    private static func reconstructedLines(from observations: [RecognizedTextObservation]) -> [String] {
        let fragments = observations.compactMap { observation -> ReceiptTextFragment? in
            guard let text = observation.topCandidates(1).first?.string
                .trimmingCharacters(in: .whitespacesAndNewlines),
                !text.isEmpty
            else { return nil }

            return ReceiptTextFragment(text: text, bounds: observation.boundingBox.cgRect)
        }
        .sorted {
            if abs($0.bounds.midY - $1.bounds.midY) > 0.005 {
                return $0.bounds.midY > $1.bounds.midY
            }
            return $0.bounds.minX < $1.bounds.minX
        }

        var rows: [ReceiptTextRow] = []
        for fragment in fragments {
            if let index = rows.firstIndex(where: { $0.overlapsVertically(with: fragment.bounds) }) {
                rows[index].append(fragment)
            } else {
                rows.append(ReceiptTextRow(fragment: fragment))
            }
        }

        return rows
            .sorted { $0.bounds.midY > $1.bounds.midY }
            .map { row in
                row.fragments
                    .sorted { $0.bounds.minX < $1.bounds.minX }
                    .map(\.text)
                    .joined(separator: " ")
            }
    }
}

private struct ReceiptTextFragment {
    let text: String
    let bounds: CGRect
}

private struct ReceiptTextRow {
    var fragments: [ReceiptTextFragment]
    var bounds: CGRect

    init(fragment: ReceiptTextFragment) {
        fragments = [fragment]
        bounds = fragment.bounds
    }

    mutating func append(_ fragment: ReceiptTextFragment) {
        fragments.append(fragment)
        bounds = bounds.union(fragment.bounds)
    }

    func overlapsVertically(with other: CGRect) -> Bool {
        let overlap = max(0, min(bounds.maxY, other.maxY) - max(bounds.minY, other.minY))
        return overlap >= min(bounds.height, other.height) * 0.35
    }
}

private struct ParsedReceipt {
    let merchant: String?
    let items: [ReceiptLineItem]
}

private struct ReceiptLineItem: Equatable {
    let name: String
    let quantity: Decimal
    let unitPrice: Decimal
}

private enum ReceiptLineItemParser {
    private static let trailingAmount = try! NSRegularExpression(
        pattern: #"(?i)(?:^|\s)(?:AZN|₼|RUB|₽|USD|\$|EUR|€)?\s*([-+]?(?:(?:\d{1,3}(?:[ .]\d{3})+)|\d+)(?:[,.]\d{1,2})?)\s*(?:AZN|₼|RUB|₽|USD|EUR|€|[A-ZА-Я]{1,2}|\*)?\s*$"#
    )
    private static let trailingQuantity = try! NSRegularExpression(
        pattern: #"(?i)\s+(\d+(?:[,.]\d+)?)\s*(?:x|х|\*)\s*(\d+(?:[,.]\d+)?)\s*$"#
    )
    private static let leadingQuantity = try! NSRegularExpression(
        pattern: #"(?i)^\s*\d+(?:[,.]\d+)?\s*(?:x|х|\*)\s*"#
    )

    private static let summaryPrefixes = [
        "total", "subtotal", "amount due", "tax", "vat", "change", "discount", "promo", "coupon", "savings", "cash", "card", "payment",
        "итого", "всего", "сумма", "к оплате", "налог", "ндс", "сдача", "скидка", "промо", "купон", "экономия", "наличные", "карта", "оплата",
        "yekun", "cəmi", "edv", "ədv", "endirim", "kampaniya", "kupon", "qənaət", "nağd", "nagd", "kart", "ödəniş", "odenis"
    ]
    private static let metadataPrefixes = [
        "receipt", "invoice", "check", "cashier", "phone", "tel", "address", "date", "time", "tax id", "tin", "fiscal", "serial", "terminal", "transaction",
        "чек", "касса", "кассир", "телефон", "адрес", "дата", "время", "инн", "фиск", "смена", "операция",
        "qəbz", "qebz", "çek", "cek", "kassa", "kassir", "telefon", "ünvan", "unvan", "tarix", "vaxt", "vöen", "voen", "fiskal", "əməliyyat", "emeliyyat"
    ]

    static func parse(_ lines: [String]) -> ParsedReceipt {
        let cleaned = lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let indexedItems = cleaned.enumerated().compactMap { index, line in
            item(from: line).map { (index, $0) }
        }
        let firstItemIndex = indexedItems.first?.0 ?? cleaned.count
        var merchant: String?
        for line in cleaned.prefix(firstItemIndex) where isMerchantCandidate(line) {
            merchant = line
            break
        }
        return ParsedReceipt(merchant: merchant, items: indexedItems.map(\.1))
    }

    private static func item(from line: String) -> ReceiptLineItem? {
        guard !hasPrefix(line, in: summaryPrefixes), !hasPrefix(line, in: metadataPrefixes) else { return nil }

        let fullRange = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = trailingAmount.firstMatch(in: line, range: fullRange),
              let amountRange = Range(match.range(at: 1), in: line),
              let matchRange = Range(match.range, in: line),
              let amount = decimal(from: String(line[amountRange])),
              amount > 0
        else { return nil }

        var name = String(line[..<matchRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        var quantity: Decimal = 1
        var unitPrice = amount
        let nameRange = NSRange(name.startIndex..<name.endIndex, in: name)
        if let quantityMatch = trailingQuantity.firstMatch(in: name, range: nameRange),
           let quantityRange = Range(quantityMatch.range(at: 1), in: name),
           let unitPriceRange = Range(quantityMatch.range(at: 2), in: name),
           let parsedQuantity = decimal(from: String(name[quantityRange])),
           let parsedUnitPrice = decimal(from: String(name[unitPriceRange])),
           parsedQuantity * parsedUnitPrice == amount
        {
            quantity = parsedQuantity
            unitPrice = parsedUnitPrice
            name = trailingQuantity.stringByReplacingMatches(
                in: name,
                range: nameRange,
                withTemplate: ""
            )
        }
        name = leadingQuantity.stringByReplacingMatches(
            in: name,
            range: NSRange(name.startIndex..<name.endIndex, in: name),
            withTemplate: ""
        )
        name = name.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))

        guard name.count >= 2, name.rangeOfCharacter(from: .letters) != nil else { return nil }
        return ReceiptLineItem(
            name: String(name.prefix(80)),
            quantity: quantity,
            unitPrice: unitPrice
        )
    }

    private static func decimal(from value: String) -> Decimal? {
        guard !value.contains("-") else { return nil }
        var digits = value.replacingOccurrences(of: " ", with: "")
        let separatorIndex = digits.lastIndex(where: { $0 == "." || $0 == "," })

        if let separatorIndex {
            let decimalPlaces = digits.distance(from: digits.index(after: separatorIndex), to: digits.endIndex)
            let allDigits = digits.filter(\.isNumber)
            if (1...2).contains(decimalPlaces), allDigits.count > decimalPlaces {
                let split = allDigits.index(allDigits.endIndex, offsetBy: -decimalPlaces)
                digits = "\(allDigits[..<split]).\(allDigits[split...])"
            } else {
                digits = allDigits
            }
        }

        return Decimal(string: digits, locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func isMerchantCandidate(_ line: String) -> Bool {
        line.count >= 2 &&
            line.count <= 80 &&
            line.rangeOfCharacter(from: .letters) != nil &&
            !hasPrefix(line, in: metadataPrefixes) &&
            !hasPrefix(line, in: summaryPrefixes)
    }

    private static func hasPrefix(_ line: String, in prefixes: [String]) -> Bool {
        let normalized = line
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased()
        return prefixes.contains {
            normalized == $0 || normalized.hasPrefix("\($0) ") || normalized.hasPrefix("\($0):")
        }
    }
}

#if DEBUG
extension ReceiptImportService {
    static func assertSelfCheck() {
        let receipt = ReceiptLineItemParser.parse([
            "BRAVO SUPERMARKET",
            "VÖEN 1234567891",
            "DATE 20.07.2026",
            "MILK 2 x 1.20 2.40",
            "BREAD 1,30 A",
            "PROMO -0.50",
            "VAT 0.45",
            "TOTAL 3.70 AZN"
        ])

        assert(receipt.merchant == "BRAVO SUPERMARKET")
        assert(receipt.items == [
            ReceiptLineItem(name: "MILK", quantity: 2, unitPrice: Decimal(string: "1.20")!),
            ReceiptLineItem(name: "BREAD", quantity: 1, unitPrice: Decimal(string: "1.30")!)
        ], "receipt totals and taxes must not become expenses")
    }
}
#endif
