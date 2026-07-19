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

    func update(_ category: TransactionCategory) async throws {
        let id = category.id
        let descriptor = FetchDescriptor<TransactionCategoryEntity>(
            predicate: #Predicate { $0.id == id }
        )
        guard let entity = try modelContext.fetch(descriptor).first else {
            throw DomainError.categoryNotFound
        }
        entity.name = category.name
        entity.kindRaw = category.kind.rawValue
        entity.icon = category.icon
        entity.colorRaw = category.color.rawValue
        try modelContext.save()
    }
}
