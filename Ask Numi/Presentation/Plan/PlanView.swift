//
//  PlanView.swift
//  Ask Numi
//

import SwiftUI

struct PlanView: View {
    let snapshot: PlanSnapshot
    let fetchTransactions: FetchTransactionsUseCase
    let fetchSubscriptions: FetchSubscriptionsUseCase
    let saveSubscription: SaveSubscriptionUseCase
    let deleteSubscription: DeleteSubscriptionUseCase
    @Binding var selectedTab: AppTab
    @State private var section: PlanSection = .payments
    @State private var subscriptions: [Subscription] = []
    @State private var editorItem: SubscriptionEditorItem?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                DashboardBackground()

                ScrollView {
                    GlassEffectContainer(spacing: 20) {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            header
                            sectionPicker

                            switch section {
                            case .payments:
                                paymentsContent
                            case .budgets:
                                PlanPlaceholder(title: L10n.Plan.sectionBudgets, symbol: "chart.bar.fill")
                            case .goals:
                                PlanPlaceholder(title: L10n.Plan.sectionGoals, symbol: "target")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 104)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .safeAreaInset(edge: .bottom) {
                AppTabBar(selection: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $editorItem) { item in
                SubscriptionEditorView(
                    subscription: item.subscription,
                    saveSubscription: saveSubscription
                ) { saved in
                    if let index = subscriptions.firstIndex(where: { $0.id == saved.id }) {
                        subscriptions[index] = saved
                    } else {
                        subscriptions.append(saved)
                    }
                    subscriptions.sort { $0.nextChargeDate < $1.nextChargeDate }
                }
            }
            .task { await loadSubscriptions() }
        }
    }

    private var header: some View {
        HStack {
            Text(L10n.Plan.title)
                .font(.title3.weight(.bold))
            Spacer()
            if section == .payments {
                Button {
                    editorItem = SubscriptionEditorItem(subscription: nil)
                } label: {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .glassEffect(.regular.tint(.indigo).interactive(), in: .circle)
                }
                .accessibilityLabel(L10n.Plan.addSubscription)
            }
        }
    }

    private var sectionPicker: some View {
        Picker(L10n.Plan.sectionPickerLabel, selection: $section) {
            ForEach(PlanSection.allCases, id: \.self) { item in
                Text(item.title).tag(item)
            }
        }
        .pickerStyle(.segmented)
    }

    private var paymentsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            UpcomingPayments(
                subscriptions: subscriptions,
                onEdit: { editorItem = SubscriptionEditorItem(subscription: $0) },
                onDelete: delete
            )

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            BalanceForecast(balance: snapshot.forecastBalance)
            BudgetProgress(budget: snapshot.budget)
        }
    }

    private func loadSubscriptions() async {
        do {
            _ = try await fetchTransactions.execute()
            subscriptions = try await fetchSubscriptions.execute()
            errorMessage = nil
        } catch {
            errorMessage = L10n.Plan.loadError
        }
    }

    private func delete(_ subscription: Subscription) {
        Task {
            do {
                try await deleteSubscription.execute(id: subscription.id)
                subscriptions.removeAll { $0.id == subscription.id }
            } catch {
                errorMessage = L10n.Plan.deleteError
            }
        }
    }
}

private struct UpcomingPayments: View {
    let subscriptions: [Subscription]
    let onEdit: (Subscription) -> Void
    let onDelete: (Subscription) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.Plan.paymentsTitle)
                .font(.subheadline.weight(.bold))

            if subscriptions.isEmpty {
                ContentUnavailableView(
                    L10n.Plan.subscriptionsEmptyTitle,
                    systemImage: "repeat.circle",
                    description: Text(L10n.Plan.subscriptionsEmptyMessage)
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(subscriptions.enumerated()), id: \.element.id) { index, subscription in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(.indigo)
                                    .frame(width: 10, height: 10)
                                if index < subscriptions.count - 1 {
                                    Rectangle()
                                        .fill(.secondary.opacity(0.25))
                                        .frame(width: 2, height: 46)
                                }
                            }
                            .padding(.top, 4)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(subscription.nextChargeDate.formatted(
                                    .dateTime.day().month(.wide).locale(Locale(identifier: LocalizationManager.shared.currentLanguage))
                                ))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(subscription.name)
                                    .font(.subheadline.weight(.semibold))
                            }

                            Spacer()

                            Text(OperationFormatting.amount(subscription.amount, sign: .expense))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                        .contentShape(.rect)
                        .onTapGesture { onEdit(subscription) }
                        .contextMenu {
                            Button(L10n.Plan.deleteSubscription, systemImage: "trash", role: .destructive) {
                                onDelete(subscription)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }
}

private struct SubscriptionEditorView: View {
    let subscription: Subscription?
    let saveSubscription: SaveSubscriptionUseCase
    let onSaved: (Subscription) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var amountText: String
    @State private var chargeDate: Date
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        subscription: Subscription?,
        saveSubscription: SaveSubscriptionUseCase,
        onSaved: @escaping (Subscription) -> Void
    ) {
        self.subscription = subscription
        self.saveSubscription = saveSubscription
        self.onSaved = onSaved
        _name = State(initialValue: subscription?.name ?? "")
        _amountText = State(initialValue: subscription.map { "\($0.amount)" } ?? "")
        _chargeDate = State(initialValue: subscription?.nextChargeDate ?? .now)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var amount: Decimal? {
        let normalized = amountText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")), value > 0 else {
            return nil
        }
        return value
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && trimmedName.count <= 60 && amount != nil && !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.Plan.subscriptionSectionDetails) {
                    TextField(L10n.Plan.subscriptionNamePlaceholder, text: $name)
                    if name.count > 60 {
                        Text(L10n.Plan.subscriptionNameTooLong)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section(L10n.Plan.subscriptionSectionAmount) {
                    HStack {
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                        Text(CurrencySettings.selectedCode)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(L10n.Plan.subscriptionSectionDate) {
                    DatePicker(
                        L10n.Plan.subscriptionDateLabel,
                        selection: $chargeDate,
                        in: Calendar.current.startOfDay(for: .now)...,
                        displayedComponents: .date
                    )
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle(subscription == nil ? L10n.Plan.subscriptionTitleNew : L10n.Plan.subscriptionTitleEdit)
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
        }
    }

    private func save() async {
        guard let amount, canSave else { return }
        isSaving = true
        errorMessage = nil

        let saved = Subscription(
            id: subscription?.id ?? UUID(),
            name: trimmedName,
            amount: amount,
            nextChargeDate: chargeDate
        )
        do {
            try await saveSubscription.execute(saved)
            onSaved(saved)
            dismiss()
        } catch {
            errorMessage = L10n.Plan.saveError
            isSaving = false
        }
    }
}

private struct SubscriptionEditorItem: Identifiable {
    let id = UUID()
    let subscription: Subscription?
}

private struct BalanceForecast: View {
    let balance: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Plan.forecastTitle)
                .font(.caption)
                .foregroundStyle(.green)

            HStack {
                Text(balance)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Spacer()
                ForecastLine()
                    .stroke(.green, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 92, height: 42)
            }
        }
        .padding(16)
        .glassEffect(.regular.tint(.green.opacity(0.18)), in: .rect(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }
}

private struct ForecastLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.25, y: rect.height * 0.68))
        path.addLine(to: CGPoint(x: rect.width * 0.42, y: rect.height * 0.76))
        path.addLine(to: CGPoint(x: rect.width * 0.62, y: rect.height * 0.38))
        path.addLine(to: CGPoint(x: rect.width * 0.78, y: rect.height * 0.48))
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        return path
    }
}

private struct BudgetProgress: View {
    let budget: PlannedBudget

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.Plan.budgetsTitle)
                    .font(.subheadline.weight(.bold))
                Spacer()
                Button(L10n.Plan.budgetsAll) { }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.indigo)
            }

            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(.orange)
                    .frame(width: 4, height: 52)

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(budget.title)
                                .font(.subheadline.weight(.semibold))
                            Text("\(budget.spent) / \(budget.limit)")
                                .font(.caption)
                        }
                        Spacer()
                        Text(budget.progress.formatted(.percent.precision(.fractionLength(0))))
                            .font(.subheadline.weight(.bold))
                    }

                    ProgressView(value: budget.progress)
                        .tint(.orange)
                }
            }

            Text(L10n.Plan.remaining(budget.remaining))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PlanPlaceholder: View {
    let title: String
    let symbol: String

    var body: some View {
        ContentUnavailableView(
            L10n.Plan.placeholderTitle(title),
            systemImage: symbol,
            description: Text(L10n.Plan.placeholderMessage)
        )
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }
}

private enum PlanSection: CaseIterable {
    case payments
    case budgets
    case goals

    var title: String {
        switch self {
        case .payments: L10n.Plan.sectionPayments
        case .budgets: L10n.Plan.sectionBudgets
        case .goals: L10n.Plan.sectionGoals
        }
    }
}

struct PlanSnapshot {
    let forecastBalance: String
    let budget: PlannedBudget

    static let preview = PlanSnapshot(
        forecastBalance: "3 890 AZN",
        budget: PlannedBudget(title: "Кафе и рестораны", spent: "186 AZN", limit: "250 AZN", remaining: "64 AZN", progress: 0.74)
    )
}

struct PlannedBudget {
    let title: String
    let spent: String
    let limit: String
    let remaining: String
    let progress: Double
}

#Preview("Светлая тема") {
    let container = AppContainer(isStoredInMemoryOnly: true)
    PlanView(
        snapshot: .preview,
        fetchTransactions: container.makeFetchTransactionsUseCase(),
        fetchSubscriptions: container.makeFetchSubscriptionsUseCase(),
        saveSubscription: container.makeSaveSubscriptionUseCase(),
        deleteSubscription: container.makeDeleteSubscriptionUseCase(),
        selectedTab: .constant(.plan)
    )
}

#Preview("Тёмная тема") {
    let container = AppContainer(isStoredInMemoryOnly: true)
    PlanView(
        snapshot: .preview,
        fetchTransactions: container.makeFetchTransactionsUseCase(),
        fetchSubscriptions: container.makeFetchSubscriptionsUseCase(),
        saveSubscription: container.makeSaveSubscriptionUseCase(),
        deleteSubscription: container.makeDeleteSubscriptionUseCase(),
        selectedTab: .constant(.plan)
    )
        .preferredColorScheme(.dark)
}
