//
//  AddTransactionUseCase.swift
//  Ask Numi
//

import Foundation

struct AddTransactionUseCase: Sendable {
    private let repository: TransactionRepository

    init(repository: TransactionRepository) {
        self.repository = repository
    }

    func execute(_ transaction: Transaction) async throws {
        guard transaction.amount > 0 else { throw DomainError.invalidAmount }
        try await repository.add(transaction)
    }

    func execute(_ transactions: [Transaction]) async throws {
        guard !transactions.isEmpty, transactions.allSatisfy({ $0.amount > 0 }) else {
            throw DomainError.invalidAmount
        }
        try await repository.add(transactions)
    }
}
