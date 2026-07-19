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
        try postDueSubscriptions()
        let descriptor = FetchDescriptor<TransactionEntity>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).compactMap { $0.toDomain() }
    }

    func fetch(in period: DateInterval) async throws -> [Transaction] {
        try postDueSubscriptions()
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

    func add(_ transactions: [Transaction]) async throws {
        try modelContext.transaction {
            for transaction in transactions {
                modelContext.insert(TransactionEntity(transaction))
            }
        }
    }

    func update(_ transaction: Transaction) async throws {
        // `id` is @Attribute(.unique), so insert performs an upsert on the existing row.
        modelContext.insert(TransactionEntity(transaction))
        try modelContext.save()
    }

    func delete(id: UUID) async throws {
        try modelContext.delete(model: TransactionEntity.self, where: #Predicate { $0.id == id })
        try modelContext.save()
    }

    private func postDueSubscriptions(asOf now: Date = .now) throws {
        let descriptor = FetchDescriptor<SubscriptionEntity>(
            predicate: #Predicate { $0.nextChargeDate <= now }
        )
        let subscriptions = try modelContext.fetch(descriptor)
        guard !subscriptions.isEmpty else { return }

        try modelContext.transaction {
            for subscription in subscriptions {
                while subscription.nextChargeDate <= now,
                      subscription.endDate.map({ subscription.nextChargeDate <= $0 }) ?? true {
                    modelContext.insert(TransactionEntity(Transaction(
                        amount: subscription.amount,
                        kind: .expense,
                        category: subscription.name,
                        categoryIcon: "repeat.circle.fill",
                        date: subscription.nextChargeDate
                    )))
                    subscription.nextChargeDate = Subscription.followingChargeDate(
                        after: subscription.nextChargeDate,
                        billingDay: subscription.billingDay
                    )
                }
            }
        }
    }
}
