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
    let transactionCategoryRepository: TransactionCategoryRepository
    let subscriptionRepository: SubscriptionRepository
    let advisor: FinancialAdvisor

    init(isStoredInMemoryOnly: Bool = false) {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: isStoredInMemoryOnly)
            modelContainer = try ModelContainer(
                for: TransactionEntity.self,
                TransactionCategoryEntity.self,
                SubscriptionEntity.self,
                configurations: configuration
            )
        } catch {
            // A store that fails to open at launch is unrecoverable.
            fatalError("Failed to create ModelContainer: \(error)")
        }
        transactionRepository = SwiftDataTransactionRepository(modelContainer: modelContainer)
        transactionCategoryRepository = SwiftDataTransactionCategoryRepository(modelContainer: modelContainer)
        subscriptionRepository = SwiftDataSubscriptionRepository(modelContainer: modelContainer)
        advisor = FoundationModelsAdvisor()
    }

    func makeFetchTransactionCategoriesUseCase() -> FetchTransactionCategoriesUseCase {
        FetchTransactionCategoriesUseCase(repository: transactionCategoryRepository)
    }

    func makeAddTransactionCategoryUseCase() -> AddTransactionCategoryUseCase {
        AddTransactionCategoryUseCase(repository: transactionCategoryRepository)
    }

    func makeAddTransactionUseCase() -> AddTransactionUseCase {
        AddTransactionUseCase(repository: transactionRepository)
    }

    func makeUpdateTransactionUseCase() -> UpdateTransactionUseCase {
        UpdateTransactionUseCase(repository: transactionRepository)
    }

    func makeDeleteTransactionUseCase() -> DeleteTransactionUseCase {
        DeleteTransactionUseCase(repository: transactionRepository)
    }

    func makeFetchTransactionsUseCase() -> FetchTransactionsUseCase {
        FetchTransactionsUseCase(repository: transactionRepository)
    }

    func makeFetchSubscriptionsUseCase() -> FetchSubscriptionsUseCase {
        FetchSubscriptionsUseCase(repository: subscriptionRepository)
    }

    func makeSaveSubscriptionUseCase() -> SaveSubscriptionUseCase {
        SaveSubscriptionUseCase(repository: subscriptionRepository)
    }

    func makeDeleteSubscriptionUseCase() -> DeleteSubscriptionUseCase {
        DeleteSubscriptionUseCase(repository: subscriptionRepository)
    }

    func makeAdviceUseCase() -> GetFinancialAdviceUseCase {
        GetFinancialAdviceUseCase(transactions: transactionRepository, advisor: advisor)
    }
}
