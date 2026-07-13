//
//  SwiftDataBudgetRepository.swift
//  Ask Numi
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataBudgetRepository: BudgetRepository {
    func fetchAll() async throws -> [Budget] {
        let descriptor = FetchDescriptor<BudgetEntity>(
            sortBy: [SortDescriptor(\.category)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func save(_ budget: Budget) async throws {
        modelContext.insert(BudgetEntity(budget))
        try modelContext.save()
    }

    func delete(id: UUID) async throws {
        try modelContext.delete(model: BudgetEntity.self, where: #Predicate { $0.id == id })
        try modelContext.save()
    }
}
