//
//  AppContainer.swift
//  Ask Numi
//
//  Composition root — the only place that knows concrete types.
//

import Foundation
import SwiftData

@MainActor
final class AppContainer {
    let modelContainer: ModelContainer
    let transactionRepository: TransactionRepository
    let advisor: FinancialAdvisor

    init(isStoredInMemoryOnly: Bool = false) {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: isStoredInMemoryOnly)
            modelContainer = try ModelContainer(for: TransactionEntity.self, configurations: configuration)
        } catch {
            // A store that fails to open at launch is unrecoverable.
            fatalError("Failed to create ModelContainer: \(error)")
        }
        transactionRepository = SwiftDataTransactionRepository(modelContainer: modelContainer)
        advisor = FoundationModelsAdvisor()
    }

    func makeAddTransactionUseCase() -> AddTransactionUseCase {
        AddTransactionUseCase(repository: transactionRepository)
    }

    func makeFetchTransactionsUseCase() -> FetchTransactionsUseCase {
        FetchTransactionsUseCase(repository: transactionRepository)
    }

    func makeAdviceUseCase() -> GetFinancialAdviceUseCase {
        GetFinancialAdviceUseCase(transactions: transactionRepository, advisor: advisor)
    }
}
