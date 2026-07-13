//
//  ContentView.swift
//  Ask Numi
//

import SwiftUI

struct ContentView: View {
    let container: AppContainer
    @State private var selectedTab: AppTab = .home

    var body: some View {
        Group {
            switch selectedTab {
            case .home:
                HomeDashboardView(
                    snapshot: .preview,
                    fetchTransactions: container.makeFetchTransactionsUseCase(),
                    selectedTab: $selectedTab
                )
            case .operations:
                OperationsView(
                    fetchTransactions: container.makeFetchTransactionsUseCase(),
                    fetchCategories: container.makeFetchTransactionCategoriesUseCase(),
                    addCategory: container.makeAddTransactionCategoryUseCase(),
                    addTransaction: container.makeAddTransactionUseCase(),
                    updateTransaction: container.makeUpdateTransactionUseCase(),
                    deleteTransaction: container.makeDeleteTransactionUseCase(),
                    selectedTab: $selectedTab
                )
            case .assistant:
                AssistantView(
                    getAdvice: container.makeAdviceUseCase(),
                    selectedTab: $selectedTab
                )
            case .plan:
                PlanView(
                    snapshot: .preview,
                    fetchTransactions: container.makeFetchTransactionsUseCase(),
                    fetchSubscriptions: container.makeFetchSubscriptionsUseCase(),
                    saveSubscription: container.makeSaveSubscriptionUseCase(),
                    deleteSubscription: container.makeDeleteSubscriptionUseCase(),
                    fetchBudgets: container.makeFetchBudgetsUseCase(),
                    saveBudget: container.makeSaveBudgetUseCase(),
                    deleteBudget: container.makeDeleteBudgetUseCase(),
                    selectedTab: $selectedTab
                )
            }
        }
    }
}

enum AppTab: CaseIterable {
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

struct AppTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        GlassEffectContainer(spacing: 18) {
            HStack(spacing: 0) {
                tabButton(.home)
                tabButton(.operations)
                tabButton(.assistant)
                tabButton(.plan)
            }
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, minHeight: 54)
            .glassEffect(.regular, in: .capsule)
        }
        .frame(height: 62)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.symbol)
                    .symbolVariant(tab == selection ? .fill : .none)
                    .font(.subheadline.weight(.semibold))
                Text(tab.title)
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(tab == selection ? .indigo : .secondary)
            .frame(maxWidth: .infinity, minHeight: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(tab == selection ? .isSelected : [])
    }
}

#Preview {
    ContentView(container: AppContainer(isStoredInMemoryOnly: true))
}
