//
//  HomeDashboardView.swift
//  Ask Numi
//

import Charts
import SwiftUI

enum DashboardPalette {
    static let primary = Color(red: 79.0 / 255, green: 70.0 / 255, blue: 229.0 / 255)
    static let avatarHighlight = Color(red: 124.0 / 255, green: 127.0 / 255, blue: 240.0 / 255)
    static let ai = Color(red: 175.0 / 255, green: 82.0 / 255, blue: 222.0 / 255)
    static let income = Color(red: 52.0 / 255, green: 199.0 / 255, blue: 89.0 / 255)
    static let balanceStart = Color(red: 47.0 / 255, green: 99.0 / 255, blue: 236.0 / 255)
    static let balanceEnd = Color(red: 25.0 / 255, green: 45.0 / 255, blue: 151.0 / 255)
    static let spendingCategories: [Color] = [.blue, .purple, .orange]
}

struct HomeDashboardView: View {
    let snapshot: DashboardSnapshot
    let fetchTransactions: FetchTransactionsUseCase
    let fetchBudgets: FetchBudgetsUseCase
    let fetchSubscriptions: FetchSubscriptionsUseCase
    let fetchGoals: FetchSavingsGoalsUseCase
    let getMonthlyInsight: GetMonthlySpendingInsightUseCase
    let getFinancialTwin: GetFinancialTwinUseCase
    let simulatePurchase: SimulatePurchaseUseCase
    let simulateTimeMachine: SimulateFinancialTimeMachineUseCase
    let showBudgets: () -> Void
    let showAssistant: () -> Void
    @State private var isShowingSettings = false
    @State private var transactions: [Transaction] = []
    @State private var budgets: [Budget] = []
    @State private var subscriptions: [Subscription] = []
    @State private var goals: [SavingsGoal] = []
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

    private var currentMonth: DateInterval {
        Calendar.current.dateInterval(of: .month, for: .now)
            ?? DateInterval(start: .distantPast, end: .distantFuture)
    }

    private var monthlyTransactions: [Transaction] {
        transactions.filter { $0.date >= currentMonth.start && $0.date < currentMonth.end }
    }

    private var monthlySummary: FinancialSummary {
        FinancialSummary(transactions: monthlyTransactions, period: currentMonth)
    }

    private var monthlySpending: DashboardSpendingBreakdown {
        DashboardSpendingBreakdown(transactions: monthlyTransactions)
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
                        FinancialOverviewSection(
                            summary: summary,
                            monthlyBalance: monthlySummary.balance,
                            spending: monthlySpending,
                            subscriptions: subscriptions,
                            goals: goals,
                            isLoading: isLoading,
                            hasCommitmentData: errorMessage == nil
                        )

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
                FinancialTwinDetailsView(
                    report: financialTwinReport,
                    transactions: transactions,
                    budgets: budgets,
                    subscriptions: subscriptions,
                    goals: goals,
                    simulatePurchase: simulatePurchase,
                    simulateTimeMachine: simulateTimeMachine
                )
            }
            .task {
                #if DEBUG
                DashboardSpendingBreakdown.assertSelfCheck()
                DashboardMonthlyExpenseComparison.assertSelfCheck()
                #endif
                await loadDashboard()
            }
        }
    }

    private func loadDashboard() async {
        isLoading = true

        do {
            // Fetching transactions first posts due subscriptions and advances their next charge date.
            transactions = try await fetchTransactions.execute()
            async let loadedBudgets = fetchBudgets.execute()
            async let loadedSubscriptions = fetchSubscriptions.execute()
            async let loadedGoals = fetchGoals.execute()
            budgets = try await loadedBudgets
            subscriptions = try await loadedSubscriptions
            goals = try await loadedGoals
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
        let comparison = DashboardMonthlyExpenseComparison(transactions: transactions)
        if comparison.current > 0 || comparison.previous > 0 {
            return L10n.Dashboard.insightMonthComparison(
                OperationFormatting.plain(comparison.current),
                OperationFormatting.plain(comparison.previous)
            )
        }
        if monthlySummary.totalIncome > 0 {
            return L10n.Dashboard.insightRecordedIncome(OperationFormatting.plain(monthlySummary.totalIncome))
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
    let monthlyBalance: Decimal
    let spending: DashboardSpendingBreakdown
    let subscriptions: [Subscription]
    let goals: [SavingsGoal]
    let isLoading: Bool
    let hasCommitmentData: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            BalanceHero(summary: summary, monthlyBalance: monthlyBalance, isLoading: isLoading)
            SafeToSpendCard(
                subscriptions: subscriptions,
                goals: goals,
                isLoading: isLoading,
                hasCommitmentData: hasCommitmentData
            )
            SpendingOverviewCard(breakdown: spending, isLoading: isLoading)
            DailyMoneyTipCard()
        }
    }
}

private struct BalanceHero: View {
    let summary: FinancialSummary
    let monthlyBalance: Decimal
    let isLoading: Bool
    @State private var isBalanceHidden = false
    @ScaledMetric(relativeTo: .largeTitle) private var balanceFontSize = 38.0

    private var monthlyTint: Color {
        if monthlyBalance > 0 { return DashboardPalette.income }
        if monthlyBalance < 0 { return Color(red: 1, green: 0.58, blue: 0.56) }
        return .white.opacity(0.72)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(L10n.Dashboard.totalBalance)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.76))

                Spacer()

                Button {
                    isBalanceHidden.toggle()
                } label: {
                    Image(systemName: isBalanceHidden ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.13), in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    isBalanceHidden ? L10n.Dashboard.showBalance : L10n.Dashboard.hideBalance
                )
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(isBalanceHidden ? "••••••" : OperationFormatting.plain(summary.balance))
                    .font(.system(size: balanceFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(summary.balance < 0 ? Color(red: 1, green: 0.78, blue: 0.76) : .white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .contentTransition(.numericText())
                    .privacySensitive()
                    .redacted(reason: isLoading ? .placeholder : [])

                HStack(spacing: 5) {
                    Image(systemName: monthlyBalance >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text(OperationFormatting.plain(monthlyBalance))
                    Text(L10n.Dashboard.thisMonth)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(monthlyTint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .redacted(reason: isLoading ? .placeholder : [])
            }

            HStack(spacing: 8) {
                Text(CurrencySettings.flag(for: CurrencySettings.selectedCode))
                    .accessibilityHidden(true)
                Text(CurrencySettings.selectedCode)
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(.white.opacity(0.14), in: .capsule)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [DashboardPalette.balanceStart, DashboardPalette.balanceEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: .rect(cornerRadius: 22)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: DashboardPalette.balanceEnd.opacity(0.24), radius: 16, y: 10)
        .animation(.snappy, value: isBalanceHidden)
    }
}

private struct DashboardSpendingCategory: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let amount: Decimal
}

private struct DashboardSpendingBreakdown {
    let total: Decimal
    let categories: [DashboardSpendingCategory]

    init(transactions: [Transaction]) {
        let summary = FinancialSummary(
            transactions: transactions,
            period: DateInterval(start: .distantPast, end: .distantFuture)
        )
        let topCategories = Array(summary.expensesByCategory.prefix(3))

        total = summary.totalExpenses
        categories = topCategories.enumerated().map { index, item in
            let transaction = transactions.first {
                $0.kind == .expense && $0.category == item.category
            }
            return DashboardSpendingCategory(
                id: "category:\(item.category)",
                name: item.category,
                icon: transaction?.categoryIcon ?? CategoryIcon.fallback,
                color: DashboardPalette.spendingCategories[index],
                amount: item.amount
            )
        } + {
            let other = summary.totalExpenses - topCategories.reduce(Decimal.zero) { $0 + $1.amount }
            guard other > 0 else { return [] }
            return [DashboardSpendingCategory(
                id: "other",
                name: L10n.Assistant.chartOther,
                icon: "ellipsis",
                color: .secondary,
                amount: other
            )]
        }()
    }

    func share(of amount: Decimal) -> Double {
        guard total > 0 else { return 0 }
        return NSDecimalNumber(decimal: amount / total).doubleValue
    }

    #if DEBUG
    static func assertSelfCheck() {
        let transactions = [
            Transaction(amount: 40, kind: .expense, category: "A", categoryColor: .blue),
            Transaction(amount: 30, kind: .expense, category: "B", categoryColor: .green),
            Transaction(amount: 20, kind: .expense, category: "C", categoryColor: .orange),
            Transaction(amount: 10, kind: .expense, category: "D", categoryColor: .purple),
            Transaction(amount: 200, kind: .income, category: "Income", categoryColor: .green)
        ]
        let breakdown = DashboardSpendingBreakdown(transactions: transactions)

        assert(breakdown.total == 100)
        assert(breakdown.categories.count == 4)
        assert(breakdown.categories.last?.amount == 10)
        assert(breakdown.share(of: 40) == 0.4)
    }
    #endif
}

private struct DashboardMonthlyExpenseComparison {
    let current: Decimal
    let previous: Decimal

    init(
        transactions: [Transaction],
        now: Date = .now,
        calendar: Calendar = .current
    ) {
        guard let currentPeriod = calendar.dateInterval(of: .month, for: now),
              let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentPeriod.start),
              let previousPeriod = calendar.dateInterval(of: .month, for: previousMonth) else {
            current = 0
            previous = 0
            return
        }

        let currentEnd = min(now, currentPeriod.end)
        let elapsed = calendar.dateComponents(
            [.day, .hour, .minute, .second],
            from: currentPeriod.start,
            to: currentEnd
        )
        let previousEnd = min(
            calendar.date(byAdding: elapsed, to: previousPeriod.start) ?? previousPeriod.end,
            previousPeriod.end
        )
        current = Self.total(in: transactions, from: currentPeriod.start, to: currentEnd)
        previous = Self.total(in: transactions, from: previousPeriod.start, to: previousEnd)
    }

    private static func total(in transactions: [Transaction], from start: Date, to end: Date) -> Decimal {
        transactions.reduce(Decimal.zero) { total, transaction in
            guard transaction.kind == .expense,
                  transaction.date >= start,
                  transaction.date < end else { return total }
            return total + transaction.amount
        }
    }

    #if DEBUG
    static func assertSelfCheck() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let date = { (month: Int, day: Int) in
            calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
        }
        let comparison = DashboardMonthlyExpenseComparison(
            transactions: [
                Transaction(amount: 10, kind: .expense, category: "Current", date: date(7, 10)),
                Transaction(amount: 90, kind: .expense, category: "Future", date: date(7, 25)),
                Transaction(amount: 7, kind: .expense, category: "Previous", date: date(6, 10)),
                Transaction(amount: 80, kind: .expense, category: "Old future", date: date(6, 25)),
                Transaction(amount: 100, kind: .income, category: "Income", date: date(7, 10))
            ],
            now: date(7, 20),
            calendar: calendar
        )

        assert(comparison.current == 10)
        assert(comparison.previous == 7)
    }
    #endif
}

private struct SpendingOverviewCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let breakdown: DashboardSpendingBreakdown
    let isLoading: Bool

    private var categoryColumns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), alignment: .leading),
            count: dynamicTypeSize.isAccessibilitySize ? 1 : 2
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.Dashboard.spendingOverview)
                    .font(.headline)

                Spacer()

                Text(L10n.Dashboard.thisMonth)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if breakdown.categories.isEmpty && !isLoading {
                ContentUnavailableView(
                    L10n.Dashboard.spendingEmpty,
                    systemImage: "chart.pie"
                )
                .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 20) {
                        spendingTotal
                        Spacer(minLength: 0)
                        spendingChart
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        spendingTotal
                        spendingChart
                            .frame(maxWidth: .infinity)
                    }
                }
                .redacted(reason: isLoading ? .placeholder : [])

                LazyVGrid(columns: categoryColumns, alignment: .leading, spacing: 14) {
                    ForEach(breakdown.categories) { category in
                        categoryRow(category)
                    }
                }
                .redacted(reason: isLoading ? .placeholder : [])
            }
        }
        .padding(18)
        .background(
            Color(uiColor: .secondarySystemBackground).opacity(0.58),
            in: .rect(cornerRadius: 22)
        )
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(.primary.opacity(0.05), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.05), radius: 12, y: 8)
    }

    private var spendingTotal: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(L10n.Dashboard.spent)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(OperationFormatting.plain(breakdown.total))
                .font(.title2.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .contentTransition(.numericText())
        }
    }

    private var spendingChart: some View {
        Chart(breakdown.categories) { category in
            SectorMark(
                angle: .value(
                    L10n.Dashboard.spent,
                    NSDecimalNumber(decimal: category.amount).doubleValue
                ),
                innerRadius: .ratio(0.62),
                angularInset: 2
            )
            .cornerRadius(3)
            .foregroundStyle(category.color)
        }
        .frame(width: 126, height: 126)
        .chartLegend(.hidden)
        .overlay {
            Image(systemName: "chart.pie.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(DashboardPalette.primary)
        }
        .accessibilityHidden(true)
    }

    private func categoryRow(_ category: DashboardSpendingCategory) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 7) {
                Image(systemName: category.icon)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(category.color)
                    .frame(width: 22, height: 22)
                    .background(category.color.opacity(0.12), in: .rect(cornerRadius: 6))
                    .accessibilityHidden(true)

                Text(category.name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 4)

                Text(breakdown.share(of: category.amount).formatted(
                    .percent.precision(.fractionLength(0))
                ))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            }

            Text(OperationFormatting.plain(category.amount))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct DailyMoneyTipCard: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.scenePhase) private var scenePhase
    @State private var date = Date.now

    private var tip: String {
        let tips = L10n.Dashboard.dailyTips
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 1
        return tips[(day - 1) % tips.count]
    }

    var body: some View {
        GlassCard(tint: DashboardPalette.primary.opacity(0.12)) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb.max.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DashboardPalette.primary)
                    .padding(10)
                    .background(DashboardPalette.primary.opacity(0.12), in: .rect(cornerRadius: 12))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Dashboard.dailyTipTitle)
                        .font(.subheadline.weight(.bold))
                    Text(tip)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                date = .now
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            date = .now
        }
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
        fetchGoals: container.makeFetchSavingsGoalsUseCase(),
        getMonthlyInsight: container.makeMonthlySpendingInsightUseCase(),
        getFinancialTwin: container.makeFinancialTwinUseCase(),
        simulatePurchase: container.makePurchaseSimulatorUseCase(),
        simulateTimeMachine: container.makeFinancialTimeMachineUseCase(),
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
        fetchGoals: container.makeFetchSavingsGoalsUseCase(),
        getMonthlyInsight: container.makeMonthlySpendingInsightUseCase(),
        getFinancialTwin: container.makeFinancialTwinUseCase(),
        simulatePurchase: container.makePurchaseSimulatorUseCase(),
        simulateTimeMachine: container.makeFinancialTimeMachineUseCase(),
        showBudgets: {},
        showAssistant: {}
    )
    .preferredColorScheme(.dark)
}
