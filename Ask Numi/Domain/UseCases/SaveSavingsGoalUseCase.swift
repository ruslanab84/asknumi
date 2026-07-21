//
//  SaveSavingsGoalUseCase.swift
//  Ask Numi
//

import Foundation

struct SaveSavingsGoalUseCase: Sendable {
    private let repository: SavingsGoalRepository

    init(repository: SavingsGoalRepository) {
        self.repository = repository
    }

    func execute(_ goal: SavingsGoal) async throws {
        try validate(goal)
        try await repository.save(goal)
    }

    func execute(_ goals: [SavingsGoal]) async throws {
        try goals.forEach(validate)
        try await repository.save(goals)
    }

    private func validate(_ goal: SavingsGoal) throws {
        let name = goal.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 60 else { throw DomainError.invalidName }
        guard goal.targetAmount > 0, goal.savedAmount >= 0 else { throw DomainError.invalidAmount }
    }
}
