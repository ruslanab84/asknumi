//
//  FetchSubscriptionsUseCase.swift
//  Ask Numi
//

struct FetchSubscriptionsUseCase: Sendable {
    private let repository: SubscriptionRepository

    init(repository: SubscriptionRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Subscription] {
        try await repository.fetchAll()
    }
}
