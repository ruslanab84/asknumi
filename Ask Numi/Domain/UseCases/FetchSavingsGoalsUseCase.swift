//
//  FetchSavingsGoalsUseCase.swift
//  Ask Numi
//

struct FetchSavingsGoalsUseCase: Sendable {
    private let repository: SavingsGoalRepository

    init(repository: SavingsGoalRepository) {
        self.repository = repository
    }

    func execute() async throws -> [SavingsGoal] {
        try await repository.fetchAll()
    }
}
