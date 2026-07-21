//
//  SavingsGoalRepository.swift
//  Ask Numi
//

import Foundation

protocol SavingsGoalRepository: Sendable {
    func fetchAll() async throws -> [SavingsGoal]
    func save(_ goal: SavingsGoal) async throws
    func save(_ goals: [SavingsGoal]) async throws
    func delete(id: UUID) async throws
}
