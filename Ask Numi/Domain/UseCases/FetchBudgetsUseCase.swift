//
//  FetchBudgetsUseCase.swift
//  Ask Numi
//

struct FetchBudgetsUseCase: Sendable {
    private let repository: BudgetRepository

    init(repository: BudgetRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Budget] {
        try await repository.fetchAll()
    }
}
