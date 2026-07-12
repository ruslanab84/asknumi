//
//  FetchTransactionsUseCase.swift
//  Ask Numi
//

import Foundation

struct FetchTransactionsUseCase: Sendable {
    private let repository: TransactionRepository

    init(repository: TransactionRepository) {
        self.repository = repository
    }

    func execute(in period: DateInterval? = nil) async throws -> [Transaction] {
        if let period {
            return try await repository.fetch(in: period)
        }
        return try await repository.fetchAll()
    }
}
