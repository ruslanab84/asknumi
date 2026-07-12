//
//  DeleteSubscriptionUseCase.swift
//  Ask Numi
//

import Foundation

struct DeleteSubscriptionUseCase: Sendable {
    private let repository: SubscriptionRepository

    init(repository: SubscriptionRepository) {
        self.repository = repository
    }

    func execute(id: UUID) async throws {
        try await repository.delete(id: id)
    }
}
