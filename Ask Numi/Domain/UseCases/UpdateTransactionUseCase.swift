//
//  UpdateTransactionUseCase.swift
//  Ask Numi
//

import Foundation

struct UpdateTransactionUseCase: Sendable {
    private let repository: TransactionRepository

    init(repository: TransactionRepository) {
        self.repository = repository
    }

    func execute(_ transaction: Transaction) async throws {
        guard transaction.amount > 0, transaction.hasValidReceiptItem else { throw DomainError.invalidAmount }
        try await repository.update(transaction)
    }
}
