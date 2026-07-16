//
//  HomeDashboardView.swift
//  Ask Numi
//

import SwiftUI

struct HomeDashboardView: View {
    let snapshot: DashboardSnapshot
    let fetchTransactions: FetchTransactionsUseCase
    let fetchBudgets: FetchBudgetsUseCase
    let getMonthlyInsight: GetMonthlySpendingInsightUseCase
    let showBudgets: () -> Void
    @Binding var selectedTab: AppTab
    @State private var isShowingSettings = false
    @State private var transactions: [Transaction] = []
    @State private var budgets: [Budget] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var insightState: DashboardInsightState = .loading

    private var summary: FinancialSummary {
        FinancialSummary(
            transactions: transactions,
            period: DateInterval(start: .distantPast, end: .distantFuture)
        )
    }

    private var recentTransactions: [Transaction] {
        Array(transactions.sorted { $0.date > $1.date }.prefix(5))
    }

    private var budgetOverview: BudgetOverview {
        BudgetOverview(budgets: budgets, transactions: transactions)
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

                            BudgetCard(
                                overview: budgetOverview,
                                isLoading: isLoading,
                                onTap: showBudgets
                            )
                            InsightCard(state: insightState) {
                                selectedTab = .assistant
                            }
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
                await loadDashboard()
            }
        }
    }

    private func loadDashboard() async {
        isLoading = true

        do {
            async let loadedTransactions = fetchTransactions.execute()
            async let loadedBudgets = fetchBudgets.execute()
            transactions = try await loadedTransactions
            budgets = try await loadedBudgets
            errorMessage = nil
            isLoading = false
            await loadInsight()
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            insightState = .failed
        }
    }

    private func loadInsight() async {
        switch getMonthlyInsight.advisorAvailability {
        case .available:
            do {
                let advice = try await getMonthlyInsight.execute(transactions: transactions)
                insightState = .content(advice.headline)
            } catch DomainError.notEnoughData {
                insightState = .notEnoughData
            } catch {
                insightState = .failed
            }
        case .downloading:
            insightState = .downloading
        case .unavailable:
            insightState = .unavailable
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
                            .foregroundStyle(.red)
                    }
                }
                .redacted(reason: isLoading ? .placeholder : [])
            }
        }
    }
}

private struct BudgetCard: View {
    let overview: BudgetOverview
    let isLoading: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            GlassCard(tint: cardColor.opacity(0.12)) {
                if isLoading || !overview.items.isEmpty {
                    budgetSummary
                        .redacted(reason: isLoading ? .placeholder : [])
                } else {
                    budgetEmptyState
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var budgetSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(monthTitle)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(progress.formatted(.percent.precision(.fractionLength(0))))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(cardColor)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: min(max(progress, 0), 1))
                .tint(cardColor)

            HStack {
                AmountCaption(
                    title: L10n.Dashboard.spent,
                    value: OperationFormatting.plain(overview.totalSpent)
                )
                Spacer()
                AmountCaption(
                    title: L10n.Dashboard.budgetPlan,
                    value: OperationFormatting.plain(overview.totalLimit),
                    alignment: .trailing
                )
            }

            HStack {
                Text(remainingText)
                Spacer()
                if overview.remaining >= 0 {
                    Text(L10n.Dashboard.budgetPerDay(OperationFormatting.plain(overview.dailyAllowance)))
                }
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(overview.remaining < 0 ? .red : .secondary)
        }
    }

    private var budgetEmptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(monthTitle)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            Label(L10n.Dashboard.budgetEmptyTitle, systemImage: "chart.bar.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.mint)
            Text(L10n.Dashboard.budgetEmptyMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(L10n.Dashboard.budgetSetup)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.mint)
        }
    }

    private var monthTitle: String {
        let month = overview.period.start.formatted(
            .dateTime
                .month(.wide)
                .year()
                .locale(Locale(identifier: LocalizationManager.shared.currentLanguage))
        )
        return L10n.Dashboard.budgetTitle(month)
    }

    private var progress: Double {
        guard overview.totalLimit > 0 else { return 0 }
        return NSDecimalNumber(decimal: overview.totalSpent / overview.totalLimit).doubleValue
    }

    private var remainingText: String {
        if overview.remaining < 0 {
            return L10n.Dashboard.budgetOverBy(OperationFormatting.plain(-overview.remaining))
        }
        return L10n.Dashboard.budgetRemaining(OperationFormatting.plain(overview.remaining))
    }

    private var cardColor: Color {
        overview.remaining < 0 ? .red : .mint
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
    let state: DashboardInsightState
    let showDetails: () -> Void

    var body: some View {
        Button(action: showDetails) {
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

                        insightContent
                    }
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(!state.showsDetails)
    }

    @ViewBuilder
    private var insightContent: some View {
        switch state {
        case .loading:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text(L10n.Assistant.thinking)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        case .content(let insight):
            Text(insight)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(L10n.Dashboard.insightShowDetails)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.purple)
        case .downloading:
            status(L10n.Assistant.noticeDownloading)
        case .unavailable:
            status(L10n.Assistant.noticeUnavailable)
        case .notEnoughData:
            status(L10n.Dashboard.insightNotEnoughData)
        case .failed:
            status(L10n.Assistant.errorGeneric)
        }
    }

    private func status(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

private enum DashboardInsightState {
    case loading
    case content(String)
    case downloading
    case unavailable
    case notEnoughData
    case failed

    var showsDetails: Bool {
        if case .content = self { true } else { false }
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
                    .foregroundStyle(transaction.kind == .income ? .green : .red)
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

    static let preview = DashboardSnapshot(
        userName: "Руслан"
    )
}

#Preview("Светлая тема") {
    HomeDashboardView(
        snapshot: .preview,
        fetchTransactions: AppContainer(isStoredInMemoryOnly: true).makeFetchTransactionsUseCase(),
        fetchBudgets: AppContainer(isStoredInMemoryOnly: true).makeFetchBudgetsUseCase(),
        getMonthlyInsight: AppContainer(isStoredInMemoryOnly: true).makeMonthlySpendingInsightUseCase(),
        showBudgets: {},
        selectedTab: .constant(.home)
    )
}

#Preview("Тёмная тема") {
    HomeDashboardView(
        snapshot: .preview,
        fetchTransactions: AppContainer(isStoredInMemoryOnly: true).makeFetchTransactionsUseCase(),
        fetchBudgets: AppContainer(isStoredInMemoryOnly: true).makeFetchBudgetsUseCase(),
        getMonthlyInsight: AppContainer(isStoredInMemoryOnly: true).makeMonthlySpendingInsightUseCase(),
        showBudgets: {},
        selectedTab: .constant(.home)
    )
    .preferredColorScheme(.dark)
}
