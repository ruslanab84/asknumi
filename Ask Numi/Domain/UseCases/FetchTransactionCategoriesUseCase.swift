//
//  FetchTransactionCategoriesUseCase.swift
//  Ask Numi
//

import Foundation

struct FetchTransactionCategoriesUseCase: Sendable {
    private let repository: TransactionCategoryRepository

    init(repository: TransactionCategoryRepository) {
        self.repository = repository
    }

    func execute() async throws -> [TransactionCategory] {
        try await repository.fetchAll()
    }
}
