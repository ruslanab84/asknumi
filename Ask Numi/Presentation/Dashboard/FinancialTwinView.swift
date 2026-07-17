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
        Button(action: showDetails) {
            GlassCard(tint: .orange.opacity(0.15)) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.title3)
                        .foregroundStyle(.orange)
                        .frame(width: 38, height: 38)
                        .background(.orange.opacity(0.15), in: .circle)

                    VStack(alignment: .leading, spacing: 7) {
                        Text(L10n.Dashboard.financialTwinTitle)
                            .font(.subheadline.weight(.bold))
                        Text(summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                        Text(L10n.Dashboard.financialTwinDetails)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                    Spacer(minLength: 0)
                }
                .redacted(reason: isLoading ? .placeholder : [])
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
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

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DashboardBackground()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        Label(L10n.FinancialTwin.privacy, systemImage: "lock.shield.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(L10n.FinancialTwin.sources(
                            report.transactionCount,
                            report.budgetCount,
                            report.subscriptionCount
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        if report.insights.isEmpty {
                            ContentUnavailableView(
                                L10n.FinancialTwin.emptyTitle,
                                systemImage: "chart.dots.scatter",
                                description: Text(L10n.FinancialTwin.emptyMessage)
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 36)
                        } else {
                            ForEach(report.insights) { insight in
                                FinancialTwinInsightCard(content: FinancialTwinInsightContent(insight))
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle(L10n.FinancialTwin.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.FinancialTwin.close) { dismiss() }
                }
            }
        }
    }
}

private struct FinancialTwinInsightCard: View {
    let content: FinancialTwinInsightContent

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(content.title, systemImage: content.icon)
                .font(.headline)
                .foregroundStyle(content.color)

            Text(content.headline)
                .font(.body.weight(.semibold))

            Divider()

            Text(L10n.FinancialTwin.evidenceTitle)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            ForEach(Array(content.evidence.enumerated()), id: \.offset) { _, line in
                Label {
                    Text(line)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 5))
                        .foregroundStyle(content.color)
                }
            }

            Text(L10n.FinancialTwin.methodTitle)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Text(content.method)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(content.color.opacity(0.1)), in: .rect(cornerRadius: 22))
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
        let currency = CurrencySettings.selectedCode
        switch insight {
        case .cashFlowSnapshot(let value):
            title = L10n.FinancialTwin.snapshotTitle
            if let category = value.topExpenseCategory {
                headline = L10n.FinancialTwin.snapshotTopCategory(
                    category,
                    Self.amount(value.topExpenseAmount),
                    currency,
                    value.topExpenseSharePercent
                )
            } else {
                headline = L10n.FinancialTwin.snapshotBalance(Self.amount(value.balance), currency)
            }
            evidence = [
                L10n.FinancialTwin.snapshotTotals(
                    Self.amount(value.totalIncome),
                    Self.amount(value.totalExpenses),
                    Self.amount(value.balance),
                    currency,
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
                    Self.amount(value.baselineFiveDayAverage),
                    currency
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
                    Self.amount(value.matchingAmount),
                    currency
                )
            ] + value.samples.map {
                L10n.FinancialTwin.impulseSample(Self.dateTime($0.date), Self.amount($0.amount), currency)
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
                    Self.amount($0.spentAtCrossing),
                    currency
                )
            }
            method = L10n.FinancialTwin.budgetMethod
            icon = "gauge.with.dots.needle.67percent"
            color = .red

        case .monthEndBalance(let value):
            title = L10n.FinancialTwin.monthEndTitle
            headline = L10n.FinancialTwin.monthEndHeadline(Self.amount(value.medianBalance), currency)
            evidence = value.samples.map {
                L10n.FinancialTwin.monthEndSample(
                    Self.month($0.month),
                    Self.amount($0.income),
                    Self.amount($0.expenses),
                    Self.amount($0.balance),
                    currency
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
                    currency,
                    candidate.occurrenceCount
                )] + candidate.samples.map {
                    L10n.FinancialTwin.recurringSample(Self.date($0.date), Self.amount($0.amount), currency)
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
