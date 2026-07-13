//
//  BudgetRepository.swift
//  Ask Numi
//

import Foundation

protocol BudgetRepository: Sendable {
    func fetchAll() async throws -> [Budget]
    func save(_ budget: Budget) async throws
    func delete(id: UUID) async throws
}
