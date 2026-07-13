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
    let fetchBudgets: FetchBudgetsUseCase
    let saveBudget: SaveBudgetUseCase
    let deleteBudget: DeleteBudgetUseCase
    let fetchGoals: FetchSavingsGoalsUseCase
    let saveGoal: SaveSavingsGoalUseCase
    let deleteGoal: DeleteSavingsGoalUseCase
    @Binding var selectedTab: AppTab
    @State private var section: PlanSection = .payments
    @State private var transactions: [Transaction] = []
    @State private var subscriptions: [Subscription] = []
    @State private var budgets: [Budget] = []
    @State private var budgetOverview = BudgetOverview(budgets: [], transactions: [])
    @State private var goals: [SavingsGoal] = []
    @State private var goalsOverview = SavingsGoalsOverview(goals: [], transactions: [])
    @State private var editorItem: PlanEditorItem?
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

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }

                            switch section {
                            case .payments:
                                paymentsContent
                            case .budgets:
                                budgetsContent
                            case .goals:
                                goalsContent
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
                switch item.kind {
                case .subscription(let subscription):
                    SubscriptionEditorView(
                        subscription: subscription,
                        saveSubscription: saveSubscription
                    ) { saved in
                        if let index = subscriptions.firstIndex(where: { $0.id == saved.id }) {
                            subscriptions[index] = saved
                        } else {
                            subscriptions.append(saved)
                        }
                        subscriptions.sort { $0.nextChargeDate < $1.nextChargeDate }
                    }

                case .budget(let budget):
                    BudgetEditorView(
                        budget: budget,
                        categoryOptions: budgetCategoryOptions,
                        existingBudgets: budgets,
                        saveBudget: saveBudget
                    ) { saved in
                        if let index = budgets.firstIndex(where: { $0.id == saved.id }) {
                            budgets[index] = saved
                        } else {
                            budgets.append(saved)
                        }
                        budgets.sort { $0.category.localizedStandardCompare($1.category) == .orderedAscending }
                        refreshBudgetOverview()
                    }

                case .goal(let goal):
                    SavingsGoalEditorView(
                        goal: goal,
                        saveGoal: saveGoal,
                        onDelete: deleteGoalItem,
                        onSaved: updateGoal
                    )

                case .goalContribution(let goal):
                    SavingsGoalContributionView(goal: goal, saveGoal: saveGoal) { saved in
                        updateGoal(saved)
                    }
                }
            }
            .task { await loadPlan() }
        }
    }

    private var header: some View {
        HStack {
            Text(L10n.Plan.title)
                .font(.title3.weight(.bold))
            Spacer()
            Button {
                switch section {
                case .payments:
                    editorItem = PlanEditorItem(kind: .subscription(nil))
                case .budgets:
                    editorItem = PlanEditorItem(kind: .budget(nil))
                case .goals:
                    editorItem = PlanEditorItem(kind: .goal(nil))
                }
            } label: {
                Image(systemName: "plus")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .glassEffect(.regular.tint(.indigo).interactive(), in: .circle)
            }
            .accessibilityLabel(addButtonLabel)
        }
    }

    private var addButtonLabel: String {
        switch section {
        case .payments: L10n.Plan.addSubscription
        case .budgets: L10n.Plan.addBudget
        case .goals: L10n.Plan.addGoal
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
                onEdit: { editorItem = PlanEditorItem(kind: .subscription($0)) },
                onDelete: deleteSubscription
            )

            BalanceForecast(balance: snapshot.forecastBalance)
            if !budgetOverview.items.isEmpty {
                BudgetPreviewCard(overview: budgetOverview) {
                    section = .budgets
                }
            }
        }
    }

    private var budgetsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if budgets.isEmpty {
                ContentUnavailableView(
                    L10n.Plan.budgetEmptyTitle,
                    systemImage: "chart.bar.fill",
                    description: Text(L10n.Plan.budgetEmptyMessage)
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 44)
                .glassEffect(.regular, in: .rect(cornerRadius: 22))
            } else {
                BudgetSummaryCard(overview: budgetOverview)

                ForEach(budgetOverview.items) { item in
                    Button {
                        editorItem = PlanEditorItem(kind: .budget(item.budget))
                    } label: {
                        BudgetRow(progress: item)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(L10n.Plan.deleteBudget, systemImage: "trash", role: .destructive) {
                            deleteBudgetItem(item.budget)
                        }
                    }
                    .accessibilityAction(named: L10n.Plan.deleteBudget) {
                        deleteBudgetItem(item.budget)
                    }
                }

                if budgetOverview.unbudgetedSpent > 0 {
                    Label(
                        L10n.Plan.unbudgetedSpending(OperationFormatting.plain(budgetOverview.unbudgetedSpent)),
                        systemImage: "exclamationmark.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var goalsContent: some View {
        SavingsGoalsContent(
            overview: goalsOverview,
            onCreate: { editorItem = PlanEditorItem(kind: .goal(nil)) },
            onEdit: { editorItem = PlanEditorItem(kind: .goal($0)) },
            onContribute: { editorItem = PlanEditorItem(kind: .goalContribution($0)) },
            onDelete: deleteGoalItem
        )
    }

    private var budgetCategoryOptions: [BudgetCategoryOption] {
        let used = transactions
            .filter { $0.kind == .expense }
            .sorted { $0.date > $1.date }
            .map { BudgetCategoryOption(name: $0.category, icon: $0.categoryIcon) }
        let saved = budgets.map { BudgetCategoryOption(name: $0.category, icon: $0.categoryIcon) }
        let defaults = L10n.AddOperation.defaultExpenseCategories.map {
            BudgetCategoryOption(name: $0, icon: CategoryIcon.suggested(for: $0, kind: .expense))
        }

        var seen = Set<String>()
        return (used + saved + defaults).filter {
            seen.insert(Budget.categoryKey(for: $0.name)).inserted
        }
    }

    private func loadPlan() async {
        do {
            async let loadedTransactions = fetchTransactions.execute()
            async let loadedSubscriptions = fetchSubscriptions.execute()
            async let loadedBudgets = fetchBudgets.execute()
            async let loadedGoals = fetchGoals.execute()

            transactions = try await loadedTransactions
            subscriptions = try await loadedSubscriptions
            budgets = try await loadedBudgets
            goals = try await loadedGoals
            refreshBudgetOverview()
            refreshGoalsOverview()
            errorMessage = nil
        } catch {
            errorMessage = L10n.Plan.loadError
        }
    }

    private func refreshBudgetOverview() {
        budgetOverview = BudgetOverview(budgets: budgets, transactions: transactions)
    }

    private func refreshGoalsOverview() {
        goalsOverview = SavingsGoalsOverview(goals: goals, transactions: transactions)
    }

    private func updateGoal(_ goal: SavingsGoal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
        } else {
            goals.append(goal)
        }
        refreshGoalsOverview()
    }

    private func deleteSubscription(_ subscription: Subscription) {
        Task {
            do {
                try await deleteSubscription.execute(id: subscription.id)
                subscriptions.removeAll { $0.id == subscription.id }
            } catch {
                errorMessage = L10n.Plan.deleteError
            }
        }
    }

    private func deleteBudgetItem(_ budget: Budget) {
        Task {
            do {
                try await deleteBudget.execute(id: budget.id)
                budgets.removeAll { $0.id == budget.id }
                refreshBudgetOverview()
            } catch {
                errorMessage = L10n.Plan.budgetDeleteError
            }
        }
    }

    private func deleteGoalItem(_ goal: SavingsGoal) {
        Task {
            do {
                try await deleteGoal.execute(id: goal.id)
                goals.removeAll { $0.id == goal.id }
                refreshGoalsOverview()
            } catch {
                errorMessage = L10n.Plan.goalDeleteError
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

private struct PlanEditorItem: Identifiable {
    enum Kind {
        case subscription(Subscription?)
        case budget(Budget?)
        case goal(SavingsGoal?)
        case goalContribution(SavingsGoal)
    }

    let id = UUID()
    let kind: Kind
}

private struct BudgetEditorView: View {
    let budget: Budget?
    let categoryOptions: [BudgetCategoryOption]
    let existingBudgets: [Budget]
    let saveBudget: SaveBudgetUseCase
    let onSaved: (Budget) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var category: String
    @State private var categoryIcon: String
    @State private var limitText: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: BudgetField?

    init(
        budget: Budget?,
        categoryOptions: [BudgetCategoryOption],
        existingBudgets: [Budget],
        saveBudget: SaveBudgetUseCase,
        onSaved: @escaping (Budget) -> Void
    ) {
        self.budget = budget
        self.categoryOptions = categoryOptions
        self.existingBudgets = existingBudgets
        self.saveBudget = saveBudget
        self.onSaved = onSaved
        _category = State(initialValue: budget?.category ?? "")
        _categoryIcon = State(initialValue: budget?.categoryIcon ?? CategoryIcon.fallback)
        _limitText = State(initialValue: budget.map { "\($0.monthlyLimit)" } ?? "")
    }

    private var trimmedCategory: String {
        category.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var monthlyLimit: Decimal? {
        let normalized = limitText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")), value > 0 else {
            return nil
        }
        return value
    }

    private var hasDuplicateCategory: Bool {
        let key = Budget.categoryKey(for: trimmedCategory)
        return existingBudgets.contains { $0.id != budget?.id && $0.categoryKey == key }
    }

    private var canSave: Bool {
        !trimmedCategory.isEmpty &&
            trimmedCategory.count <= 60 &&
            monthlyLimit != nil &&
            !hasDuplicateCategory &&
            !isSaving
    }

    private var filteredCategoryOptions: [BudgetCategoryOption] {
        guard !trimmedCategory.isEmpty else { return categoryOptions }
        return categoryOptions.filter {
            $0.name.localizedCaseInsensitiveContains(trimmedCategory) &&
                $0.name.caseInsensitiveCompare(trimmedCategory) != .orderedSame
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.Plan.budgetSectionCategory) {
                    TextField(L10n.AddOperation.categoryPlaceholder, text: $category)
                        .focused($focusedField, equals: .category)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .limit }
                        .onChange(of: category) { _, value in
                            categoryIcon = categoryOptions.first {
                                $0.name.caseInsensitiveCompare(value) == .orderedSame
                            }?.icon ?? CategoryIcon.suggested(for: value, kind: .expense)
                        }

                    if category.count > 60 {
                        Text(L10n.AddOperation.categoryTooLong)
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if hasDuplicateCategory {
                        Text(L10n.Plan.budgetDuplicateCategory)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    if !filteredCategoryOptions.isEmpty {
                        ScrollView(.horizontal) {
                            GlassEffectContainer(spacing: 8) {
                                LazyHStack(spacing: 8) {
                                    ForEach(filteredCategoryOptions) { option in
                                        Button {
                                            category = option.name
                                            categoryIcon = option.icon
                                            focusedField = .limit
                                        } label: {
                                            Label(option.name, systemImage: option.icon)
                                        }
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.primary)
                                        .padding(.horizontal, 14)
                                        .frame(height: 32)
                                        .glassEffect(.regular.interactive(), in: .capsule)
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                }

                Section(L10n.Plan.budgetSectionLimit) {
                    HStack {
                        TextField("0", text: $limitText)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .limit)
                        Text(CurrencySettings.selectedCode)
                            .foregroundStyle(.secondary)
                    }
                    Text(L10n.Plan.budgetMonthlyHint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background { DashboardBackground() }
            .navigationTitle(budget == nil ? L10n.Plan.budgetTitleNew : L10n.Plan.budgetTitleEdit)
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
            .onAppear { focusedField = .category }
        }
    }

    private func save() async {
        guard let monthlyLimit, canSave else { return }
        isSaving = true
        errorMessage = nil

        let saved = Budget(
            id: budget?.id ?? UUID(),
            category: trimmedCategory,
            categoryIcon: categoryIcon,
            monthlyLimit: monthlyLimit
        )
        do {
            try await saveBudget.execute(saved)
            onSaved(saved)
            dismiss()
        } catch {
            errorMessage = L10n.Plan.budgetSaveError
            isSaving = false
        }
    }
}

private struct BudgetCategoryOption: Identifiable {
    let name: String
    let icon: String

    var id: String { Budget.categoryKey(for: name) }
}

private enum BudgetField {
    case category
    case limit
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

private struct BudgetPreviewCard: View {
    let overview: BudgetOverview
    let onShowAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.Plan.budgetsTitle)
                    .font(.subheadline.weight(.bold))
                Spacer()
                Button(L10n.Plan.budgetsAll, action: onShowAll)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.indigo)
            }

            Text(L10n.Plan.budgetSpentOf(
                OperationFormatting.plain(overview.totalSpent),
                OperationFormatting.plain(overview.totalLimit)
            ))
            .font(.subheadline.weight(.semibold))

            ProgressView(value: min(max(budgetProgress, 0), 1))
                .tint(overview.remaining < 0 ? .red : .indigo)

            Text(remainingText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
    }

    private var budgetProgress: Double {
        guard overview.totalLimit > 0 else { return 0 }
        return NSDecimalNumber(decimal: overview.totalSpent / overview.totalLimit).doubleValue
    }

    private var remainingText: String {
        if overview.remaining < 0 {
            return L10n.Plan.budgetOverBy(OperationFormatting.plain(-overview.remaining))
        }
        return L10n.Plan.remaining(OperationFormatting.plain(overview.remaining))
    }
}

private struct BudgetSummaryCard: View {
    let overview: BudgetOverview

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(monthTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.indigo)

            Text(L10n.Plan.budgetSpentOf(
                OperationFormatting.plain(overview.totalSpent),
                OperationFormatting.plain(overview.totalLimit)
            ))
            .font(.title3.weight(.bold))

            ProgressView(value: min(max(progress, 0), 1))
                .tint(overview.remaining < 0 ? .red : .indigo)

            if overview.remaining < 0 {
                Text(L10n.Plan.budgetOverBy(OperationFormatting.plain(-overview.remaining)))
                    .font(.caption)
                    .foregroundStyle(.red)
            } else {
                HStack {
                    Text(L10n.Plan.remaining(OperationFormatting.plain(overview.remaining)))
                    Spacer()
                    Text(L10n.Plan.budgetPerDay(OperationFormatting.plain(overview.dailyAllowance)))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .glassEffect(.regular.tint(.indigo.opacity(0.14)), in: .rect(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }

    private var progress: Double {
        guard overview.totalLimit > 0 else { return 0 }
        return NSDecimalNumber(decimal: overview.totalSpent / overview.totalLimit).doubleValue
    }

    private var monthTitle: String {
        let month = overview.period.start.formatted(
            .dateTime
                .month(.wide)
                .year()
                .locale(Locale(identifier: LocalizationManager.shared.currentLanguage))
        )
        return L10n.Plan.budgetMonthTitle(month)
    }
}

private struct BudgetRow: View {
    let progress: BudgetProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: progress.budget.categoryIcon)
                    .font(.headline)
                    .foregroundStyle(paceColor)
                    .frame(width: 38, height: 38)
                    .background(paceColor.opacity(0.14), in: .circle)

                VStack(alignment: .leading, spacing: 3) {
                    Text(progress.budget.category)
                        .font(.subheadline.weight(.semibold))
                    Text(paceTitle)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(paceColor)
                }

                Spacer()

                Text(progress.progress.formatted(.percent.precision(.fractionLength(0))))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(paceColor)
            }

            Text(L10n.Plan.budgetSpentOf(
                OperationFormatting.plain(progress.spent),
                OperationFormatting.plain(progress.budget.monthlyLimit)
            ))
            .font(.caption)

            ProgressView(value: min(max(progress.progress, 0), 1))
                .tint(paceColor)

            HStack {
                Text(remainingText)
                Spacer()
                if progress.pace == .atRisk {
                    Text(L10n.Plan.budgetProjected(OperationFormatting.plain(progress.projectedSpend)))
                } else if progress.remaining >= 0 {
                    Text(L10n.Plan.budgetPerDay(OperationFormatting.plain(progress.dailyAllowance)))
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .glassEffect(.regular.tint(paceColor.opacity(0.1)).interactive(), in: .rect(cornerRadius: 20))
    }

    private var paceColor: Color {
        switch progress.pace {
        case .onTrack: .green
        case .atRisk: .orange
        case .over: .red
        }
    }

    private var paceTitle: String {
        switch progress.pace {
        case .onTrack: L10n.Plan.budgetPaceOnTrack
        case .atRisk: L10n.Plan.budgetPaceAtRisk
        case .over: L10n.Plan.budgetPaceOver
        }
    }

    private var remainingText: String {
        if progress.remaining < 0 {
            return L10n.Plan.budgetOverBy(OperationFormatting.plain(-progress.remaining))
        }
        return L10n.Plan.remaining(OperationFormatting.plain(progress.remaining))
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

    static let preview = PlanSnapshot(
        forecastBalance: "3 890 AZN"
    )
}

#Preview("Светлая тема") {
    let container = AppContainer(isStoredInMemoryOnly: true)
    PlanView(
        snapshot: .preview,
        fetchTransactions: container.makeFetchTransactionsUseCase(),
        fetchSubscriptions: container.makeFetchSubscriptionsUseCase(),
        saveSubscription: container.makeSaveSubscriptionUseCase(),
        deleteSubscription: container.makeDeleteSubscriptionUseCase(),
        fetchBudgets: container.makeFetchBudgetsUseCase(),
        saveBudget: container.makeSaveBudgetUseCase(),
        deleteBudget: container.makeDeleteBudgetUseCase(),
        fetchGoals: container.makeFetchSavingsGoalsUseCase(),
        saveGoal: container.makeSaveSavingsGoalUseCase(),
        deleteGoal: container.makeDeleteSavingsGoalUseCase(),
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
        fetchBudgets: container.makeFetchBudgetsUseCase(),
        saveBudget: container.makeSaveBudgetUseCase(),
        deleteBudget: container.makeDeleteBudgetUseCase(),
        fetchGoals: container.makeFetchSavingsGoalsUseCase(),
        saveGoal: container.makeSaveSavingsGoalUseCase(),
        deleteGoal: container.makeDeleteSavingsGoalUseCase(),
        selectedTab: .constant(.plan)
    )
        .preferredColorScheme(.dark)
}
