//
//  MLClassificationService.swift
//  Ask Numi
//

import CoreML
import Foundation

@MainActor
final class MLClassificationService: TransactionClassifier {
    private enum CacheEntry {
        case prediction(TransactionCategoryClassification)
        case unavailable

        var prediction: TransactionCategoryClassification? {
            switch self {
            case .prediction(let prediction): prediction
            case .unavailable: nil
            }
        }
    }

    private let model: MLModel?
    private var cache: [String: CacheEntry] = [:]

    init() {
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all

        if let url = Bundle.main.url(forResource: "MyTabularClassifier", withExtension: "mlmodelc") {
            model = try? MLModel(contentsOf: url, configuration: configuration)
        } else {
            model = nil
        }
    }

    func classify(text: String) async -> TransactionCategoryClassification? {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalized.isEmpty, let model else { return nil }
        if let cached = cache[normalized] {
            return cached.prediction
        }

        let result: TransactionCategoryClassification?
        do {
            let input = try MLDictionaryFeatureProvider(dictionary: ["text": normalized])
            let output = try await model.prediction(from: input)
            guard
                let label = output.featureValue(for: "label")?.stringValue,
                let category = ClassifiedTransactionCategory(rawValue: label),
                let confidence = output.featureValue(for: "labelProbability")?
                    .dictionaryValue[label]?.doubleValue
            else {
                cache[normalized] = .unavailable
                return nil
            }
            result = TransactionCategoryClassification(
                category: category,
                confidence: min(max(confidence, 0), 1)
            )
        } catch {
            // The tabular model rejects merchants it did not see while training.
            result = nil
        }

        if cache.count >= 100 {
            cache.removeAll(keepingCapacity: true)
        }
        cache[normalized] = result.map(CacheEntry.prediction) ?? .unavailable
        return result
    }
}

#if DEBUG
extension MLClassificationService {
    static func assertSelfCheck() async {
        let service = MLClassificationService()
        let known = await service.classify(text: "STARBUCKS COFFEE #847")
        assert(known?.category == .food && known?.confidence ?? 0 > 0.9)
        let unknown = await service.classify(text: "A MERCHANT THE MODEL NEVER SAW")
        assert(unknown == nil, "unknown merchants must not break the add-operation form")
    }
}
#endif
