//
//  SaveSubscriptionUseCase.swift
//  Ask Numi
//

import Foundation

struct SaveSubscriptionUseCase: Sendable {
    private let repository: SubscriptionRepository

    init(repository: SubscriptionRepository) {
        self.repository = repository
    }

    func execute(_ subscription: Subscription) async throws {
        guard !subscription.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DomainError.invalidName
        }
        guard subscription.amount > 0 else { throw DomainError.invalidAmount }
        try await repository.save(subscription)
    }
}
