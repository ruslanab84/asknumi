//
//  SwiftDataSubscriptionRepository.swift
//  Ask Numi
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataSubscriptionRepository: SubscriptionRepository {
    func fetchAll() async throws -> [Subscription] {
        let descriptor = FetchDescriptor<SubscriptionEntity>(
            sortBy: [SortDescriptor(\.nextChargeDate)]
        )
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func save(_ subscription: Subscription) async throws {
        modelContext.insert(SubscriptionEntity(subscription))
        try modelContext.save()
    }

    func delete(id: UUID) async throws {
        try modelContext.delete(model: SubscriptionEntity.self, where: #Predicate { $0.id == id })
        try modelContext.save()
    }
}
