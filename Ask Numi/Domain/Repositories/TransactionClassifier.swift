//
//  TransactionClassifier.swift
//  Ask Numi
//

import Foundation

enum ClassifiedTransactionCategory: String, Sendable {
    case food
    case transport
    case subscriptions
    case shopping
    case utilities
    case health
    case entertainment
    case cash
    case income
    case other

    var kind: TransactionKind {
        self == .income ? .income : .expense
    }
}

struct TransactionCategoryClassification: Equatable, Sendable {
    let category: ClassifiedTransactionCategory
    let confidence: Double
}

protocol TransactionClassifier: Sendable {
    func classify(text: String) async -> TransactionCategoryClassification?
}
