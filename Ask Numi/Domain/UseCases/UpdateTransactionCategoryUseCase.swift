//
//  UpdateTransactionCategoryUseCase.swift
//  Ask Numi
//

import Foundation

struct UpdateTransactionCategoryUseCase: Sendable {
    private let repository: TransactionCategoryRepository

    init(repository: TransactionCategoryRepository) {
        self.repository = repository
    }

    func execute(_ category: TransactionCategory) async throws {
        try await repository.update(category)
    }
}
