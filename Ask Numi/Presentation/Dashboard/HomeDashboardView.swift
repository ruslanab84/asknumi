//
//  HomeDashboardView.swift
//  Ask Numi
//

import SwiftUI

enum DashboardPalette {
    static let primary = Color(red: 79.0 / 255, green: 70.0 / 255, blue: 229.0 / 255)
    static let avatarHighlight = Color(red: 124.0 / 255, green: 127.0 / 255, blue: 240.0 / 255)
    static let ai = Color(red: 175.0 / 255, green: 82.0 / 255, blue: 222.0 / 255)
    static let income = Color(red: 52.0 / 255, green: 199.0 / 255, blue: 89.0 / 255)
    static let incomeLabel = Color(red: 36.0 / 255, green: 138.0 / 255, blue: 61.0 / 255)
    static let expense = Color(red: 255.0 / 255, green: 59.0 / 255, blue: 48.0 / 255)
}

struct HomeDashboardView: View {
    let snapshot: DashboardSnapshot
    let fetchTransactions: FetchTransactionsUseCase
    let fetchBudgets: FetchBudgetsUseCase
    let fetchSubscriptions: FetchSubscriptionsUseCase
    let getMonthlyInsight: GetMonthlySpendingInsightUseCase
    let getFinancialTwin: GetFinancialTwinUseCase
    let showBudgets: () -> Void
    let showAssistant: () -> Void
    @State private var isShowingSettings = false
    @State private var transactions: [Transaction] = []
    @State private var budgets: [Budget] = []
    @State private var subscriptions: [Subscription] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var insightState: DashboardInsightState = .loading
    @State private var financialTwinReport = FinancialTwinReport.empty
    @State private var isShowingFinancialTwin = false

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
                DashboardBackground(isNeutral: true)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        DashboardHeader(name: snapshot.userName) {
                            isShowingSettings = true
                        }
                        FinancialOverviewSection(summary: summary, isLoading: isLoading)

                        if let errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.red.opacity(0.08), in: .rect(cornerRadius: 16))
                        }

                        AttentionCarousel(
                            overview: budgetOverview,
                            isLoading: isLoading,
                            report: financialTwinReport,
                            insightState: insightState,
                            showBudgets: showBudgets,
                            showFinancialTwin: { isShowingFinancialTwin = true },
                            showInsight: showAssistant
                        )
                        RecentTransactions(transactions: recentTransactions)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                .scrollEdgeEffectStyle(.soft, for: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $isShowingFinancialTwin) {
                FinancialTwinDetailsView(report: financialTwinReport)
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
            async let loadedSubscriptions = fetchSubscriptions.execute()
            transactions = try await loadedTransactions
            budgets = try await loadedBudgets
            subscriptions = try await loadedSubscriptions
            financialTwinReport = getFinancialTwin.execute(
                transactions: transactions,
                budgets: budgets,
                subscriptions: subscriptions
            )
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
                insightState = .content(fallbackInsight)
            } catch {
                insightState = .failed
            }
        case .downloading:
            insightState = .downloading
        case .unavailable:
            insightState = .unavailable
        }
    }

    private var fallbackInsight: String {
        if let category = summary.expensesByCategory.first {
            return L10n.Dashboard.insightTopCategory(
                category.category,
                OperationFormatting.plain(category.amount),
                CurrencySettings.selectedCode
            )
        }
        if summary.totalIncome > 0 {
            return L10n.Dashboard.insightRecordedIncome(
                OperationFormatting.plain(summary.totalIncome),
                CurrencySettings.selectedCode
            )
        }
        return L10n.Dashboard.insightEmpty
    }
}

private struct DashboardHeader: View {
    let name: String
    let showSettings: () -> Void

    var body: some View {
        ZStack {
            Text("Ask Numi")
                .font(.headline)

            HStack {
                Button(action: showSettings) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [DashboardPalette.avatarHighlight, DashboardPalette.primary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text(name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(DashboardPalette.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: 72, alignment: .leading)
                    }
                    .padding(.leading, 8)
                    .padding(.trailing, 12)
                    .padding(.vertical, 8)
                    .glassEffect(
                        .regular.tint(DashboardPalette.primary.opacity(0.12)).interactive(),
                        in: .capsule
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.Dashboard.settingsLabel)

                Spacer()

                Image(systemName: "bell")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .glassEffect(.regular, in: .circle)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44)
    }
}

private struct FinancialOverviewSection: View {
    let summary: FinancialSummary
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            BalanceHero(summary: summary, isLoading: isLoading)
            IncomeExpenseRow(summary: summary, isLoading: isLoading)
        }
    }
}

private struct BalanceHero: View {
    let summary: FinancialSummary
    let isLoading: Bool
    @ScaledMetric(relativeTo: .largeTitle) private var balanceFontSize = 40.0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(L10n.Dashboard.totalBalance)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)

                Image(systemName: "eye")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }

            Text(OperationFormatting.plain(summary.balance))
                .font(.system(size: balanceFontSize, weight: .heavy, design: .rounded))
                .tracking(-0.6)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())
                .redacted(reason: isLoading ? .placeholder : [])
        }
        .accessibilityElement(children: .combine)
    }
}

private struct IncomeExpenseRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let summary: FinancialSummary
    let isLoading: Bool

    private var layout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 12))
            : AnyLayout(HStackLayout(spacing: 12))
    }

    var body: some View {
        layout {
            metric(
                title: L10n.Dashboard.income,
                systemImage: "arrow.down",
                amount: OperationFormatting.amount(summary.totalIncome, sign: .income),
                labelColor: DashboardPalette.incomeLabel,
                amountColor: .primary,
                backgroundColor: DashboardPalette.income.opacity(0.1)
            )
            metric(
                title: L10n.Dashboard.expenses,
                systemImage: "arrow.up",
                amount: OperationFormatting.amount(summary.totalExpenses, sign: .expense),
                labelColor: DashboardPalette.expense,
                amountColor: DashboardPalette.expense,
                backgroundColor: DashboardPalette.expense.opacity(0.08)
            )
        }
        .redacted(reason: isLoading ? .placeholder : [])
    }

    private func metric(
        title: String,
        systemImage: String,
        amount: String,
        labelColor: Color,
        amountColor: Color,
        backgroundColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(title, systemImage: systemImage)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(labelColor)
            Text(amount)
                .font(.headline)
                .foregroundStyle(amountColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(backgroundColor), in: .rect(cornerRadius: 18))
    }
}

private enum AttentionPage: CaseIterable, Hashable {
    case budget
    case financialTwin
    case insight
}

private struct AttentionCarousel: View {
    let overview: BudgetOverview
    let isLoading: Bool
    let report: FinancialTwinReport
    let insightState: DashboardInsightState
    let showBudgets: () -> Void
    let showFinancialTwin: () -> Void
    let showInsight: () -> Void
    @State private var activePage: AttentionPage? = .budget

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.Dashboard.attentionTitle)
                    .font(.headline)

                Spacer()

                HStack(spacing: 6) {
                    ForEach(AttentionPage.allCases, id: \.self) { page in
                        Circle()
                            .fill(DashboardPalette.ai)
                            .frame(width: 6, height: 6)
                            .scaleEffect(activePage == page ? 1 : 0.72)
                            .opacity(activePage == page ? 1 : 0.2)
                    }
                }
                .animation(.snappy, value: activePage)
                .accessibilityHidden(true)
            }

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    BudgetCard(overview: overview, isLoading: isLoading, onTap: showBudgets)
                        .containerRelativeFrame(.horizontal, count: 5, span: 4, spacing: 12)
                        .id(AttentionPage.budget)
                    FinancialTwinSummaryCard(
                        report: report,
                        isLoading: isLoading,
                        showDetails: showFinancialTwin
                    )
                    .containerRelativeFrame(.horizontal, count: 5, span: 4, spacing: 12)
                    .id(AttentionPage.financialTwin)
                    InsightCard(state: insightState, showDetails: showInsight)
                        .containerRelativeFrame(.horizontal, count: 5, span: 4, spacing: 12)
                        .id(AttentionPage.insight)
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $activePage)
            .scrollClipDisabled()
        }
    }
}

private struct BudgetCard: View {
    let overview: BudgetOverview
    let isLoading: Bool
    let onTap: () -> Void

    var body: some View {
        AttentionCard(
            title: overview.items.isEmpty && !isLoading ? L10n.Dashboard.budgetEmptyTitle : monthTitle,
            systemImage: "chart.bar.fill",
            tint: DashboardPalette.income,
            isEnabled: true,
            action: onTap
        ) {
            Text(message)
                .redacted(reason: isLoading ? .placeholder : [])
        }
    }

    private var message: String {
        guard !overview.items.isEmpty else {
            return L10n.Dashboard.budgetEmptyMessage
        }
        return "\(progress.formatted(.percent.precision(.fractionLength(0)))) · \(remainingText)"
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

}

struct AttentionCard<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    let systemImage: String
    let tint: Color
    let isEnabled: Bool
    let action: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(tint)
                        .frame(width: 36, height: 36)
                        .background(tint.opacity(0.14), in: .rect(cornerRadius: 12))
                        .accessibilityHidden(true)

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(tint.opacity(0.7))
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)

                    content
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
            .background(tint.opacity(0.05), in: .rect(cornerRadius: 22))
            .glassEffect(
                .regular.tint(tint.opacity(0.12)).interactive(),
                in: .rect(cornerRadius: 22)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(tint.opacity(0.18), lineWidth: 1)
            }
            .contentShape(.rect(cornerRadius: 22))
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

private struct InsightCard: View {
    let state: DashboardInsightState
    let showDetails: () -> Void

    var body: some View {
        AttentionCard(
            title: L10n.Dashboard.insightTitle,
            systemImage: "sparkles",
            tint: DashboardPalette.ai,
            isEnabled: state.showsDetails,
            action: showDetails
        ) {
            insightContent
        }
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
        case .downloading:
            status(L10n.Assistant.noticeDownloading)
        case .unavailable:
            status(L10n.Assistant.noticeUnavailable)
        case .failed:
            status(L10n.Assistant.errorGeneric)
        }
    }

    private func status(_ text: String) -> some View {
        Text(text)
    }
}

private enum DashboardInsightState {
    case loading
    case content(String)
    case downloading
    case unavailable
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

            Group {
                if transactions.isEmpty {
                    Text(L10n.Dashboard.recentEmpty)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 16)
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
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color(uiColor: .secondarySystemBackground).opacity(0.45),
                in: .rect(cornerRadius: 22)
            )
            .glassEffect(.regular, in: .rect(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(.primary.opacity(0.04), lineWidth: 1)
            }
            .shadow(
                color: Color(red: 20.0 / 255, green: 20.0 / 255, blue: 50.0 / 255).opacity(0.05),
                radius: 12,
                y: 8
            )
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

struct GlassCard<Content: View>: View {
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
    var isNeutral = false

    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [.black, Color(red: 0.02, green: 0.06, blue: 0.12), Color(red: 0.06, green: 0.02, blue: 0.16)]
                : lightColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var lightColors: [Color] {
        isNeutral
            ? [Color(red: 246.0 / 255, green: 247.0 / 255, blue: 251.0 / 255), .white]
            : [Color(red: 0.96, green: 0.97, blue: 1), .white, Color(red: 0.95, green: 1, blue: 0.98)]
    }
}

struct DashboardSnapshot {
    let userName: String

    static let preview = DashboardSnapshot(
        userName: "Руслан"
    )
}

#Preview("Светлая тема") {
    let container = AppContainer(isStoredInMemoryOnly: true)
    HomeDashboardView(
        snapshot: .preview,
        fetchTransactions: container.makeFetchTransactionsUseCase(),
        fetchBudgets: container.makeFetchBudgetsUseCase(),
        fetchSubscriptions: container.makeFetchSubscriptionsUseCase(),
        getMonthlyInsight: container.makeMonthlySpendingInsightUseCase(),
        getFinancialTwin: container.makeFinancialTwinUseCase(),
        showBudgets: {},
        showAssistant: {}
    )
}

#Preview("Тёмная тема") {
    let container = AppContainer(isStoredInMemoryOnly: true)
    HomeDashboardView(
        snapshot: .preview,
        fetchTransactions: container.makeFetchTransactionsUseCase(),
        fetchBudgets: container.makeFetchBudgetsUseCase(),
        fetchSubscriptions: container.makeFetchSubscriptionsUseCase(),
        getMonthlyInsight: container.makeMonthlySpendingInsightUseCase(),
        getFinancialTwin: container.makeFinancialTwinUseCase(),
        showBudgets: {},
        showAssistant: {}
    )
    .preferredColorScheme(.dark)
}
