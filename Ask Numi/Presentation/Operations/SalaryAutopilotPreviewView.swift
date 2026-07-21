//
//  SalaryAutopilotPreviewView.swift
//  Ask Numi
//

import SwiftUI

struct SalaryAutopilotPreviewView: View {
    let income: Transaction
    let transactions: [Transaction]
    let fetchSubscriptions: FetchSubscriptionsUseCase
    let fetchBudgets: FetchBudgetsUseCase
    let fetchGoals: FetchSavingsGoalsUseCase
    let saveGoals: SaveSavingsGoalUseCase

    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar
    @State private var proposal: SalaryAllocationProposal?
    @State private var goals: [SavingsGoal] = []
    @State private var isLoading = true
    @State private var isApplying = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView(L10n.SalaryAutopilot.loading)
                } else if let proposal {
                    preview(proposal)
                } else {
                    ContentUnavailableView {
                        Label(L10n.SalaryAutopilot.loadError, systemImage: "exclamationmark.triangle")
                    } actions: {
                        Button(L10n.Common.retry) { Task { await load() } }
                    }
                }
            }
            .navigationTitle(L10n.SalaryAutopilot.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                        .disabled(isApplying)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isApplying ? L10n.SalaryAutopilot.applying : L10n.SalaryAutopilot.apply) {
                        Task { await apply() }
                    }
                    .disabled(proposal == nil || isApplying)
                }
            }
            .alert(
                L10n.SalaryAutopilot.applyError,
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button(L10n.Operations.deleteAlertOk, role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .task { await load() }
        }
    }

    private func preview(_ proposal: SalaryAllocationProposal) -> some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(OperationFormatting.plain(proposal.income))
                        .font(.title2.weight(.bold))
                    Text(L10n.SalaryAutopilot.intro)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            ForEach(SalaryAllocationBucket.allCases, id: \.self) { bucket in
                Section {
                    let items = proposal.items[bucket, default: []]
                    if items.isEmpty {
                        allocationRow(
                            title: bucket.title,
                            reason: bucket.emptyReason,
                            amount: 0,
                            icon: bucket.systemImage
                        )
                    } else {
                        ForEach(items) { item in
                            allocationRow(
                                title: item.name.isEmpty ? bucket.title : item.name,
                                reason: reason(for: item.basis),
                                amount: item.amount,
                                icon: bucket.systemImage
                            )
                        }
                    }
                } header: {
                    HStack {
                        Text(bucket.title)
                        Spacer()
                        Text(OperationFormatting.plain(proposal.amount(for: bucket)))
                    }
                }
            }

            Section {
                Text(L10n.SalaryAutopilot.method)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background { DashboardBackground() }
    }

    private func allocationRow(
        title: String,
        reason: String,
        amount: Decimal,
        icon: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Text(OperationFormatting.plain(amount))
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }

    private func reason(for basis: SalaryAllocationBasis) -> String {
        switch basis {
        case .payment(let dueDate):
            L10n.SalaryAutopilot.paymentReason(date(dueDate))
        case .budget(let spent, let limit):
            L10n.SalaryAutopilot.budgetReason(
                OperationFormatting.plain(spent),
                OperationFormatting.plain(limit)
            )
        case .goal(let targetDate, let remaining):
            L10n.SalaryAutopilot.goalReason(
                OperationFormatting.plain(remaining),
                date(targetDate)
            )
        case .remainder:
            L10n.SalaryAutopilot.freeReason
        }
    }

    private func date(_ date: Date) -> String {
        date.formatted(
            .dateTime.day().month(.abbreviated)
                .locale(Locale(identifier: LocalizationManager.shared.currentLanguage))
        )
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let subscriptions = fetchSubscriptions.execute()
            async let budgets = fetchBudgets.execute()
            async let loadedGoals = fetchGoals.execute()
            let subscriptionsValue = try await subscriptions
            let budgetsValue = try await budgets
            goals = try await loadedGoals
            proposal = CalculateSalaryAllocationUseCase().execute(
                income: income,
                transactions: transactions,
                subscriptions: subscriptionsValue,
                budgets: budgetsValue,
                goals: goals,
                calendar: calendar
            )
            errorMessage = nil
        } catch {
            proposal = nil
        }
    }

    private func apply() async {
        guard let proposal else { return }
        isApplying = true
        defer { isApplying = false }

        let contributions = proposal.goalContributions
        let updatedGoals = goals.compactMap { goal -> SavingsGoal? in
            guard let contribution = contributions[goal.id], contribution > 0 else { return nil }
            var updated = goal
            updated.savedAmount = min(goal.savedAmount + contribution, goal.targetAmount)
            return updated
        }

        do {
            if !updatedGoals.isEmpty {
                try await saveGoals.execute(updatedGoals)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension SalaryAllocationBucket {
    var title: String {
        switch self {
        case .requiredPayments: L10n.SalaryAutopilot.requiredPayments
        case .budgets: L10n.SalaryAutopilot.budgets
        case .cushion: L10n.SalaryAutopilot.cushion
        case .goals: L10n.SalaryAutopilot.goals
        case .freeMoney: L10n.SalaryAutopilot.freeMoney
        }
    }

    var emptyReason: String {
        switch self {
        case .requiredPayments: L10n.SalaryAutopilot.noPayments
        case .budgets: L10n.SalaryAutopilot.noBudgets
        case .cushion: L10n.SalaryAutopilot.noCushion
        case .goals: L10n.SalaryAutopilot.noGoals
        case .freeMoney: L10n.SalaryAutopilot.freeReason
        }
    }

    var systemImage: String {
        switch self {
        case .requiredPayments: "checkmark.circle.fill"
        case .budgets: "chart.bar.fill"
        case .cushion: "shield.fill"
        case .goals: "target"
        case .freeMoney: "wallet.bifold.fill"
        }
    }
}
