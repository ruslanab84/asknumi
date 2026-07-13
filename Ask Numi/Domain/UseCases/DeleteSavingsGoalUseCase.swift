//
//  DeleteSavingsGoalUseCase.swift
//  Ask Numi
//

import Foundation

struct DeleteSavingsGoalUseCase: Sendable {
    private let repository: SavingsGoalRepository

    init(repository: SavingsGoalRepository) {
        self.repository = repository
    }

    func execute(id: UUID) async throws {
        try await repository.delete(id: id)
    }
}
