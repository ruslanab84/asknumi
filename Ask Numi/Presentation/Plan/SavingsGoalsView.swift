//
//  SavingsGoalsView.swift
//  Ask Numi
//

import SwiftUI

struct SavingsGoalsContent: View {
    let overview: SavingsGoalsOverview
    let onCreate: () -> Void
    let onEdit: (SavingsGoal) -> Void
    let onContribute: (SavingsGoal) -> Void
    let onDelete: (SavingsGoal) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if overview.items.isEmpty {
                ContentUnavailableView {
                    Label(L10n.Plan.goalEmptyTitle, systemImage: "target")
                } description: {
                    Text(L10n.Plan.goalEmptyMessage)
                } actions: {
                    Button(L10n.Plan.goalCreate, action: onCreate)
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 38)
                .glassEffect(.regular, in: .rect(cornerRadius: 22))
            } else {
                SavingsGoalsSummary(overview: overview)

                ForEach(overview.items) { item in
                    SavingsGoalCard(
                        progress: item,
                        onEdit: { onEdit(item.goal) },
                        onContribute: { onContribute(item.goal) },
                        onDelete: { onDelete(item.goal) }
                    )
                }
            }
        }
    }
}

private struct SavingsGoalsSummary: View {
    let overview: SavingsGoalsOverview
    @Environment(\.appAccentColor) private var accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Plan.goalsTitle)
                .font(.subheadline.weight(.bold))

            Text(L10n.Plan.goalSavedOf(
                OperationFormatting.plain(overview.totalSaved),
                OperationFormatting.plain(overview.totalTarget)
            ))
            .font(.title3.weight(.bold))

            ProgressView(value: progress)
                .tint(healthColor)

            Label(
                L10n.Plan.goalMonthlyPlan(OperationFormatting.plain(overview.monthlyNeeded)),
                systemImage: "calendar.badge.clock"
            )
            .font(.caption)

            if let averageMonthlySurplus = overview.averageMonthlySurplus {
                Label(
                    L10n.Plan.goalHistoricalSurplus(
                        OperationFormatting.plain(max(averageMonthlySurplus, 0))
                    ),
                    systemImage: "chart.line.uptrend.xyaxis"
                )
                .font(.caption)
            }

            Label(healthText, systemImage: healthSymbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(healthColor)
        }
        .padding(16)
        .glassEffect(.regular.tint(healthColor.opacity(0.12)), in: .rect(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }

    private var progress: Double {
        guard overview.totalTarget > 0 else { return 0 }
        return min(
            max(NSDecimalNumber(decimal: overview.totalSaved / overview.totalTarget).doubleValue, 0),
            1
        )
    }

    private var healthColor: Color {
        switch overview.health {
        case .complete, .feasible: .green
        case .noHistory: accentColor
        case .strained: .orange
        }
    }

    private var healthSymbol: String {
        switch overview.health {
        case .complete: "checkmark.seal.fill"
        case .feasible: "checkmark.circle.fill"
        case .noHistory: "info.circle.fill"
        case .strained: overview.hasOverdueGoals ? "exclamationmark.triangle.fill" : "arrow.up.right.circle.fill"
        }
    }

    private var healthText: String {
        switch overview.health {
        case .complete:
            return L10n.Plan.goalPlanComplete
        case .feasible:
            return L10n.Plan.goalPlanFeasible
        case .noHistory:
            return L10n.Plan.goalPlanNoHistory
        case .strained:
            if overview.hasOverdueGoals {
                return L10n.Plan.goalPlanOverdue
            }
            return L10n.Plan.goalPlanGap(
                OperationFormatting.plain(overview.monthlyGap ?? 0)
            )
        }
    }
}

private struct SavingsGoalCard: View {
    let progress: SavingsGoalProgress
    let onEdit: () -> Void
    let onContribute: () -> Void
    let onDelete: () -> Void
    @Environment(\.appAccentColor) private var accentColor

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: progress.goal.symbol)
                        .font(.headline)
                        .foregroundStyle(statusColor)
                        .frame(width: 40, height: 40)
                        .background(statusColor.opacity(0.14), in: .circle)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(progress.goal.name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(2)
                        Text(statusTitle)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(statusColor)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }

                Text(L10n.Plan.goalSavedOf(
                    OperationFormatting.plain(progress.goal.savedAmount),
                    OperationFormatting.plain(progress.goal.targetAmount)
                ))
                .font(.caption)

                ProgressView(value: min(max(progress.fractionComplete, 0), 1))
                    .tint(statusColor)

                HStack {
                    Label(formattedDeadline, systemImage: "calendar")
                    Spacer()
                    if progress.state.isActive {
                        Text(L10n.Plan.goalPerMonth(
                            OperationFormatting.plain(progress.monthlyContribution)
                        ))
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .padding(16)
            .contentShape(.rect)
            .onTapGesture(perform: onEdit)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(L10n.Plan.editGoal(progress.goal.name))
            .accessibilityAction { onEdit() }

            Divider()
                .padding(.horizontal, 16)

            Button(action: onContribute) {
                Label(L10n.Plan.goalUpdateProgress, systemImage: "plusminus.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tint)
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .glassEffect(.regular.tint(statusColor.opacity(0.08)), in: .rect(cornerRadius: 20))
        .contextMenu {
            Button(L10n.Plan.deleteGoal, systemImage: "trash", role: .destructive, action: onDelete)
        }
        .accessibilityAction(named: L10n.Plan.deleteGoal, onDelete)
    }

    private var statusColor: Color {
        switch progress.state {
        case .active: accentColor
        case .overdue: .orange
        case .complete: .green
        }
    }

    private var statusTitle: String {
        switch progress.state {
        case .active: L10n.Plan.goalStateActive
        case .overdue: L10n.Plan.goalStateOverdue
        case .complete: L10n.Plan.goalStateComplete
        }
    }

    private var formattedDeadline: String {
        progress.goal.targetDate.formatted(
            .dateTime
                .day()
                .month(.abbreviated)
                .year()
                .locale(Locale(identifier: LocalizationManager.shared.currentLanguage))
        )
    }
}

struct SavingsGoalEditorView: View {
    let goal: SavingsGoal?
    let saveGoal: SaveSavingsGoalUseCase
    let onDelete: (SavingsGoal) -> Void
    let onSaved: (SavingsGoal) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appAccentColor) private var accentColor
    @State private var name: String
    @State private var symbol: String
    @State private var targetAmountText: String
    @State private var savedAmountText: String
    @State private var targetDate: Date
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: GoalField?

    init(
        goal: SavingsGoal?,
        saveGoal: SaveSavingsGoalUseCase,
        onDelete: @escaping (SavingsGoal) -> Void,
        onSaved: @escaping (SavingsGoal) -> Void
    ) {
        self.goal = goal
        self.saveGoal = saveGoal
        self.onDelete = onDelete
        self.onSaved = onSaved

        let today = Calendar.current.startOfDay(for: .now)
        let defaultDeadline = Calendar.current.date(byAdding: .month, value: 6, to: today) ?? today
        _name = State(initialValue: goal?.name ?? "")
        _symbol = State(initialValue: goal?.symbol ?? "target")
        _targetAmountText = State(initialValue: goal.map { "\($0.targetAmount)" } ?? "")
        _savedAmountText = State(initialValue: goal.map { "\($0.savedAmount)" } ?? "")
        _targetDate = State(initialValue: max(goal?.targetDate ?? defaultDeadline, today))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.Plan.goalSectionDetails) {
                    TextField(L10n.Plan.goalNamePlaceholder, text: $name)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .targetAmount }

                    if name.count > 60 {
                        Text(L10n.Plan.goalNameTooLong)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    ScrollView(.horizontal) {
                        HStack(spacing: 12) {
                            ForEach(GoalIconOption.all) { option in
                                Button {
                                    symbol = option.symbol
                                } label: {
                                    Image(systemName: option.symbol)
                                        .font(.headline)
                                        .foregroundStyle(symbol == option.symbol ? .white : accentColor)
                                        .frame(width: 42, height: 42)
                                        .background(
                                            symbol == option.symbol ? accentColor : accentColor.opacity(0.12),
                                            in: .circle
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(option.label)
                                .accessibilityAddTraits(symbol == option.symbol ? .isSelected : [])
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .scrollIndicators(.hidden)
                }

                Section(L10n.Plan.goalSectionAmounts) {
                    amountField(
                        title: L10n.Plan.goalTargetAmount,
                        text: $targetAmountText,
                        field: .targetAmount
                    )
                    amountField(
                        title: L10n.Plan.goalSavedAmount,
                        text: $savedAmountText,
                        field: .savedAmount
                    )
                }

                Section(L10n.Plan.goalSectionDeadline) {
                    DatePicker(
                        L10n.Plan.goalTargetDate,
                        selection: $targetDate,
                        in: Calendar.current.startOfDay(for: .now)...,
                        displayedComponents: .date
                    )

                    if let monthlyProjection {
                        Text(L10n.Plan.goalEditorMonthly(
                            OperationFormatting.plain(monthlyProjection)
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                if let goal {
                    Section {
                        Button(L10n.Plan.deleteGoal, systemImage: "trash", role: .destructive) {
                            onDelete(goal)
                            dismiss()
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background { DashboardBackground() }
            .navigationTitle(goal == nil ? L10n.Plan.goalTitleNew : L10n.Plan.goalTitleEdit)
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? L10n.Common.saving : L10n.Common.save) {
                        Task { await save() }
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                if goal == nil {
                    focusedField = .name
                }
            }
        }
    }

    private func amountField(
        title: String,
        text: Binding<String>,
        field: GoalField
    ) -> some View {
        HStack {
            TextField(title, text: text)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: field)
            Text(CurrencySettings.selectedCode)
                .foregroundStyle(.secondary)
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var targetAmount: Decimal? {
        parseDecimal(targetAmountText, allowsZero: false)
    }

    private var savedAmount: Decimal? {
        let trimmed = savedAmountText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? 0 : parseDecimal(trimmed, allowsZero: true)
    }

    private var monthlyProjection: Decimal? {
        guard let targetAmount, let savedAmount else { return nil }
        return SavingsGoalProgress(
            goal: SavingsGoal(
                name: trimmedName,
                targetAmount: targetAmount,
                savedAmount: savedAmount,
                targetDate: targetDate
            )
        ).monthlyContribution
    }

    private var canSave: Bool {
        !trimmedName.isEmpty &&
            trimmedName.count <= 60 &&
            targetAmount != nil &&
            savedAmount != nil &&
            !isSaving
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

    private func save() async {
        guard let targetAmount, let savedAmount, canSave else { return }
        isSaving = true
        errorMessage = nil

        let saved = SavingsGoal(
            id: goal?.id ?? UUID(),
            name: trimmedName,
            symbol: symbol,
            targetAmount: targetAmount,
            savedAmount: savedAmount,
            targetDate: targetDate
        )
        do {
            try await saveGoal.execute(saved)
            onSaved(saved)
            dismiss()
        } catch {
            errorMessage = L10n.Plan.goalSaveError
            isSaving = false
        }
    }
}

struct SavingsGoalContributionView: View {
    let goal: SavingsGoal
    let saveGoal: SaveSavingsGoalUseCase
    let onSaved: (SavingsGoal) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var action: GoalAdjustment = .add
    @State private var amountText = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var isAmountFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.Plan.goalContributionCurrent) {
                    Text(OperationFormatting.plain(goal.savedAmount))
                        .font(.title3.weight(.bold))
                }

                Section(L10n.Plan.goalContributionAction) {
                    Picker(L10n.Plan.goalContributionAction, selection: $action) {
                        Text(L10n.Plan.goalContributionAdd).tag(GoalAdjustment.add)
                        Text(L10n.Plan.goalContributionWithdraw).tag(GoalAdjustment.withdraw)
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        TextField(L10n.Plan.goalContributionAmount, text: $amountText)
                            .keyboardType(.decimalPad)
                            .focused($isAmountFocused)
                        Text(CurrencySettings.selectedCode)
                            .foregroundStyle(.secondary)
                    }

                    if action == .withdraw, let amount, amount > goal.savedAmount {
                        Text(L10n.Plan.goalContributionInsufficient)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background { DashboardBackground() }
            .navigationTitle(L10n.Plan.goalContributionTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? L10n.Common.saving : L10n.Common.save) {
                        Task { await save() }
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear { isAmountFocused = true }
        }
    }

    private var amount: Decimal? {
        let normalized = amountText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard
            let value = Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")),
            value > 0
        else { return nil }
        return value
    }

    private var canSave: Bool {
        guard let amount, !isSaving else { return false }
        return action == .add || amount <= goal.savedAmount
    }

    private func save() async {
        guard let amount, canSave else { return }
        isSaving = true
        errorMessage = nil

        var updated = goal
        updated.savedAmount += action == .add ? amount : -amount
        do {
            try await saveGoal.execute(updated)
            onSaved(updated)
            dismiss()
        } catch {
            errorMessage = L10n.Plan.goalSaveError
            isSaving = false
        }
    }
}

private enum GoalField {
    case name
    case targetAmount
    case savedAmount
}

private enum GoalAdjustment {
    case add
    case withdraw
}

private struct GoalIconOption: Identifiable {
    let symbol: String
    let label: String

    var id: String { symbol }

    static var all: [GoalIconOption] {
        [
            GoalIconOption(symbol: "shield.fill", label: L10n.Plan.goalIconEmergency),
            GoalIconOption(symbol: "airplane", label: L10n.Plan.goalIconTravel),
            GoalIconOption(symbol: "house.fill", label: L10n.Plan.goalIconHome),
            GoalIconOption(symbol: "car.fill", label: L10n.Plan.goalIconCar),
            GoalIconOption(symbol: "graduationcap.fill", label: L10n.Plan.goalIconEducation),
            GoalIconOption(symbol: "target", label: L10n.Plan.goalIconOther)
        ]
    }
}

#Preview("Goals — empty") {
    SavingsGoalsContent(
        overview: SavingsGoalsOverview(goals: [], transactions: []),
        onCreate: {},
        onEdit: { _ in },
        onContribute: { _ in },
        onDelete: { _ in }
    )
    .padding()
    .background { DashboardBackground() }
}

#Preview("Goals — populated") {
    let targetDate = Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now
    let goals = [
        SavingsGoal(
            name: L10n.Plan.goalIconEmergency,
            symbol: "shield.fill",
            targetAmount: 5_000,
            savedAmount: 1_750,
            targetDate: targetDate
        )
    ]
    ScrollView {
        SavingsGoalsContent(
            overview: SavingsGoalsOverview(goals: goals, transactions: []),
            onCreate: {},
            onEdit: { _ in },
            onContribute: { _ in },
            onDelete: { _ in }
        )
        .padding()
    }
    .background { DashboardBackground() }
}
