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
                HomeDashboardView(snapshot: .preview, selectedTab: $selectedTab)
            case .operations:
                OperationsView(snapshot: .preview, selectedTab: $selectedTab)
            case .assistant:
                AssistantView(snapshot: .preview, selectedTab: $selectedTab)
            case .plan:
                PlanView(snapshot: .preview, selectedTab: $selectedTab)
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
        case .home: "Главная"
        case .operations: "Операции"
        case .assistant: "Помощник"
        case .plan: "План"
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
    @State private var isAddingCategory = false

    var body: some View {
        GlassEffectContainer(spacing: 18) {
            HStack(spacing: 0) {
                tabButton(.home)
                tabButton(.operations)

                Button {
                    isAddingCategory = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .glassEffect(.regular.tint(.indigo), in: .circle)
                }
                .offset(y: -16)
                .accessibilityLabel("Добавить категорию")

                tabButton(.assistant)
                tabButton(.plan)
            }
            .padding(.horizontal, 6)
            .padding(.top, 8)
            .frame(maxWidth: .infinity)
            .glassEffect(.regular, in: .capsule)
        }
        .frame(height: 62)
        .fullScreenCover(isPresented: $isAddingCategory) {
            NewCategoryView()
        }
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab == selection ? "\(tab.symbol).fill" : tab.symbol)
                    .font(.subheadline.weight(.semibold))
                Text(tab.title)
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(tab == selection ? .indigo : .secondary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(tab == selection ? .isSelected : [])
    }
}

#Preview {
    ContentView(container: AppContainer())
}
