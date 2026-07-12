//
//  HomeDashboardView.swift
//  Ask Numi
//

import SwiftUI

struct HomeDashboardView: View {
    let snapshot: DashboardSnapshot

    var body: some View {
        NavigationStack {
            ZStack {
                DashboardBackground()

                ScrollView {
                    GlassEffectContainer(spacing: 22) {
                        VStack(alignment: .leading, spacing: 20) {
                            DashboardHeader()
                            WelcomeView(name: snapshot.userName)
                            BalanceCard(snapshot: snapshot)
                            BudgetCard(snapshot: snapshot)
                            InsightCard(insight: snapshot.insight)
                            RecentTransactions(transactions: snapshot.transactions)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 104)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .safeAreaInset(edge: .bottom) {
                DashboardTabBar()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private struct DashboardHeader: View {
    var body: some View {
        HStack {
            Image(systemName: "line.3.horizontal")
            Spacer()
            Text("Главная")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Image(systemName: "bell")
        }
        .font(.body.weight(.medium))
        .frame(maxWidth: .infinity)
    }
}

private struct WelcomeView: View {
    let name: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundStyle(.orange, .pink)

            Text("Добрый вечер, \(name)!")
                .font(.subheadline.weight(.medium))
        }
    }
}

private struct BalanceCard: View {
    let snapshot: DashboardSnapshot

    var body: some View {
        GlassCard(tint: .indigo.opacity(0.12)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Общий баланс")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "eye")
                        .foregroundStyle(.secondary)
                }

                Text(snapshot.balance)
                    .font(.system(size: 30, weight: .bold, design: .rounded))

                Divider()

                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 5) {
                        Label("Безопасно потратить", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.green)
                        Text(snapshot.safeToSpend)
                            .font(.title2.weight(.bold))
                        Text("до 1 августа")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "shield.checkered")
                        .font(.title3)
                        .foregroundStyle(.green)
                        .frame(width: 42, height: 42)
                        .background(.green.opacity(0.14), in: .circle)
                }
            }
        }
    }
}

private struct BudgetCard: View {
    let snapshot: DashboardSnapshot

    var body: some View {
        GlassCard(tint: .mint.opacity(0.12)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Бюджет июля")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(snapshot.budgetProgress.formatted(.percent.precision(.fractionLength(0))))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: snapshot.budgetProgress)
                    .tint(.mint)

                HStack {
                    AmountCaption(title: "Потрачено", value: snapshot.spent)
                    Spacer()
                    AmountCaption(title: "План", value: snapshot.budget, alignment: .trailing)
                }
            }
        }
    }
}

private struct AmountCaption: View {
    let title: String
    let value: String
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
        }
    }
}

private struct InsightCard: View {
    let insight: String

    var body: some View {
        GlassCard(tint: .purple.opacity(0.18)) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(.purple)
                    .frame(width: 38, height: 38)
                    .background(.purple.opacity(0.15), in: .circle)

                VStack(alignment: .leading, spacing: 7) {
                    Text("AI-инсайт")
                        .font(.subheadline.weight(.bold))
                    Text(insight)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Показать детали  →")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.purple)
                }
            }
        }
    }
}

private struct RecentTransactions: View {
    let transactions: [DashboardTransaction]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Последние операции")
                    .font(.headline)
                Spacer()
                Text("Все")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.purple)
            }

            GlassCard(tint: .clear) {
                VStack(spacing: 0) {
                    ForEach(transactions) { transaction in
                        TransactionRow(transaction: transaction)

                        if transaction.id != transactions.last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            }
        }
    }
}

private struct TransactionRow: View {
    let transaction: DashboardTransaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(transaction.tint)
                .frame(width: 38, height: 38)
                .background(transaction.tint.opacity(0.14), in: .rect(cornerRadius: 12))

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
                    .foregroundStyle(transaction.isIncome ? .green : .primary)
                Text(transaction.time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
    }
}

private struct DashboardTabBar: View {
    var body: some View {
        GlassEffectContainer(spacing: 18) {
            HStack(spacing: 0) {
                TabItem(title: "Главная", symbol: "house.fill", isSelected: true)
                TabItem(title: "Операции", symbol: "list.bullet", isSelected: false)

                Image(systemName: "plus")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .glassEffect(.regular.tint(.indigo), in: .circle)
                    .offset(y: -16)
                    .accessibilityLabel("Добавить операцию")

                TabItem(title: "Помощник", symbol: "sparkles", isSelected: false)
                TabItem(title: "План", symbol: "calendar", isSelected: false)
            }
            .padding(.horizontal, 6)
            .padding(.top, 8)
            .frame(maxWidth: .infinity)
            .glassEffect(.regular, in: .capsule)
        }
        .frame(height: 62)
    }
}

private struct TabItem: View {
    let title: String
    let symbol: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.semibold))
            Text(title)
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(isSelected ? .indigo : .secondary)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct GlassCard<Content: View>: View {
    let tint: Color
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular.tint(tint), in: .rect(cornerRadius: 24))
    }
}

private struct DashboardBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [.black, Color(red: 0.02, green: 0.06, blue: 0.12), Color(red: 0.06, green: 0.02, blue: 0.16)]
                : [Color(red: 0.96, green: 0.97, blue: 1), .white, Color(red: 0.95, green: 1, blue: 0.98)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct DashboardSnapshot {
    let userName: String
    let balance: String
    let safeToSpend: String
    let budgetProgress: Double
    let spent: String
    let budget: String
    let insight: String
    let transactions: [DashboardTransaction]

    static let preview = DashboardSnapshot(
        userName: "Руслан",
        balance: "4 280 AZN",
        safeToSpend: "740 AZN",
        budgetProgress: 0.68,
        spent: "2 904 AZN",
        budget: "4 280 AZN",
        insight: "Расходы на кафе выросли на 24% за последние 2 недели.",
        transactions: [
            DashboardTransaction(id: "bravo", title: "Bravo Supermarket", category: "Продукты", amount: "−48 AZN", time: "19:42", symbol: "cart.fill", tint: .green, isIncome: false),
            DashboardTransaction(id: "bolt", title: "Bolt", category: "Транспорт", amount: "−12 AZN", time: "18:17", symbol: "car.fill", tint: .gray, isIncome: false),
            DashboardTransaction(id: "salary", title: "Зарплата", category: "Доход", amount: "+3 200 AZN", time: "09:15", symbol: "arrow.down.left.circle.fill", tint: .mint, isIncome: true)
        ]
    )
}

struct DashboardTransaction: Identifiable {
    let id: String
    let title: String
    let category: String
    let amount: String
    let time: String
    let symbol: String
    let tint: Color
    let isIncome: Bool
}

#Preview("Светлая тема") {
    HomeDashboardView(snapshot: .preview)
}

#Preview("Тёмная тема") {
    HomeDashboardView(snapshot: .preview)
        .preferredColorScheme(.dark)
}
