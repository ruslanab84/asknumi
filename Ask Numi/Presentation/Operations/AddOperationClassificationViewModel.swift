//
//  AddOperationClassificationViewModel.swift
//  Ask Numi
//

import Foundation
import Observation

@MainActor
@Observable
final class AddOperationClassificationViewModel {
    var merchantText: String
    private(set) var suggestion: TransactionCategoryClassification?

    private let classifier: any TransactionClassifier

    init(classifier: any TransactionClassifier, merchantText: String = "") {
        self.classifier = classifier
        self.merchantText = merchantText
    }

    func refreshSuggestion() async {
        guard !merchantText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            suggestion = nil
            return
        }

        do {
            try await Task.sleep(for: .milliseconds(300))
        } catch {
            return
        }
        let classifiedText = merchantText
        let result = await classifier.classify(text: classifiedText)
        guard !Task.isCancelled, merchantText == classifiedText else { return }
        suggestion = result
    }
}

extension ClassifiedTransactionCategory {
    var localized: String {
        L10n.AddOperation.mlCategory(rawValue)
    }

    var icon: String {
        switch self {
        case .food: "fork.knife"
        case .transport: "car"
        case .subscriptions: "repeat.circle.fill"
        case .shopping: "bag"
        case .utilities: "bolt"
        case .health: "cross.case"
        case .entertainment: "film"
        case .cash: "banknote"
        case .income: "arrow.down.left.circle.fill"
        case .other: CategoryIcon.fallback
        }
    }
}
