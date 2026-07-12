//
//  SubscriptionRepository.swift
//  Ask Numi
//

import Foundation

protocol SubscriptionRepository: Sendable {
    func fetchAll() async throws -> [Subscription]
    func save(_ subscription: Subscription) async throws
    func delete(id: UUID) async throws
}
