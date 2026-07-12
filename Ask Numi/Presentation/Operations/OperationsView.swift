//
//  OperationsView.swift
//  Ask Numi
//

import SwiftUI

struct OperationsView: View {
    let snapshot: OperationsSnapshot
    @Binding var selectedTab: AppTab
    @State private var query = ""
    @State private var filter: OperationsFilter = .all

    private var sections: [OperationsSection] {
        snapshot.sections.compactMap { section in
            let transactions = section.transactions.filter { transaction in
                filter.matches(transaction) &&
                    (query.isEmpty || transaction.title.localizedCaseInsensitiveContains(query) || transaction.category.localizedCaseInsensitiveContains(query))
            }
            return transactions.isEmpty ? nil : OperationsSection(title: section.title, transactions: transactions)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DashboardBackground()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        header
                        searchField
                        filters

                        ForEach(sections) { section in
                            transactionSection(section)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 104)
                }
                .scrollIndicators(.hidden)
            }
            .safeAreaInset(edge: .bottom) {
                AppTabBar(selection: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        HStack {
            Text("Операции")
                .font(.title3.weight(.bold))
            Spacer()
            Image(systemName: "cart")
                .font(.body.weight(.semibold))
                .accessibilityLabel("Покупки")
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Поиск или спросите что-нибудь", text: $query)
                .font(.subheadline)
            Image(systemName: "mic.fill")
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .glassEffect(.regular, in: .capsule)
    }

    private var filters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(OperationsFilter.allCases, id: \.self) { item in
                    Button(item.title) {
                        filter = item
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(filter == item ? .white : .primary)
                    .padding(.horizontal, 16)
                    .frame(height: 34)
                    .glassEffect(.regular.tint(filter == item ? .indigo : .clear), in: .capsule)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func transactionSection(_ section: OperationsSection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.title)
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                ForEach(section.transactions) { transaction in
                    OperationsRow(transaction: transaction)

                    if transaction.id != section.transactions.last?.id {
                        Divider().padding(.leading, 54)
                    }
                }
            }
        }
    }
}

private struct OperationsRow: View {
    let transaction: OperationItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(transaction.tint)
                .frame(width: 42, height: 42)
                .background(transaction.tint.opacity(0.14), in: .rect(cornerRadius: 13))

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.title)
                    .font(.subheadline.weight(.semibold))
                Text(transaction.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(transaction.amount)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(transaction.kind == .income ? .green : .primary)
                Text(transaction.time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 9)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

private enum OperationsFilter: CaseIterable {
    case all
    case expenses
    case income
    case subscriptions

    var title: String {
        switch self {
        case .all: "Все"
        case .expenses: "Расходы"
        case .income: "Доходы"
        case .subscriptions: "Подписки"
        }
    }

    func matches(_ transaction: OperationItem) -> Bool {
        switch self {
        case .all: true
        case .expenses: transaction.kind == .expense
        case .income: transaction.kind == .income
        case .subscriptions: transaction.category == "Подписка"
        }
    }
}

struct OperationsSnapshot {
    let sections: [OperationsSection]

    static let preview = OperationsSnapshot(sections: [
        OperationsSection(title: "Сегодня", transactions: [
            OperationItem(id: "bravo", title: "Bravo Supermarket", category: "Продукты", amount: "−48 AZN", time: "19:42", symbol: "cart.fill", tint: .green, kind: .expense),
            OperationItem(id: "bolt", title: "Bolt", category: "Транспорт", amount: "−12 AZN", time: "18:17", symbol: "car.fill", tint: .gray, kind: .expense),
            OperationItem(id: "coffee", title: "Coffee Moffie", category: "Кафе", amount: "−14 AZN", time: "12:08", symbol: "cup.and.saucer.fill", tint: .blue, kind: .expense)
        ]),
        OperationsSection(title: "Вчера", transactions: [
            OperationItem(id: "pharmacy", title: "Аптека №44", category: "Здоровье", amount: "−8 AZN", time: "20:11", symbol: "heart.fill", tint: .pink, kind: .expense),
            OperationItem(id: "market", title: "Market 24", category: "Продукты", amount: "−15 AZN", time: "17:33", symbol: "cart.fill", tint: .green, kind: .expense)
        ]),
        OperationsSection(title: "12 июня", transactions: [
            OperationItem(id: "netflix", title: "Netflix", category: "Подписка", amount: "−15 AZN", time: "21:00", symbol: "n.square.fill", tint: .red, kind: .expense),
            OperationItem(id: "azerishiq", title: "Азеришыг", category: "Коммунальные", amount: "−44 AZN", time: "10:22", symbol: "drop.fill", tint: .blue, kind: .expense)
        ])
    ])
}

struct OperationsSection: Identifiable {
    let title: String
    let transactions: [OperationItem]
    var id: String { title }
}

struct OperationItem: Identifiable {
    let id: String
    let title: String
    let category: String
    let amount: String
    let time: String
    let symbol: String
    let tint: Color
    let kind: TransactionKind
}

#Preview("Светлая тема") {
    OperationsView(snapshot: .preview, selectedTab: .constant(.operations))
}

#Preview("Тёмная тема") {
    OperationsView(snapshot: .preview, selectedTab: .constant(.operations))
        .preferredColorScheme(.dark)
}
