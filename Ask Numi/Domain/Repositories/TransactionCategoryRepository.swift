//
//  TransactionCategoryRepository.swift
//  Ask Numi
//

import Foundation

protocol TransactionCategoryRepository: Sendable {
    func fetchAll() async throws -> [TransactionCategory]
    func add(_ category: TransactionCategory) async throws
}
