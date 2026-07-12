//
//  HomeDashboardView.swift
//  Ask Numi
//

import SwiftUI

struct HomeDashboardView: View {
    let snapshot: DashboardSnapshot // ponytail: budget & insight cards still mock, wire when those features land
    let fetchTransactions: FetchTransactionsUseCase
    @Binding var selectedTab: AppTab
    @State private var isShowingSettings = false
    @State private var transactions: [Transaction] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var summary: FinancialSummary {
        FinancialSummary(
            transactions: transactions,
            period: DateInterval(start: .distantPast, end: .distantFuture)
        )
    }

    private var recentTransactions: [Transaction] {
        Array(transactions.sorted { $0.date > $1.date }.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DashboardBackground()

                ScrollView {
                    GlassEffectContainer(spacing: 22) {
                        VStack(alignment: .leading, spacing: 20) {
                            DashboardHeader {
                                isShowingSettings = true
                            }
                            WelcomeView(name: snapshot.userName)
                            BalanceCard(summary: summary, isLoading: isLoading)

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }

                            BudgetCard(snapshot: snapshot)
                            InsightCard(insight: snapshot.insight)
                            RecentTransactions(transactions: recentTransactions)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 104)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .safeAreaInset(edge: .bottom) {
                AppTabBar(selection: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .task {
                await loadTransactions()
            }
        }
    }

    private func loadTransactions() async {
        isLoading = true
        defer { isLoading = false }

        do {
            transactions = try await fetchTransactions.execute()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct DashboardHeader: View {
    let showSettings: () -> Void

    var body: some View {
        HStack {
            Button(action: showSettings) {
                Image(systemName: "line.3.horizontal")
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.Dashboard.settingsLabel)
            Spacer()
            Text(L10n.Dashboard.title)
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

            Text(L10n.Dashboard.greeting(name))
                .font(.subheadline.weight(.medium))
        }
    }
}

private struct BalanceCard: View {
    let summary: FinancialSummary
    let isLoading: Bool

    var body: some View {
        GlassCard(tint: .indigo.opacity(0.12)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(L10n.Dashboard.totalBalance)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "eye")
                        .foregroundStyle(.secondary)
                }

                Text(OperationFormatting.plain(summary.balance))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .redacted(reason: isLoading ? .placeholder : [])

                Divider()

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Label(L10n.Dashboard.income, systemImage: "arrow.down.left.circle.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.green)
                        Text(OperationFormatting.amount(summary.totalIncome, sign: .income))
                            .font(.title3.weight(.bold))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 5) {
                        Label(L10n.Dashboard.expenses, systemImage: "arrow.up.right.circle.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.red)
                        Text(OperationFormatting.amount(summary.totalExpenses, sign: .expense))
                            .font(.title3.weight(.bold))
                    }
                }
                .redacted(reason: isLoading ? .placeholder : [])
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
                    Text(L10n.Dashboard.budgetTitle)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(snapshot.budgetProgress.formatted(.percent.precision(.fractionLength(0))))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: snapshot.budgetProgress)
                    .tint(.mint)

                HStack {
                    AmountCaption(title: L10n.Dashboard.spent, value: snapshot.spent)
                    Spacer()
                    AmountCaption(title: L10n.Dashboard.budgetPlan, value: snapshot.budget, alignment: .trailing)
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
                    Text(L10n.Dashboard.insightTitle)
                        .font(.subheadline.weight(.bold))
                    Text(insight)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(L10n.Dashboard.insightShowDetails)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.purple)
                }
            }
        }
    }
}

private struct RecentTransactions: View {
    let transactions: [Transaction]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Dashboard.recentTitle)
                .font(.headline)

            GlassCard(tint: .clear) {
                if transactions.isEmpty {
                    Text(L10n.Dashboard.recentEmpty)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
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
}

private struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.categoryIcon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(transaction.kind == .income ? .green : .red)
                .frame(width: 38, height: 38)
                .background(
                    (transaction.kind == .income ? Color.green : .red).opacity(0.14),
                    in: .rect(cornerRadius: 12)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.category)
                    .font(.subheadline.weight(.semibold))
                Text(transaction.kind.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(OperationFormatting.amount(transaction.amount, sign: transaction.kind))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(transaction.kind == .income ? .green : .primary)
                Text(timeLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
    }

    private var timeLabel: String {
        if Calendar.current.isDateInToday(transaction.date) {
            return transaction.date.formatted(.dateTime.hour().minute())
        }
        return transaction.date.formatted(
            .dateTime.day().month().locale(Locale(identifier: LocalizationManager.shared.currentLanguage))
        )
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

struct DashboardBackground: View {
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
    let budgetProgress: Double
    let spent: String
    let budget: String
    let insight: String

    static let preview = DashboardSnapshot(
        userName: "Руслан",
        budgetProgress: 0.68,
        spent: "2 904 AZN",
        budget: "4 280 AZN",
        insight: "Расходы на кафе выросли на 24% за последние 2 недели."
    )
}

#Preview("Светлая тема") {
    HomeDashboardView(
        snapshot: .preview,
        fetchTransactions: AppContainer(isStoredInMemoryOnly: true).makeFetchTransactionsUseCase(),
        selectedTab: .constant(.home)
    )
}

#Preview("Тёмная тема") {
    HomeDashboardView(
        snapshot: .preview,
        fetchTransactions: AppContainer(isStoredInMemoryOnly: true).makeFetchTransactionsUseCase(),
        selectedTab: .constant(.home)
    )
    .preferredColorScheme(.dark)
}
