//
//  DeleteTransactionUseCase.swift
//  Ask Numi
//

import Foundation

struct DeleteTransactionUseCase: Sendable {
    private let repository: TransactionRepository

    init(repository: TransactionRepository) {
        self.repository = repository
    }

    func execute(id: UUID) async throws {
        try await repository.delete(id: id)
    }
}
