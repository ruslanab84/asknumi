//
//  PurchaseDecisionView.swift
//  Ask Numi
//

import SwiftUI

struct PurchaseDecisionView: View {
    let transactions: [Transaction]
    let budgets: [Budget]
    let subscriptions: [Subscription]
    let goals: [SavingsGoal]
    let simulatePurchase: SimulatePurchaseUseCase

    @Environment(\.dismiss) private var dismiss
    @State private var amountText = ""
    @State private var balanceText = ""
    @State private var purchaseDate = Calendar.current.startOfDay(for: .now)
    @State private var category = ""
    @State private var report: PurchaseDecisionReport?
    @State private var errorMessage: String?
    @State private var isSimulating = false
    @State private var requestID = UUID()
    @FocusState private var focusedField: Field?

    private enum Field {
        case amount
        case balance
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.PurchaseDecision.inputSection) {
                    amountField(
                        title: L10n.PurchaseDecision.amount,
                        text: $amountText,
                        field: .amount
                    )
                    amountField(
                        title: L10n.PurchaseDecision.availableBalance,
                        text: $balanceText,
                        field: .balance
                    )

                    Text(L10n.PurchaseDecision.balanceHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    DatePicker(
                        L10n.PurchaseDecision.date,
                        selection: $purchaseDate,
                        in: Calendar.current.startOfDay(for: .now)...,
                        displayedComponents: .date
                    )

                    Picker(L10n.PurchaseDecision.category, selection: $category) {
                        ForEach(categoryOptions, id: \String.self) { value in
                            Text(value).tag(value)
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }

                if isSimulating {
                    Section {
                        HStack {
                            ProgressView()
                            Text(L10n.PurchaseDecision.calculating)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if let report {
                    resultContent(report)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background { DashboardBackground() }
            .navigationTitle(L10n.PurchaseDecision.title)
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.PurchaseDecision.calculate) {
                        Task { await simulate() }
                    }
                    .disabled(!canSimulate || isSimulating)
                }
            }
            .onAppear {
                if category.isEmpty { category = categoryOptions.first ?? "" }
                focusedField = .amount
            }
            .onChange(of: amountText) { _, _ in invalidateResult() }
            .onChange(of: balanceText) { _, _ in invalidateResult() }
            .onChange(of: purchaseDate) { _, _ in invalidateResult() }
            .onChange(of: category) { _, _ in invalidateResult() }
        }
    }

    @ViewBuilder
    private func resultContent(_ report: PurchaseDecisionReport) -> some View {
        let decision = report.decision

        Section(L10n.PurchaseDecision.resultSection) {
            Label(
                L10n.PurchaseDecision.recommendation(decision.recommendation),
                systemImage: recommendationIcon(decision.recommendation)
            )
            .font(.headline)
            .foregroundStyle(recommendationColor(decision.recommendation))

            Text(report.explanation ?? L10n.PurchaseDecision.fallback(decision.recommendation))
                .font(.subheadline)

            resultRow(
                L10n.PurchaseDecision.currentMonthPayments,
                OperationFormatting.plain(decision.currentMonthScheduledPayments)
            )
            resultRow(
                L10n.PurchaseDecision.balanceAfterPayments,
                OperationFormatting.plain(decision.remainingAfterCurrentMonthPayments)
            )
            resultRow(
                L10n.PurchaseDecision.safeAmount,
                OperationFormatting.plain(decision.safePurchaseAmount)
            )
            resultRow(
                L10n.PurchaseDecision.budgetImpact,
                budgetText(decision)
            )
            resultRow(
                L10n.PurchaseDecision.goalImpact,
                goalText(decision.goalImpact)
            )
            resultRow(
                L10n.PurchaseDecision.betterDate,
                decision.betterDate.map(formatDate) ?? L10n.PurchaseDecision.noSuitableDate
            )
        }

        Section(L10n.PurchaseDecision.scenariosSection) {
            PurchaseScenarioRow(
                title: L10n.PurchaseDecision.buyNow,
                scenario: decision.buyNow,
                isRecommended: decision.recommendation == .buyNow
            )
            PurchaseScenarioRow(
                title: L10n.PurchaseDecision.buyLater,
                scenario: decision.buyLater,
                isRecommended: decision.recommendation == .buyLater
            )
            PurchaseScenarioRow(
                title: L10n.PurchaseDecision.skip,
                scenario: decision.skip,
                isRecommended: decision.recommendation == .skip,
                isSkip: true
            )
        }

        Section(L10n.FinancialTwin.methodTitle) {
            Text(L10n.PurchaseDecision.method)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func amountField(
        title: String,
        text: Binding<String>,
        field: Field
    ) -> some View {
        HStack {
            TextField(title, text: text)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: field)
            Text(CurrencySettings.symbol(for: CurrencySettings.selectedCode))
                .foregroundStyle(.secondary)
        }
    }

    private func resultRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var categoryOptions: [String] {
        let recent = transactions
            .filter { $0.kind == .expense }
            .sorted { $0.date > $1.date }
            .map(\.category)
        var seen = Set<String>()
        return (budgets.map(\.category) + recent + L10n.AddOperation.defaultExpenseCategories).filter {
            seen.insert(Budget.categoryKey(for: $0)).inserted
        }
    }

    private var purchaseAmount: Decimal? { parseDecimal(amountText, allowsZero: false) }
    private var availableBalance: Decimal? { parseDecimal(balanceText, allowsZero: true) }
    private var canSimulate: Bool {
        purchaseAmount != nil && availableBalance != nil && !category.isEmpty
    }

    private func parseDecimal(_ text: String, allowsZero: Bool) -> Decimal? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")) else {
            return nil
        }
        return allowsZero ? (value >= 0 ? value : nil) : (value > 0 ? value : nil)
    }

    private func simulate() async {
        guard let purchaseAmount, let availableBalance, canSimulate else {
            errorMessage = L10n.PurchaseDecision.invalidInput
            return
        }

        let currentRequestID = UUID()
        requestID = currentRequestID
        isSimulating = true
        errorMessage = nil
        defer {
            if requestID == currentRequestID { isSimulating = false }
        }

        do {
            let value = try await simulatePurchase.execute(
                amount: purchaseAmount,
                desiredDate: purchaseDate,
                availableBalance: availableBalance,
                category: category,
                transactions: transactions,
                budgets: budgets,
                subscriptions: subscriptions,
                goals: goals
            )
            guard requestID == currentRequestID else { return }
            report = value
        } catch {
            guard requestID == currentRequestID else { return }
            errorMessage = L10n.PurchaseDecision.failed
        }
    }

    private func invalidateResult() {
        requestID = UUID()
        report = nil
        errorMessage = nil
        isSimulating = false
    }

    private func budgetText(_ decision: PurchaseDecision) -> String {
        guard let impact = decision.budgetImpact else {
            return L10n.PurchaseDecision.noBudget(decision.category)
        }
        if impact.overBy > 0 {
            return L10n.PurchaseDecision.budgetExceeded(
                impact.category,
                OperationFormatting.plain(impact.overBy)
            )
        }
        return L10n.PurchaseDecision.budgetWithin(
            impact.category,
            OperationFormatting.plain(max(impact.limit - impact.projectedSpent, 0))
        )
    }

    private func goalText(_ impact: PurchaseGoalImpact?) -> String {
        guard let impact else { return L10n.PurchaseDecision.noGoal }
        guard impact.delayedByMonths > 0 else {
            return L10n.PurchaseDecision.goalOnTrack(impact.name)
        }
        return L10n.PurchaseDecision.goalDelayed(
            impact.name,
            impact.delayedByMonths,
            formatDate(impact.projectedTargetDate)
        )
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

    private func recommendationIcon(_ value: PurchaseRecommendation) -> String {
        switch value {
        case .buyNow: "checkmark.circle.fill"
        case .buyLater: "calendar.badge.clock"
        case .skip: "hand.raised.fill"
        }
    }

    private func recommendationColor(_ value: PurchaseRecommendation) -> Color {
        switch value {
        case .buyNow: .green
        case .buyLater: .orange
        case .skip: .red
        }
    }
}

private struct PurchaseScenarioRow: View {
    let title: String
    let scenario: PurchaseScenario
    let isRecommended: Bool
    var isSkip = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if isRecommended {
                    Text(L10n.PurchaseDecision.recommended)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.tint, in: .capsule)
                }
            }

            if let date = scenario.date {
                Label(formatDate(date), systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(isSkip
                ? L10n.PurchaseDecision.skipScenario(OperationFormatting.plain(scenario.balanceAfterPurchaseAndPayments))
                : L10n.PurchaseDecision.purchaseScenario(
                    OperationFormatting.plain(scenario.balanceAfterPurchaseAndPayments),
                    scenario.isSafe
                )
            )
            .font(.subheadline)
            .fixedSize(horizontal: false, vertical: true)

            if let budget = scenario.exceededBudgets.first {
                Text(L10n.PurchaseDecision.budgetExceeded(
                    budget.category,
                    OperationFormatting.plain(budget.overBy)
                ))
                .font(.caption)
                .foregroundStyle(.red)
            }

            if let goal = scenario.goalImpact, goal.delayedByMonths > 0 {
                Text(L10n.PurchaseDecision.goalDelayShort(goal.name, goal.delayedByMonths))
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
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
}

#Preview {
    PurchaseDecisionView(
        transactions: [],
        budgets: [],
        subscriptions: [],
        goals: [],
        simulatePurchase: SimulatePurchaseUseCase()
    )
}
