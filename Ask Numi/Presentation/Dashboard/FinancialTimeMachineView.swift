//
//  FinancialTimeMachineView.swift
//  Ask Numi
//

import Charts
import SwiftUI

struct FinancialTimeMachineView: View {
    let transactions: [Transaction]
    let subscriptions: [Subscription]
    let simulate: SimulateFinancialTimeMachineUseCase

    @Environment(\.dismiss) private var dismiss
    @State private var spendingCategory = ""
    @State private var spendingReductionPercent = 15
    @State private var incomeCategory = ""
    @State private var incomeDelayDays = 7
    @State private var subscriptionIncreasePercent = 20
    @State private var monthlySavingsText = "200"
    @State private var horizonMonths = 3
    @State private var report: FinancialTimeMachineReport?
    @State private var errorMessage: String?
    @FocusState private var isSavingsFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                scenarioInputSection

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button(L10n.TimeMachine.calculate) { calculate() }
                        .frame(maxWidth: .infinity)
                        .disabled(monthlySavings == nil)
                }

                if let report {
                    result(report)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background { DashboardBackground() }
            .navigationTitle(L10n.TimeMachine.title)
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
            }
            .onAppear {
                spendingCategory = spendingCategory.isEmpty ? expenseCategories.first ?? "" : spendingCategory
                incomeCategory = incomeCategory.isEmpty ? incomeCategories.first ?? "" : incomeCategory
                if expenseCategories.isEmpty { spendingReductionPercent = 0 }
                if incomeCategories.isEmpty { incomeDelayDays = 0 }
            }
            .onChange(of: inputToken) { _, _ in invalidate() }
        }
    }

    private var scenarioInputSection: some View {
        Section {
            expenseInputs
            incomeInputs

            Stepper(
                L10n.TimeMachine.subscriptionIncrease(subscriptionIncreasePercent),
                value: $subscriptionIncreasePercent,
                in: 0...100,
                step: 5
            )

            HStack {
                TextField(L10n.TimeMachine.monthlySavings, text: $monthlySavingsText)
                    .keyboardType(.decimalPad)
                    .focused($isSavingsFocused)
                Text(currencySymbol)
                    .foregroundStyle(.secondary)
            }

            Picker(L10n.TimeMachine.horizon, selection: $horizonMonths) {
                Text(L10n.TimeMachine.horizonMonths(3)).tag(3)
                Text(L10n.TimeMachine.horizonMonths(6)).tag(6)
                Text(L10n.TimeMachine.horizonMonths(12)).tag(12)
            }
            .pickerStyle(.segmented)
        } header: {
            Text(L10n.TimeMachine.scenarioSection)
        } footer: {
            Text(L10n.TimeMachine.simulationOnly)
        }
    }

    @ViewBuilder
    private var expenseInputs: some View {
        if expenseCategories.isEmpty {
            Text(L10n.TimeMachine.noExpenseData)
                .foregroundStyle(.secondary)
        } else {
            Picker(L10n.TimeMachine.spendingCategory, selection: $spendingCategory) {
                ForEach(expenseCategories, id: \String.self) { Text($0).tag($0) }
            }
            Stepper(
                L10n.TimeMachine.spendingReduction(spendingCategory, spendingReductionPercent),
                value: $spendingReductionPercent,
                in: 0...100,
                step: 5
            )
        }
    }

    @ViewBuilder
    private var incomeInputs: some View {
        if incomeCategories.isEmpty {
            Text(L10n.TimeMachine.noIncomeData)
                .foregroundStyle(.secondary)
        } else {
            Picker(L10n.TimeMachine.incomeCategory, selection: $incomeCategory) {
                ForEach(incomeCategories, id: \String.self) { Text($0).tag($0) }
            }
            Stepper(
                L10n.TimeMachine.incomeDelay(incomeCategory, incomeDelayDays),
                value: $incomeDelayDays,
                in: 0...31
            )
        }
    }

    @ViewBuilder
    private func result(_ report: FinancialTimeMachineReport) -> some View {
        Section(L10n.TimeMachine.outcomeSection) {
            VStack(alignment: .leading, spacing: 14) {
                Text(L10n.TimeMachine.chartTitle)
                    .font(.headline)

                Chart {
                    ForEach(report.months) { month in
                        LineMark(
                            x: .value(L10n.TimeMachine.monthAxis, month.start),
                            y: .value(
                                L10n.TimeMachine.cashFlowAxis,
                                NSDecimalNumber(decimal: month.baselineCumulativeCashFlow).doubleValue
                            )
                        )
                        .foregroundStyle(by: .value(
                            L10n.TimeMachine.chartSeries,
                            L10n.TimeMachine.baseline
                        ))

                        LineMark(
                            x: .value(L10n.TimeMachine.monthAxis, month.start),
                            y: .value(
                                L10n.TimeMachine.cashFlowAxis,
                                NSDecimalNumber(decimal: month.scenarioCumulativeCashFlow).doubleValue
                            )
                        )
                        .foregroundStyle(by: .value(
                            L10n.TimeMachine.chartSeries,
                            L10n.TimeMachine.scenario
                        ))
                    }
                }
                .chartForegroundStyleScale([
                    L10n.TimeMachine.baseline: Color.secondary,
                    L10n.TimeMachine.scenario: DashboardPalette.primary
                ])
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .frame(height: 210)

                resultRow(
                    L10n.TimeMachine.baselineEnd,
                    OperationFormatting.plain(report.baselineEndingCashFlow)
                )
                resultRow(
                    L10n.TimeMachine.scenarioEnd,
                    OperationFormatting.plain(report.scenarioEndingCashFlow)
                )
                resultRow(
                    L10n.TimeMachine.difference,
                    OperationFormatting.plain(report.difference)
                )
            }
            .padding(.vertical, 6)
        }

        Section(L10n.TimeMachine.factorsSection) {
            if !report.assumptions.spendingCategory.isEmpty {
                resultRow(
                    L10n.TimeMachine.spendingSaved(report.assumptions.spendingCategory),
                    OperationFormatting.plain(report.spendingSaved)
                )
            }
            if report.assumptions.subscriptionIncreasePercent > 0 {
                resultRow(
                    L10n.TimeMachine.subscriptionCost,
                    OperationFormatting.plain(report.additionalSubscriptionCost)
                )
            }
            resultRow(
                L10n.TimeMachine.savingsTotal,
                OperationFormatting.plain(report.plannedSavings)
            )

            if let shift = report.incomeShift {
                Text(L10n.TimeMachine.incomeShift(
                    shift.category,
                    OperationFormatting.plain(shift.amount),
                    formatDate(shift.originalDate),
                    formatDate(shift.delayedDate)
                ))
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(L10n.TimeMachine.noIncomeShift)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }

        Section(L10n.TimeMachine.monthlySection) {
            ForEach(report.months) { month in
                VStack(alignment: .leading, spacing: 5) {
                    Text(formatMonth(month.start))
                        .font(.headline)
                    Text(L10n.TimeMachine.monthlyNet(
                        OperationFormatting.plain(month.baselineNetCashFlow),
                        OperationFormatting.plain(month.scenarioNetCashFlow)
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
        }

        Section(L10n.FinancialTwin.methodTitle) {
            Text(L10n.TimeMachine.method(report.sampleMonthCount))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var expenseCategories: [String] {
        let subscriptionKeys = Set(subscriptions.map { Budget.categoryKey(for: $0.name) })
        return uniqueCategories(kind: .expense).filter {
            !subscriptionKeys.contains(Budget.categoryKey(for: $0))
        }
    }

    private var incomeCategories: [String] {
        uniqueCategories(kind: .income)
    }

    private var currencySymbol: String {
        CurrencySettings.symbol(for: CurrencySettings.selectedCode)
    }

    private var inputToken: String {
        [
            spendingCategory,
            String(spendingReductionPercent),
            incomeCategory,
            String(incomeDelayDays),
            String(subscriptionIncreasePercent),
            monthlySavingsText,
            String(horizonMonths)
        ].joined(separator: "|")
    }

    private func uniqueCategories(kind: TransactionKind) -> [String] {
        var seen = Set<String>()
        return transactions
            .filter { $0.kind == kind }
            .sorted { $0.date > $1.date }
            .map(\.category)
            .filter { seen.insert(Budget.categoryKey(for: $0)).inserted }
    }

    private var monthlySavings: Decimal? {
        let normalized = monthlySavingsText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")),
              value >= 0
        else { return nil }
        return value
    }

    private func calculate() {
        guard let monthlySavings else {
            errorMessage = L10n.TimeMachine.invalidInput
            return
        }
        do {
            report = try simulate.execute(
                assumptions: FinancialTimeMachineAssumptions(
                    spendingCategory: spendingCategory,
                    spendingReductionPercent: spendingReductionPercent,
                    incomeCategory: incomeCategory,
                    incomeDelayDays: incomeDelayDays,
                    subscriptionIncreasePercent: subscriptionIncreasePercent,
                    monthlySavings: monthlySavings,
                    horizonMonths: horizonMonths
                ),
                transactions: transactions,
                subscriptions: subscriptions
            )
            errorMessage = nil
            isSavingsFocused = false
        } catch {
            report = nil
            errorMessage = L10n.TimeMachine.invalidInput
        }
    }

    private func invalidate() {
        report = nil
        errorMessage = nil
    }

    private func resultRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.weight(.semibold))
                .contentTransition(.numericText())
        }
        .accessibilityElement(children: .combine)
    }

    private func formatDate(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .day()
                .month(.wide)
                .year()
                .locale(Locale(identifier: LocalizationManager.shared.currentLanguage))
        )
    }

    private func formatMonth(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .month(.wide)
                .year()
                .locale(Locale(identifier: LocalizationManager.shared.currentLanguage))
        )
    }
}

#Preview {
    FinancialTimeMachineView(
        transactions: [],
        subscriptions: [],
        simulate: SimulateFinancialTimeMachineUseCase()
    )
}
