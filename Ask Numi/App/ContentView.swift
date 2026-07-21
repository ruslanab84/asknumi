//
//  ContentView.swift
//  Ask Numi
//

import SwiftUI

struct ContentView: View {
    let container: AppContainer
    @State private var selectedTab: AppTab = .home
    @State private var planSection: PlanSection = .payments
    @State private var assistantExchanges: [AssistantExchange] = []

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.home.title, systemImage: AppTab.home.symbol, value: AppTab.home) {
                HomeDashboardView(
                    snapshot: .preview,
                    fetchTransactions: container.makeFetchTransactionsUseCase(),
                    fetchBudgets: container.makeFetchBudgetsUseCase(),
                    fetchSubscriptions: container.makeFetchSubscriptionsUseCase(),
                    fetchGoals: container.makeFetchSavingsGoalsUseCase(),
                    getMonthlyInsight: container.makeMonthlySpendingInsightUseCase(),
                    getFinancialTwin: container.makeFinancialTwinUseCase(),
                    simulatePurchase: container.makePurchaseSimulatorUseCase(),
                    simulateTimeMachine: container.makeFinancialTimeMachineUseCase(),
                    showBudgets: {
                        planSection = .budgets
                        selectedTab = .plan
                    },
                    showAssistant: { selectedTab = .assistant }
                )
            }

            Tab(AppTab.operations.title, systemImage: AppTab.operations.symbol, value: AppTab.operations) {
                OperationsView(
                    fetchTransactions: container.makeFetchTransactionsUseCase(),
                    fetchCategories: container.makeFetchTransactionCategoriesUseCase(),
                    fetchSubscriptions: container.makeFetchSubscriptionsUseCase(),
                    fetchBudgets: container.makeFetchBudgetsUseCase(),
                    fetchGoals: container.makeFetchSavingsGoalsUseCase(),
                    addCategory: container.makeAddTransactionCategoryUseCase(),
                    updateCategory: container.makeUpdateTransactionCategoryUseCase(),
                    addTransaction: container.makeAddTransactionUseCase(),
                    saveGoals: container.makeSaveSavingsGoalUseCase(),
                    updateTransaction: container.makeUpdateTransactionUseCase(),
                    deleteTransaction: container.makeDeleteTransactionUseCase(),
                    parseNaturalInput: container.makeParseNaturalInputUseCase(),
                    transactionClassifier: container.transactionClassifier
                )
            }

            Tab(AppTab.assistant.title, systemImage: AppTab.assistant.symbol, value: AppTab.assistant) {
                AssistantView(
                    getAdvice: container.makeAdviceUseCase(),
                    exchanges: $assistantExchanges
                )
            }

            Tab(AppTab.plan.title, systemImage: AppTab.plan.symbol, value: AppTab.plan) {
                PlanView(
                    fetchTransactions: container.makeFetchTransactionsUseCase(),
                    fetchSubscriptions: container.makeFetchSubscriptionsUseCase(),
                    saveSubscription: container.makeSaveSubscriptionUseCase(),
                    deleteSubscription: container.makeDeleteSubscriptionUseCase(),
                    fetchBudgets: container.makeFetchBudgetsUseCase(),
                    saveBudget: container.makeSaveBudgetUseCase(),
                    deleteBudget: container.makeDeleteBudgetUseCase(),
                    fetchGoals: container.makeFetchSavingsGoalsUseCase(),
                    saveGoal: container.makeSaveSavingsGoalUseCase(),
                    deleteGoal: container.makeDeleteSavingsGoalUseCase(),
                    section: $planSection
                )
            }
        }
    }
}

enum AppTab: Hashable, CaseIterable {
    case home
    case operations
    case assistant
    case plan

    var title: String {
        switch self {
        case .home: L10n.Tab.home
        case .operations: L10n.Tab.operations
        case .assistant: L10n.Tab.assistant
        case .plan: L10n.Tab.plan
        }
    }

    var symbol: String {
        switch self {
        case .home: "house"
        case .operations: "list.bullet"
        case .assistant: "sparkles"
        case .plan: "calendar"
        }
    }
}

#Preview {
    ContentView(container: AppContainer(isStoredInMemoryOnly: true))
}
