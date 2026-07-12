//
//  TransactionRepository.swift
//  Ask Numi
//

import Foundation

protocol TransactionRepository: Sendable {
    func fetchAll() async throws -> [Transaction]
    func fetch(in period: DateInterval) async throws -> [Transaction]
    func add(_ transaction: Transaction) async throws
    func update(_ transaction: Transaction) async throws
    func delete(id: UUID) async throws
}
