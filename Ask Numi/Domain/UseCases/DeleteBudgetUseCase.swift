//
//  DeleteBudgetUseCase.swift
//  Ask Numi
//

import Foundation

struct DeleteBudgetUseCase: Sendable {
    private let repository: BudgetRepository

    init(repository: BudgetRepository) {
        self.repository = repository
    }

    func execute(id: UUID) async throws {
        try await repository.delete(id: id)
    }
}
