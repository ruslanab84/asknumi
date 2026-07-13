//
//  SaveBudgetUseCase.swift
//  Ask Numi
//

import Foundation

struct SaveBudgetUseCase: Sendable {
    private let repository: BudgetRepository

    init(repository: BudgetRepository) {
        self.repository = repository
    }

    func execute(_ budget: Budget) async throws {
        guard !budget.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DomainError.invalidName
        }
        guard budget.monthlyLimit > 0 else { throw DomainError.invalidAmount }
        try await repository.save(budget)
    }
}
