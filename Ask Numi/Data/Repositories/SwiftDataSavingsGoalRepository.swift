//
//  SwiftDataSavingsGoalRepository.swift
//  Ask Numi
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataSavingsGoalRepository: SavingsGoalRepository {
    func fetchAll() async throws -> [SavingsGoal] {
        let descriptor = FetchDescriptor<SavingsGoalEntity>(
            sortBy: [SortDescriptor(\.targetDate)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func save(_ goal: SavingsGoal) async throws {
        modelContext.insert(SavingsGoalEntity(goal))
        try modelContext.save()
    }

    func delete(id: UUID) async throws {
        try modelContext.delete(model: SavingsGoalEntity.self, where: #Predicate { $0.id == id })
        try modelContext.save()
    }
}
