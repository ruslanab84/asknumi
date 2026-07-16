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
    let budgetRepository: BudgetRepository
    let savingsGoalRepository: SavingsGoalRepository
    let advisor: FinancialAdvisor
    let transactionParser: TransactionParser
    let transactionClassifier: any TransactionClassifier

    init(isStoredInMemoryOnly: Bool = false) {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: isStoredInMemoryOnly)
            modelContainer = try ModelContainer(
                for: TransactionEntity.self,
                TransactionCategoryEntity.self,
                SubscriptionEntity.self,
                BudgetEntity.self,
                SavingsGoalEntity.self,
                configurations: configuration
            )
        } catch {
            // A store that fails to open at launch is unrecoverable.
            fatalError("Failed to create ModelContainer: \(error)")
        }
        transactionRepository = SwiftDataTransactionRepository(modelContainer: modelContainer)
        transactionCategoryRepository = SwiftDataTransactionCategoryRepository(modelContainer: modelContainer)
        subscriptionRepository = SwiftDataSubscriptionRepository(modelContainer: modelContainer)
        budgetRepository = SwiftDataBudgetRepository(modelContainer: modelContainer)
        savingsGoalRepository = SwiftDataSavingsGoalRepository(modelContainer: modelContainer)
        advisor = FoundationModelsAdvisor()
        transactionParser = FoundationModelsTransactionParser()
        transactionClassifier = MLClassificationService()

        #if DEBUG
        BudgetOverview.assertSelfCheck()
        SavingsGoalsOverview.assertSelfCheck()
        GetFinancialAdviceUseCase.assertSelfCheck()
        GetMonthlySpendingInsightUseCase.assertSelfCheck()
        FoundationModelsAdvisor.assertSelfCheck()
        Task { await GetFinancialAdviceUseCase.assertAsyncSelfCheck() }
        Task { await ParseNaturalInputUseCase.assertSelfCheck() }
        Task { await MLClassificationService.assertSelfCheck() }
        #endif
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

    func makeParseNaturalInputUseCase() -> ParseNaturalInputUseCase {
        ParseNaturalInputUseCase(parser: transactionParser)
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

    func makeFetchBudgetsUseCase() -> FetchBudgetsUseCase {
        FetchBudgetsUseCase(repository: budgetRepository)
    }

    func makeSaveBudgetUseCase() -> SaveBudgetUseCase {
        SaveBudgetUseCase(repository: budgetRepository)
    }

    func makeDeleteBudgetUseCase() -> DeleteBudgetUseCase {
        DeleteBudgetUseCase(repository: budgetRepository)
    }

    func makeFetchSavingsGoalsUseCase() -> FetchSavingsGoalsUseCase {
        FetchSavingsGoalsUseCase(repository: savingsGoalRepository)
    }

    func makeSaveSavingsGoalUseCase() -> SaveSavingsGoalUseCase {
        SaveSavingsGoalUseCase(repository: savingsGoalRepository)
    }

    func makeDeleteSavingsGoalUseCase() -> DeleteSavingsGoalUseCase {
        DeleteSavingsGoalUseCase(repository: savingsGoalRepository)
    }

    func makeAdviceUseCase() -> GetFinancialAdviceUseCase {
        GetFinancialAdviceUseCase(transactions: transactionRepository, advisor: advisor)
    }

    func makeMonthlySpendingInsightUseCase() -> GetMonthlySpendingInsightUseCase {
        GetMonthlySpendingInsightUseCase(advisor: advisor)
    }
}
