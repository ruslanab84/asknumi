//
//  FinancialTwinView.swift
//  Ask Numi
//

import SwiftUI

struct FinancialTwinSummaryCard: View {
    let report: FinancialTwinReport
    let isLoading: Bool
    let showDetails: () -> Void

    var body: some View {
        AttentionCard(
            title: L10n.Dashboard.financialTwinTitle,
            systemImage: "person.crop.circle.badge.checkmark",
            tint: DashboardPalette.primary,
            isEnabled: !isLoading,
            action: showDetails
        ) {
            Text(summary)
                .redacted(reason: isLoading ? .placeholder : [])
        }
    }

    private var summary: String {
        guard let insight = report.insights.first else {
            return L10n.Dashboard.financialTwinEmpty
        }
        return FinancialTwinInsightContent(insight).headline
    }
}

struct FinancialTwinDetailsView: View {
    let report: FinancialTwinReport
    let transactions: [Transaction]
    let budgets: [Budget]
    let subscriptions: [Subscription]
    let goals: [SavingsGoal]
    let simulatePurchase: SimulatePurchaseUseCase

    @Environment(\.dismiss) private var dismiss
    @State private var isShowingPurchaseDecision = false

    var body: some View {
        NavigationStack {
            ZStack {
                DashboardBackground()

                ScrollView {
                    GlassEffectContainer(spacing: 12) {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            FinancialTwinHero(report: report)

                            Button {
                                isShowingPurchaseDecision = true
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "cart.badge.questionmark")
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .frame(width: 46, height: 46)
                                        .background(DashboardPalette.primary, in: .rect(cornerRadius: 15))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(L10n.PurchaseDecision.title)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text(L10n.PurchaseDecision.launchSubtitle)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    Spacer(minLength: 8)
                                    Image(systemName: "chevron.right")
                                        .font(.footnote.weight(.bold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(18)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(.rect)
                                .glassEffect(
                                    .regular.tint(DashboardPalette.primary.opacity(0.12)).interactive(),
                                    in: .rect(cornerRadius: 24)
                                )
                            }
                            .buttonStyle(.plain)

                            if report.insights.isEmpty {
                                ContentUnavailableView(
                                    L10n.FinancialTwin.emptyTitle,
                                    systemImage: "chart.dots.scatter",
                                    description: Text(L10n.FinancialTwin.emptyMessage)
                                )
                                .frame(maxWidth: .infinity)
                                .padding(28)
                                .glassEffect(.regular, in: .rect(cornerRadius: 24))
                            } else {
                                ForEach(report.insights) { insight in
                                    FinancialTwinInsightCard(content: FinancialTwinInsightContent(insight))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }
                }
                .scrollIndicators(.hidden)
                .scrollEdgeEffectStyle(.soft, for: .top)
            }
            .navigationTitle(L10n.FinancialTwin.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.FinancialTwin.close) { dismiss() }
                }
            }
            .sheet(isPresented: $isShowingPurchaseDecision) {
                PurchaseDecisionView(
                    transactions: transactions,
                    budgets: budgets,
                    subscriptions: subscriptions,
                    goals: goals,
                    simulatePurchase: simulatePurchase
                )
            }
        }
    }
}

private struct FinancialTwinHero: View {
    let report: FinancialTwinReport

    @Environment(\.appAccentColor) private var accentColor
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var headerLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
    }

    private var sourcesLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 10))
            : AnyLayout(HStackLayout(spacing: 10))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerLayout {
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: "person.crop.circle.dashed")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(accentColor)
                        .frame(width: 66, height: 66)
                        .background(accentColor.opacity(0.12), in: .circle)

                    Image(systemName: "lock.shield.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(accentColor, in: .circle)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.FinancialTwin.privacy)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(L10n.FinancialTwin.sources(
                        report.transactionCount,
                        report.budgetCount,
                        report.subscriptionCount
                    ))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()
                .overlay(accentColor.opacity(0.18))

            sourcesLayout {
                FinancialTwinSourceMetric(
                    title: L10n.Tab.operations,
                    value: report.transactionCount,
                    systemImage: "arrow.left.arrow.right"
                )
                FinancialTwinSourceMetric(
                    title: L10n.Plan.sectionBudgets,
                    value: report.budgetCount,
                    systemImage: "chart.bar.fill"
                )
                FinancialTwinSourceMetric(
                    title: L10n.Plan.sectionPayments,
                    value: report.subscriptionCount,
                    systemImage: "repeat.circle.fill"
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(accentColor.opacity(0.14)), in: .rect(cornerRadius: 26))
        .overlay {
            RoundedRectangle(cornerRadius: 26)
                .stroke(accentColor.opacity(0.16), lineWidth: 1)
        }
    }
}

private struct FinancialTwinSourceMetric: View {
    let title: String
    let value: Int
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text(value, format: .number)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .contentTransition(.numericText())

            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background(.primary.opacity(0.04), in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

private struct FinancialTwinInsightCard: View {
    let content: FinancialTwinInsightContent

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: content.icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(content.color)
                    .frame(width: 46, height: 46)
                    .background(content.color.opacity(0.14), in: .rect(cornerRadius: 15))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text(content.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(content.color)

                    Text(content.headline)
                        .font(.title3.weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Label(L10n.FinancialTwin.evidenceTitle, systemImage: "checkmark.seal.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.primary)

                ForEach(Array(content.evidence.enumerated()), id: \.offset) { _, line in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 5))
                            .foregroundStyle(content.color)
                            .padding(.top, 6)
                            .accessibilityHidden(true)

                        Text(line)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.primary.opacity(0.035), in: .rect(cornerRadius: 16))

            DisclosureGroup {
                Text(content.method)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
            } label: {
                Label(L10n.FinancialTwin.methodTitle, systemImage: "function")
                    .font(.footnote.weight(.semibold))
            }
            .tint(content.color)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(content.color.opacity(0.12)), in: .rect(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(content.color.opacity(0.14), lineWidth: 1)
        }
    }
}

private struct FinancialTwinInsightContent {
    let title: String
    let headline: String
    let evidence: [String]
    let method: String
    let icon: String
    let color: Color

    init(_ insight: FinancialTwinInsight) {
        switch insight {
        case .cashFlowSnapshot(let value):
            title = L10n.FinancialTwin.snapshotTitle
            if let category = value.topExpenseCategory {
                headline = L10n.FinancialTwin.snapshotTopCategory(
                    category,
                    Self.amount(value.topExpenseAmount),
                    value.topExpenseSharePercent
                )
            } else {
                headline = L10n.FinancialTwin.snapshotBalance(Self.amount(value.balance))
            }
            evidence = [
                L10n.FinancialTwin.snapshotTotals(
                    Self.amount(value.totalIncome),
                    Self.amount(value.totalExpenses),
                    Self.amount(value.balance),
                    value.transactionCount
                )
            ]
            method = L10n.FinancialTwin.snapshotMethod
            icon = "chart.pie.fill"
            color = .teal

        case .paydaySpending(let value):
            title = L10n.FinancialTwin.paydayTitle
            headline = L10n.FinancialTwin.paydayHeadline(value.category, value.increasePercent)
            evidence = [
                L10n.FinancialTwin.paydayComparison(
                    value.paydayCount,
                    Self.amount(value.firstFiveDayAverage),
                    Self.amount(value.baselineFiveDayAverage)
                )
            ] + value.paydayDates.map {
                L10n.FinancialTwin.paydayDate(Self.date($0))
            }
            method = L10n.FinancialTwin.paydayMethod
            icon = "banknote.fill"
            color = .green

        case .impulseTiming(let value):
            let weekday = value.samples.first.map { Self.weekday($0.date) } ?? Self.weekday(Date())
            title = L10n.FinancialTwin.impulseTitle
            headline = L10n.FinancialTwin.impulseHeadline(
                weekday,
                L10n.FinancialTwin.dayPart(value.dayPart)
            )
            evidence = [
                L10n.FinancialTwin.impulseSummary(
                    value.matchingCount,
                    value.totalCount,
                    Self.amount(value.matchingAmount)
                )
            ] + value.samples.map {
                L10n.FinancialTwin.impulseSample(Self.dateTime($0.date), Self.amount($0.amount))
            }
            method = L10n.FinancialTwin.impulseMethod
            icon = "bolt.fill"
            color = .orange

        case .budgetOverrun(let value):
            title = L10n.FinancialTwin.budgetTitle
            headline = L10n.FinancialTwin.budgetHeadline
            evidence = value.crossings.map {
                L10n.FinancialTwin.budgetCrossing(
                    $0.category,
                    Self.amount($0.limit),
                    Self.date($0.date),
                    Self.amount($0.spentAtCrossing)
                )
            }
            method = L10n.FinancialTwin.budgetMethod
            icon = "gauge.with.dots.needle.67percent"
            color = .red

        case .monthEndBalance(let value):
            title = L10n.FinancialTwin.monthEndTitle
            headline = L10n.FinancialTwin.monthEndHeadline(Self.amount(value.medianBalance))
            evidence = value.samples.map {
                L10n.FinancialTwin.monthEndSample(
                    Self.month($0.month),
                    Self.amount($0.income),
                    Self.amount($0.expenses),
                    Self.amount($0.balance)
                )
            }
            method = L10n.FinancialTwin.monthEndMethod
            icon = "calendar.badge.clock"
            color = .blue

        case .unplannedRecurring(let value):
            title = L10n.FinancialTwin.recurringTitle
            headline = value.candidates.first.map {
                L10n.FinancialTwin.recurringHeadline($0.name)
            } ?? L10n.FinancialTwin.recurringTitle
            evidence = value.candidates.flatMap { candidate in
                [L10n.FinancialTwin.recurringSummary(
                    candidate.name,
                    Self.amount(candidate.typicalAmount),
                    candidate.occurrenceCount
                )] + candidate.samples.map {
                    L10n.FinancialTwin.recurringSample(Self.date($0.date), Self.amount($0.amount))
                }
            }
            method = L10n.FinancialTwin.recurringMethod
            icon = "repeat.circle.fill"
            color = .indigo
        }
    }

    private static var locale: Locale {
        Locale(identifier: LocalizationManager.shared.currentLanguage)
    }

    private static func amount(_ value: Decimal) -> String {
        OperationFormatting.plain(value)
    }

    private static func date(_ value: Date) -> String {
        value.formatted(.dateTime.day().month(.wide).year().locale(locale))
    }

    private static func dateTime(_ value: Date) -> String {
        value.formatted(.dateTime.day().month(.wide).hour().minute().locale(locale))
    }

    private static func month(_ value: Date) -> String {
        value.formatted(.dateTime.month(.wide).year().locale(locale))
    }

    private static func weekday(_ value: Date) -> String {
        value.formatted(.dateTime.weekday(.wide).locale(locale))
    }
}

#Preview("Insights") {
    FinancialTwinDetailsView(
        report: .preview,
        transactions: [],
        budgets: [],
        subscriptions: [],
        goals: [],
        simulatePurchase: SimulatePurchaseUseCase()
    )
}

#Preview("Empty") {
    FinancialTwinDetailsView(
        report: .empty,
        transactions: [],
        budgets: [],
        subscriptions: [],
        goals: [],
        simulatePurchase: SimulatePurchaseUseCase()
    )
}

private extension FinancialTwinReport {
    static let preview = FinancialTwinReport(
        insights: [
            .cashFlowSnapshot(CashFlowSnapshotInsight(
                totalIncome: 4_800,
                totalExpenses: 3_250,
                balance: 1_550,
                transactionCount: 28,
                topExpenseCategory: "Food",
                topExpenseAmount: 920,
                topExpenseSharePercent: 28
            )),
            .monthEndBalance(MonthEndBalanceInsight(
                medianBalance: 1_420,
                samples: [
                    MonthEndSample(
                        month: Date(timeIntervalSince1970: 1_767_225_600),
                        income: 4_700,
                        expenses: 3_180,
                        balance: 1_520
                    )
                ]
            ))
        ],
        transactionCount: 28,
        budgetCount: 3,
        subscriptionCount: 5
    )
}
