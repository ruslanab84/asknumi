//
//  SwiftDataTransactionCategoryRepository.swift
//  Ask Numi
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataTransactionCategoryRepository: TransactionCategoryRepository {
    func fetchAll() async throws -> [TransactionCategory] {
        let descriptor = FetchDescriptor<TransactionCategoryEntity>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor).compactMap { $0.toDomain() }
    }

    func add(_ category: TransactionCategory) async throws {
        modelContext.insert(TransactionCategoryEntity(category))
        try modelContext.save()
    }
}
