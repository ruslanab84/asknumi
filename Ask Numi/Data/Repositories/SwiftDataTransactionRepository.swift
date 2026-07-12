//
//  SwiftDataTransactionRepository.swift
//  Ask Numi
//

import Foundation
import SwiftData

/// `@ModelActor` gives this repository its own serialized ModelContext,
/// so all persistence work happens off the main thread and is data-race free.
@ModelActor
actor SwiftDataTransactionRepository: TransactionRepository {

    func fetchAll() async throws -> [Transaction] {
        let descriptor = FetchDescriptor<TransactionEntity>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).compactMap { $0.toDomain() }
    }

    func fetch(in period: DateInterval) async throws -> [Transaction] {
        let start = period.start
        let end = period.end
        let descriptor = FetchDescriptor<TransactionEntity>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).compactMap { $0.toDomain() }
    }

    func add(_ transaction: Transaction) async throws {
        modelContext.insert(TransactionEntity(transaction))
        try modelContext.save()
    }

    func delete(id: UUID) async throws {
        try modelContext.delete(model: TransactionEntity.self, where: #Predicate { $0.id == id })
        try modelContext.save()
    }
}
