//
//  OperationsView.swift
//  Ask Numi
//

import SwiftUI

struct OperationsView: View {
    @Environment(\.appAccentColor) private var accentColor
    let fetchTransactions: FetchTransactionsUseCase
    let fetchCategories: FetchTransactionCategoriesUseCase
    let fetchSubscriptions: FetchSubscriptionsUseCase
    let fetchBudgets: FetchBudgetsUseCase
    let fetchGoals: FetchSavingsGoalsUseCase
    let addCategory: AddTransactionCategoryUseCase
    let updateCategory: UpdateTransactionCategoryUseCase
    let addTransaction: AddTransactionUseCase
    let saveGoals: SaveSavingsGoalUseCase
    let updateTransaction: UpdateTransactionUseCase
    let deleteTransaction: DeleteTransactionUseCase
    let parseNaturalInput: ParseNaturalInputUseCase
    let transactionClassifier: any TransactionClassifier

    @State private var transactions: [Transaction] = []
    @State private var categories: [TransactionCategory] = []
    @State private var query = ""
    @State private var filter: OperationsFilter = .all
    @State private var presentation: OperationsPresentation = .daily
    @State private var displayedMonth = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    @State private var selectedDate = Calendar.current.startOfDay(for: .now)
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isPresentingAddOperation = false
    @State private var pendingSalaryAutopilotIncome: Transaction?
    @State private var salaryAutopilotIncome: Transaction?
    @State private var editingTransaction: Transaction?
    @State private var deleteErrorMessage: String?

    private var filteredTransactions: [Transaction] {
        transactions.filter { transaction in
            filter.matches(transaction) &&
                (query.isEmpty || transaction.category.localizedCaseInsensitiveContains(query))
        }
    }

    private var receiptPriceInsights: ReceiptPriceInsights {
        ReceiptPriceInsights(transactions: transactions)
    }

    private var sections: [OperationDaySection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredTransactions) { calendar.startOfDay(for: $0.date) }

        return grouped.keys.sorted(by: >).compactMap { date in
            guard let transactions = grouped[date] else { return nil }
            return OperationDaySection(
                date: date,
                transactions: transactions.sorted { $0.date > $1.date },
                totalExpenses: total(for: transactions, kind: .expense),
                totalIncome: total(for: transactions, kind: .income)
            )
        }
    }

    private var selectedDaySection: OperationDaySection? {
        let calendar = Calendar.current
        let dayTransactions = filteredTransactions
            .filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.date > $1.date }
        guard !dayTransactions.isEmpty else { return nil }

        return OperationDaySection(
            date: calendar.startOfDay(for: selectedDate),
            transactions: dayTransactions,
            totalExpenses: total(for: dayTransactions, kind: .expense),
            totalIncome: total(for: dayTransactions, kind: .income)
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DashboardBackground()

                ScrollView {
                    GlassEffectContainer(spacing: 18) {
                        LazyVStack(alignment: .leading, spacing: 18) {
                            content
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .safeAreaBar(edge: .top) {
                pinnedControls
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isPresentingAddOperation, onDismiss: presentSalaryAutopilotIfNeeded) {
                AddOperationView(
                    addTransaction: addTransaction,
                    updateTransaction: updateTransaction,
                    existingTransactions: transactions,
                    categories: categories,
                    addCategory: addCategory,
                    updateCategory: updateCategory,
                    parseNaturalInput: parseNaturalInput,
                    transactionClassifier: transactionClassifier
                ) { transaction in
                    transactions.append(transaction)
                    transactions.sort { $0.date > $1.date }
                    if transaction.kind == .income {
                        pendingSalaryAutopilotIncome = transaction
                    }
                } onCategorySaved: { category in
                    storeCategory(category)
                }
            }
            .sheet(item: $editingTransaction) { transaction in
                AddOperationView(
                    addTransaction: addTransaction,
                    updateTransaction: updateTransaction,
                    existingTransactions: transactions,
                    categories: categories,
                    addCategory: addCategory,
                    updateCategory: updateCategory,
                    transactionClassifier: transactionClassifier,
                    editing: transaction
                ) { updated in
                    if let index = transactions.firstIndex(where: { $0.id == updated.id }) {
                        transactions[index] = updated
                        transactions.sort { $0.date > $1.date }
                    }
                } onCategorySaved: { category in
                    storeCategory(category)
                }
            }
            .sheet(item: $salaryAutopilotIncome) { income in
                SalaryAutopilotPreviewView(
                    income: income,
                    transactions: transactions,
                    fetchSubscriptions: fetchSubscriptions,
                    fetchBudgets: fetchBudgets,
                    fetchGoals: fetchGoals,
                    saveGoals: saveGoals
                )
            }
            .alert(
                L10n.Operations.deleteAlertTitle,
                isPresented: Binding(
                    get: { deleteErrorMessage != nil },
                    set: { if !$0 { deleteErrorMessage = nil } }
                )
            ) {
                Button(L10n.Operations.deleteAlertOk, role: .cancel) {}
            } message: {
                Text(deleteErrorMessage ?? "")
            }
            .task {
                #if DEBUG
                OperationCalendarLayout.assertSelfCheck()
                #endif
                await loadData()
            }
        }
    }

    private var pinnedControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            searchField
            filters
        }
        .frame(maxWidth: .infinity)
    }

    private var header: some View {
        HStack {
            Text(L10n.Operations.title)
                .font(.title3.weight(.bold))

            Spacer()

            Button {
                isPresentingAddOperation = true
            } label: {
                Image(systemName: "plus")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .glassEffect(.regular.tint(accentColor).interactive(), in: .circle)
            }
            .accessibilityLabel(L10n.Operations.addLabel)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(L10n.Operations.searchPlaceholder, text: $query)
                .font(.subheadline)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(L10n.Operations.clearSearchLabel)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .glassEffect(.regular, in: .capsule)
    }

    private var filters: some View {
        HStack(spacing: 8) {
            ForEach(OperationsFilter.allCases, id: \.self) { item in
                Button {
                    filter = item
                } label: {
                    Text(item.title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(filter == item ? .white : .primary)
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .glassEffect(.regular.tint(filter == item ? accentColor : .clear).interactive(), in: .capsule)
                .accessibilityAddTraits(filter == item ? .isSelected : [])
            }

            presentationMenu
        }
        .frame(maxWidth: .infinity)
    }

    private var presentationMenu: some View {
        Menu {
            Picker(L10n.Operations.presentationPickerLabel, selection: $presentation) {
                ForEach(OperationsPresentation.allCases, id: \.self) { presentation in
                    Label(presentation.title, systemImage: presentation.systemImage)
                        .tag(presentation)
                }
            }
        } label: {
            Text(presentation.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
        }
        .frame(maxWidth: .infinity)
        .glassEffect(.regular.interactive(), in: .capsule)
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && transactions.isEmpty {
            ProgressView(L10n.Operations.loading)
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
        } else if let errorMessage, transactions.isEmpty {
            ContentUnavailableView {
                Label(L10n.Operations.loadErrorTitle, systemImage: "exclamationmark.triangle")
            } description: {
                Text(errorMessage)
            } actions: {
                Button(L10n.Common.retry) {
                    Task { await loadData() }
                }
            }
            .padding(.top, 48)
        } else if transactions.isEmpty {
            ContentUnavailableView {
                Label(L10n.Operations.emptyTitle, systemImage: "tray")
            } description: {
                Text(L10n.Operations.emptyMessage)
            } actions: {
                Button(L10n.Operations.emptyAddButton) {
                    isPresentingAddOperation = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 48)
        } else {
            let priceInsights = receiptPriceInsights
            if priceInsights.hasInsights {
                ReceiptPriceInsightsCard(insights: priceInsights)
            }

            switch presentation {
            case .daily:
                dailyContent
            case .calendar:
                calendarContent
            case .monthly:
                monthlyContent
            }
        }
    }

    @ViewBuilder
    private var dailyContent: some View {
        if sections.isEmpty {
            ContentUnavailableView.search(text: query)
                .padding(.top, 48)
        } else {
            ForEach(sections) { section in
                transactionSection(section)
            }
        }
    }

    @ViewBuilder
    private var calendarContent: some View {
        OperationsCalendarView(
            transactions: filteredTransactions,
            displayedMonth: $displayedMonth,
            selectedDate: $selectedDate
        )

        if let selectedDaySection {
            transactionSection(selectedDaySection)
        } else {
            ContentUnavailableView {
                Label(L10n.Operations.selectedDateEmptyTitle, systemImage: "calendar.badge.minus")
            } description: {
                Text(L10n.Operations.selectedDateEmptyMessage)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }

    @ViewBuilder
    private var monthlyContent: some View {
        if filteredTransactions.isEmpty {
            ContentUnavailableView {
                Label(L10n.Operations.periodEmptyTitle, systemImage: "calendar")
            } description: {
                Text(L10n.Operations.periodEmptyMessage)
            }
            .padding(.top, 48)
        } else {
            OperationsMonthlyView(transactions: filteredTransactions)
        }
    }

    private func transactionSection(_ section: OperationDaySection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(section.title)
                    .font(.subheadline.weight(.bold))

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if section.totalExpenses > 0 {
                        Text(L10n.Operations.sectionExpenses(OperationFormatting.amount(section.totalExpenses, sign: .expense)))
                            .foregroundStyle(.red)
                    }
                    if section.totalIncome > 0 {
                        Text(L10n.Operations.sectionIncome(OperationFormatting.amount(section.totalIncome, sign: .income)))
                            .foregroundStyle(.green)
                    }
                }
                .font(.caption.weight(.semibold))
            }

            VStack(spacing: 0) {
                ForEach(section.transactions) { transaction in
                    OperationsRow(transaction: transaction)
                        .contentShape(.rect)
                        .onTapGesture {
                            editingTransaction = transaction
                        }
                        .contextMenu {
                            Button(L10n.Operations.deleteAction, systemImage: "trash", role: .destructive) {
                                delete(transaction)
                            }
                        }
                        .accessibilityAction(named: L10n.Operations.deleteAction) {
                            delete(transaction)
                        }

                    if transaction.id != section.transactions.last?.id {
                        Divider().padding(.leading, 54)
                    }
                }
            }
            .padding(.horizontal, 12)
            .glassEffect(.regular, in: .rect(cornerRadius: 20))
        }
    }

    private func total(for transactions: [Transaction], kind: TransactionKind) -> Decimal {
        transactions.lazy
            .filter { $0.kind == kind }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    private func delete(_ transaction: Transaction) {
        Task {
            do {
                try await deleteTransaction.execute(id: transaction.id)
                withAnimation(.spring(duration: 0.3)) {
                    transactions.removeAll { $0.id == transaction.id }
                }
            } catch {
                deleteErrorMessage = error.localizedDescription
            }
        }
    }

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let loadedTransactions = fetchTransactions.execute()
            async let loadedCategories = fetchCategories.execute()
            transactions = try await loadedTransactions
            categories = try await loadedCategories
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func storeCategory(_ category: TransactionCategory) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
        } else {
            categories.append(category)
        }
        categories.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private func presentSalaryAutopilotIfNeeded() {
        salaryAutopilotIncome = pendingSalaryAutopilotIncome
        pendingSalaryAutopilotIncome = nil
    }
}

private struct ReceiptPriceInsightsCard: View {
    let insights: ReceiptPriceInsights

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.ReceiptPrices.title, systemImage: "cart.badge.clock")
                .font(.headline)

            if let basket = insights.basketChange {
                Label {
                    Text(basketText(basket))
                } icon: {
                    Image(systemName: basket.percent > 0 ? "arrow.up.right" : basket.percent < 0 ? "arrow.down.right" : "equal")
                        .foregroundStyle(basket.percent > 0 ? .orange : .green)
                }
                .font(.subheadline)
            }

            if !insights.topIncreasingItems.isEmpty {
                Text(L10n.ReceiptPrices.topItems)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(insights.topIncreasingItems) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(item.name)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(L10n.ReceiptPrices.itemIncrease(
                            item.increaseCount,
                            OperationFormatting.plain(item.addedCost)
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                    }
                }
            }

            Text(L10n.ReceiptPrices.method)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
    }

    private func basketText(_ basket: ReceiptBasketPriceChange) -> String {
        let previous = OperationFormatting.plain(basket.previousTotal)
        let current = OperationFormatting.plain(basket.currentTotal)
        if basket.percent > 0 {
            return L10n.ReceiptPrices.basketUp(basket.percent, basket.itemCount, previous, current)
        }
        if basket.percent < 0 {
            return L10n.ReceiptPrices.basketDown(abs(basket.percent), basket.itemCount, previous, current)
        }
        return L10n.ReceiptPrices.basketStable(basket.itemCount, current)
    }
}

private struct OperationsRow: View {
    let transaction: Transaction

    private var title: String {
        transaction.note ?? transaction.category
    }

    private var details: String {
        let categoryOrKind = transaction.note == nil ? transaction.kind.title : transaction.category
        return transaction.fundingSource.map { "\(categoryOrKind) · \($0)" } ?? categoryOrKind
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.categoryIcon)
                .font(.body.weight(.semibold))
                .foregroundStyle(transaction.categoryColor.displayColor)
                .frame(width: 42, height: 42)
                .background(
                    transaction.categoryColor.displayColor.opacity(0.14),
                    in: .rect(cornerRadius: 13)
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    if transaction.isImpulse {
                        Image(systemName: "bolt.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .accessibilityLabel(L10n.Operations.impulseLabel)
                    }
                }
                Text(details)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(OperationFormatting.amount(transaction.amount, sign: transaction.kind))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(transaction.kind == .income ? .green : .red)
                Text(transaction.date.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 9)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

private struct AddOperationView: View {
    let addTransaction: AddTransactionUseCase
    let updateTransaction: UpdateTransactionUseCase
    let existingTransactions: [Transaction]
    let categories: [TransactionCategory]
    let addCategory: AddTransactionCategoryUseCase
    let updateCategory: UpdateTransactionCategoryUseCase
    /// Optional on-device parser. When present and available, a quick-add
    /// field lets the user describe the operation in words. Omitted (nil)
    /// when editing an existing operation.
    let parseNaturalInput: ParseNaturalInputUseCase?
    let editing: Transaction?
    let onSaved: (Transaction) -> Void
    let onCategorySaved: (TransactionCategory) -> Void
    private let receiptImporter: ReceiptImportService

    init(
        addTransaction: AddTransactionUseCase,
        updateTransaction: UpdateTransactionUseCase,
        existingTransactions: [Transaction],
        categories: [TransactionCategory],
        addCategory: AddTransactionCategoryUseCase,
        updateCategory: UpdateTransactionCategoryUseCase,
        parseNaturalInput: ParseNaturalInputUseCase? = nil,
        transactionClassifier: any TransactionClassifier,
        editing: Transaction? = nil,
        onSaved: @escaping (Transaction) -> Void,
        onCategorySaved: @escaping (TransactionCategory) -> Void
    ) {
        self.addTransaction = addTransaction
        self.updateTransaction = updateTransaction
        self.existingTransactions = existingTransactions
        self.categories = categories
        self.addCategory = addCategory
        self.updateCategory = updateCategory
        self.parseNaturalInput = parseNaturalInput
        self.editing = editing
        self.onSaved = onSaved
        self.onCategorySaved = onCategorySaved
        receiptImporter = ReceiptImportService(classifier: transactionClassifier)

        if let editing {
            _kind = State(initialValue: editing.kind)
            _category = State(initialValue: editing.category)
            _categoryIcon = State(initialValue: editing.categoryIcon)
            _categoryColor = State(initialValue: editing.categoryColor)
            _fundingSource = State(initialValue: editing.fundingSource ?? "")
            _amountText = State(initialValue: "\(editing.amount)")
            _date = State(initialValue: editing.date)
            _isImpulse = State(initialValue: editing.isImpulse)
        }
        _classificationViewModel = State(initialValue: AddOperationClassificationViewModel(
            classifier: transactionClassifier,
            merchantText: editing?.note ?? ""
        ))
        _hasUserSelectedCategory = State(initialValue: editing != nil)
    }

    private static let defaultCategories: [TransactionKind: [String]] = [
        .expense: L10n.AddOperation.defaultExpenseCategories,
        .income: L10n.AddOperation.defaultIncomeCategories
    ]

    @Environment(\.dismiss) private var dismiss
    @State private var kind: TransactionKind = .expense
    @State private var category = ""
    @State private var categoryIcon = CategoryIcon.fallback
    @State private var categoryColor = CategoryColor.defaultColor(for: .expense)
    @State private var fundingSource = ""
    @State private var amountText = ""
    @State private var date = Date.now
    @State private var isImpulse = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var magicText = ""
    @State private var isParsing = false
    @State private var magicError: String?
    @State private var isPresentingReceiptScanner = false
    @State private var capturedReceipt: CapturedReceipt?
    @State private var isImportingReceipt = false
    @State private var receiptError: String?
    @State private var receiptDrafts: [ReceiptExpenseDraft] = []
    @State private var isPresentingReceiptReview = false
    @State private var didSaveReceipt = false
    @State private var classificationViewModel: AddOperationClassificationViewModel
    @State private var hasUserSelectedCategory: Bool
    @FocusState private var focusedField: Field?

    private var showsQuickAdd: Bool {
        editing == nil && (parseNaturalInput?.isAvailable ?? false)
    }

    private var trimmedMagicText: String {
        magicText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedCategory: String {
        category.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedFundingSource: String {
        fundingSource.trimmingCharacters(in: .whitespacesAndNewlines)
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
        !trimmedCategory.isEmpty &&
            trimmedCategory.count <= 60 &&
            amount != nil &&
            (kind == .income || !trimmedFundingSource.isEmpty) &&
            !isSaving &&
            !isImportingReceipt
    }

    private var availableCategories: [OperationCategorySuggestion] {
        suggestions(for: kind)
    }

    private var availableFundingSources: [OperationCategorySuggestion] {
        suggestions(for: .income)
    }

    private var fundingSourceIcon: String {
        availableFundingSources.first {
            $0.name.caseInsensitiveCompare(fundingSource) == .orderedSame
        }?.icon ?? "creditcard"
    }

    private var kindSelection: Binding<TransactionKind> {
        Binding(get: { kind }, set: selectKind)
    }

    // Saved categories first, then recent operations and defaults; deduped case-insensitively.
    private func suggestions(for kind: TransactionKind) -> [OperationCategorySuggestion] {
        let savedCategories = categories
            .filter { $0.kind == kind }
            .map { OperationCategorySuggestion(name: $0.name, icon: $0.icon, color: $0.color, savedCategory: $0) }
        let savedTransactions = existingTransactions
            .filter { $0.kind == kind }
            .sorted { $0.date > $1.date }
            .map { OperationCategorySuggestion(name: $0.category, icon: $0.categoryIcon, color: $0.categoryColor) }
        let defaults = (Self.defaultCategories[kind] ?? []).map {
            OperationCategorySuggestion(
                name: $0,
                icon: CategoryIcon.suggested(for: $0, kind: kind),
                color: CategoryColor.defaultColor(for: kind)
            )
        }

        var seen = Set<String>()
        return (savedCategories + savedTransactions + defaults)
            .filter { seen.insert($0.name.lowercased()).inserted }
    }

    var body: some View {
        @Bindable var classification = classificationViewModel

        NavigationStack {
            Form {
                if showsQuickAdd {
                    quickAddSection
                }

                Section(L10n.AddOperation.sectionKind) {
                    Picker(L10n.AddOperation.sectionKind, selection: kindSelection) {
                        ForEach(TransactionKind.allCases, id: \.self) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(kind == .expense ? .red : .green)
                }
                .listRowBackground(Color(uiColor: .secondarySystemBackground))

                if editing == nil && kind == .expense {
                    receiptSection
                }

                Section(kind == .income ? L10n.AddOperation.sectionIncomeSource : L10n.AddOperation.sectionCategory) {
                    NavigationLink {
                        CategorySelectionView(
                            kind: kind,
                            categories: availableCategories,
                            selectedCategory: category,
                            navigationTitle: kind == .income
                                ? L10n.AddOperation.sectionIncomeSource
                                : L10n.AddOperation.selectCategory,
                            addCategory: addCategory,
                            updateCategory: updateCategory,
                            onSelect: { selected in
                                kind = selected.kind
                                category = selected.name
                                categoryIcon = selected.icon
                                categoryColor = selected.color
                                hasUserSelectedCategory = true
                                focusedField = .amount
                            },
                            onCategorySaved: onCategorySaved
                        )
                    } label: {
                        Label(
                            category.isEmpty ? L10n.AddOperation.selectCategory : category,
                            systemImage: category.isEmpty ? CategoryIcon.fallback : categoryIcon
                        )
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemBackground))

                if kind == .expense {
                    fundingSourceSection
                }

                Section(L10n.AddOperation.sectionAmount) {
                    HStack {
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .amount)
                        Text("AZN")
                            .foregroundStyle(.secondary)
                    }
                }
                .listRowBackground(Color(uiColor: .secondarySystemBackground))

                Section(L10n.AddOperation.sectionDate) {
                    DatePicker(
                        L10n.AddOperation.dateLabel,
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                .listRowBackground(Color(uiColor: .secondarySystemBackground))

                if kind == .expense {
                    Section(L10n.AddOperation.behaviorSection) {
                        Toggle(L10n.AddOperation.impulsePurchase, isOn: $isImpulse)
                            .tint(.orange)
                        Text(L10n.AddOperation.impulseHint)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(Color(uiColor: .secondarySystemBackground))
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                    .listRowBackground(Color(uiColor: .secondarySystemBackground))
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background { DashboardBackground() }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(editing == nil ? L10n.AddOperation.titleNew : L10n.AddOperation.titleEdit)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                        .disabled(isImportingReceipt)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? L10n.Common.saving : L10n.Common.save) {
                        Task { await save() }
                    }
                    .disabled(!canSave)
                }
            }
            .fullScreenCover(isPresented: $isPresentingReceiptScanner) {
                ReceiptDocumentScanner(
                    onScan: { capturedReceipt = $0 },
                    onFailure: { receiptError = L10n.AddOperation.receiptFailed }
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $isPresentingReceiptReview, onDismiss: finishReceiptReview) {
                ReceiptReviewView(
                    drafts: receiptDrafts,
                    categories: availableCategories,
                    fundingSources: availableFundingSources,
                    initialFundingSource: trimmedFundingSource,
                    priceHistory: ReceiptPriceInsights(transactions: existingTransactions)
                ) { items, selectedFundingSource in
                    let transactions = makeReceiptTransactions(items, fundingSource: selectedFundingSource)
                    try await addTransaction.execute(transactions)
                    transactions.forEach(onSaved)
                    fundingSource = selectedFundingSource
                    didSaveReceipt = true
                }
            }
            .alert(
                L10n.AddOperation.receiptErrorTitle,
                isPresented: Binding(
                    get: { receiptError != nil },
                    set: { if !$0 { receiptError = nil } }
                )
            ) {
                Button(L10n.AddOperation.receiptErrorOK, role: .cancel) {}
            } message: {
                Text(receiptError ?? "")
            }
            .task(id: capturedReceipt?.id) {
                guard let capturedReceipt else { return }
                await importReceipt(capturedReceipt)
            }
            .task(id: classification.merchantText) {
                let previousSuggestion = classification.suggestion
                await classification.refreshSuggestion()
                guard !hasUserSelectedCategory else { return }
                if let suggestion = classification.suggestion {
                    kind = suggestion.category.kind
                    category = suggestion.category.localized
                    categoryIcon = suggestion.category.icon
                    categoryColor = CategoryColor.defaultColor(for: suggestion.category.kind)
                } else if let previousSuggestion, category == previousSuggestion.category.localized {
                    category = ""
                    categoryIcon = CategoryIcon.fallback
                    categoryColor = CategoryColor.defaultColor(for: kind)
                }
            }
            .interactiveDismissDisabled(isSaving || isImportingReceipt)
        }
    }

    private var receiptSection: some View {
        Section(L10n.AddOperation.receiptSection) {
            Button {
                Task { await openReceiptScanner() }
            } label: {
                HStack(spacing: 10) {
                    if isImportingReceipt {
                        ProgressView()
                        Text(L10n.AddOperation.receiptProcessing)
                    } else {
                        Label(L10n.AddOperation.receiptScan, systemImage: "camera.viewfinder")
                    }
                    Spacer()
                }
            }
            .disabled(isImportingReceipt)
        }
        .listRowBackground(Color(uiColor: .secondarySystemBackground))
    }

    private func openReceiptScanner() async {
        guard !isImportingReceipt else { return }
        focusedField = nil
        receiptError = nil
        didSaveReceipt = false

        guard ReceiptDocumentScanner.isSupported else {
            receiptError = L10n.AddOperation.receiptCameraUnavailable
            return
        }
        guard await ReceiptDocumentScanner.requestCameraAccess() else {
            receiptError = L10n.AddOperation.receiptCameraDenied
            return
        }
        guard !Task.isCancelled else { return }
        isPresentingReceiptScanner = true
    }

    private func importReceipt(_ receipt: CapturedReceipt) async {
        guard !isImportingReceipt else { return }
        isImportingReceipt = true
        receiptError = nil
        defer {
            isImportingReceipt = false
            capturedReceipt = nil
        }

        do {
            receiptDrafts = try await receiptImporter.expenses(from: receipt.images)
            isPresentingReceiptReview = true
        } catch is CancellationError {
            return
        } catch ReceiptImportError.noLineItems {
            receiptError = L10n.AddOperation.receiptNoItems
        } catch {
            receiptError = L10n.AddOperation.receiptFailed
        }
    }

    private func makeReceiptTransactions(
        _ items: [ReviewedReceiptItem],
        fundingSource: String
    ) -> [Transaction] {
        let receiptID = UUID()
        return items.map { item in
            let receiptItem = ReceiptItem(
                receiptID: receiptID,
                name: item.name,
                quantity: item.quantity,
                unitPrice: item.unitPrice
            )
            return Transaction(
                amount: receiptItem.total,
                kind: .expense,
                category: item.categoryName,
                categoryIcon: item.categoryIcon,
                categoryColor: item.categoryColor,
                fundingSource: fundingSource,
                date: date,
                note: item.name,
                receiptItem: receiptItem
            )
        }
    }

    private func finishReceiptReview() {
        receiptDrafts = []
        guard didSaveReceipt else { return }
        didSaveReceipt = false
        dismiss()
    }

    private var fundingSourceSection: some View {
        Section {
            NavigationLink {
                CategorySelectionView(
                    kind: .income,
                    categories: availableFundingSources,
                    selectedCategory: fundingSource,
                    navigationTitle: L10n.AddOperation.selectFundingSource,
                    addCategory: addCategory,
                    updateCategory: updateCategory,
                    onSelect: { selected in
                        fundingSource = selected.name
                        focusedField = .amount
                    },
                    onCategorySaved: onCategorySaved
                )
            } label: {
                Label(
                    fundingSource.isEmpty ? L10n.AddOperation.selectFundingSource : fundingSource,
                    systemImage: fundingSourceIcon
                )
            }
        } header: {
            Text(L10n.AddOperation.sectionFundingSource)
        } footer: {
            Text(L10n.AddOperation.fundingSourceHint)
        }
        .listRowBackground(Color(uiColor: .secondarySystemBackground))
    }

    private var quickAddSection: some View {
        Section(L10n.AddOperation.magicSection) {
            HStack(alignment: .top, spacing: 10) {
                TextField(L10n.AddOperation.magicPlaceholder, text: $magicText, axis: .vertical)
                    .lineLimit(1...3)
                    .focused($focusedField, equals: .magic)
                    .submitLabel(.go)
                    .onSubmit { Task { await parseMagicText() } }

                Button {
                    Task { await parseMagicText() }
                } label: {
                    if isParsing {
                        ProgressView()
                    } else {
                        Image(systemName: "sparkles")
                            .font(.headline)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
                .disabled(trimmedMagicText.isEmpty || isParsing)
                .accessibilityLabel(L10n.AddOperation.magicButton)
            }

            if let magicError {
                Text(magicError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .listRowBackground(Color(uiColor: .secondarySystemBackground))
    }

    private func parseMagicText() async {
        guard let parseNaturalInput, !trimmedMagicText.isEmpty, !isParsing else { return }
        isParsing = true
        magicError = nil
        focusedField = nil
        defer { isParsing = false }

        do {
            apply(try await parseNaturalInput.execute(trimmedMagicText))
        } catch {
            magicError = L10n.AddOperation.magicFailed
        }
    }

    /// Fill the form from a parsed draft so the user can review before saving.
    private func apply(_ draft: ParsedTransactionDraft) {
        kind = draft.kind
        category = draft.category
        amountText = "\(draft.amount)"
        classificationViewModel.merchantText = draft.note ?? ""
        hasUserSelectedCategory = false
        categoryIcon = categories.first {
            $0.kind == draft.kind && $0.name.caseInsensitiveCompare(draft.category) == .orderedSame
        }?.icon ?? CategoryIcon.suggested(for: draft.category, kind: draft.kind)
        categoryColor = categories.first {
            $0.kind == draft.kind && $0.name.caseInsensitiveCompare(draft.category) == .orderedSame
        }?.color ?? CategoryColor.defaultColor(for: draft.kind)
        focusedField = draft.category.isEmpty ? nil : .amount
    }

    private func save() async {
        guard let amount, canSave else { return }
        isSaving = true
        errorMessage = nil
        let merchant = classificationViewModel.merchantText
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let transactionNote: String?
        if let receiptItem = editing?.receiptItem {
            transactionNote = merchant.isEmpty ? receiptItem.name : merchant
        } else {
            transactionNote = merchant.isEmpty ? nil : merchant
        }
        let updatedReceiptItem = editing?.receiptItem.map {
            ReceiptItem(
                receiptID: $0.receiptID,
                name: transactionNote ?? $0.name,
                quantity: $0.quantity,
                unitPrice: amount / $0.quantity
            )
        }

        let transaction = Transaction(
            id: editing?.id ?? UUID(),
            amount: amount,
            kind: kind,
            category: trimmedCategory,
            categoryIcon: categoryIcon,
            categoryColor: categoryColor,
            fundingSource: trimmedFundingSource,
            date: date,
            note: transactionNote,
            isImpulse: kind == .expense && isImpulse,
            receiptItem: updatedReceiptItem
        )

        do {
            if editing == nil {
                try await addTransaction.execute(transaction)
            } else {
                try await updateTransaction.execute(transaction)
            }
            onSaved(transaction)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
        }
    }

    private func selectKind(_ newKind: TransactionKind) {
        guard kind != newKind else { return }
        kind = newKind
        category = ""
        categoryIcon = CategoryIcon.suggested(for: "", kind: newKind)
        categoryColor = CategoryColor.defaultColor(for: newKind)
        hasUserSelectedCategory = false
        if newKind == .income {
            isImpulse = false
        }
    }
}

private struct ReviewedReceiptItem: Sendable {
    let name: String
    let quantity: Decimal
    let unitPrice: Decimal
    let categoryName: String
    let categoryIcon: String
    let categoryColor: CategoryColor
}

private struct ReceiptReviewItemState: Identifiable {
    let id = UUID()
    var name: String
    var quantityText: String
    var unitPriceText: String
    var categoryName: String
    var categoryIcon: String
    var categoryColor: CategoryColor

    init(draft: ReceiptExpenseDraft, categories: [OperationCategorySuggestion]) {
        let suggestedName = draft.category.localized
        let category = categories.first {
            $0.name.caseInsensitiveCompare(suggestedName) == .orderedSame
        } ?? OperationCategorySuggestion(
            name: suggestedName,
            icon: draft.category.icon,
            color: CategoryColor.defaultColor(for: .expense)
        )
        name = draft.name
        quantityText = Self.text(draft.quantity)
        unitPriceText = Self.text(draft.unitPrice)
        categoryName = category.name
        categoryIcon = category.icon
        categoryColor = category.color
    }

    init(category: OperationCategorySuggestion) {
        name = ""
        quantityText = "1"
        unitPriceText = ""
        categoryName = category.name
        categoryIcon = category.icon
        categoryColor = category.color
    }

    var quantity: Decimal? { Self.decimal(quantityText) }
    var unitPrice: Decimal? { Self.decimal(unitPriceText) }

    var total: Decimal? {
        guard let quantity, let unitPrice else { return nil }
        return quantity * unitPrice
    }

    var reviewed: ReviewedReceiptItem? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty,
              trimmedName.count <= 80,
              let quantity,
              let unitPrice,
              !categoryName.isEmpty
        else { return nil }
        return ReviewedReceiptItem(
            name: trimmedName,
            quantity: quantity,
            unitPrice: unitPrice,
            categoryName: categoryName,
            categoryIcon: categoryIcon,
            categoryColor: categoryColor
        )
    }

    private static func decimal(_ text: String) -> Decimal? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")), value > 0 else {
            return nil
        }
        return value
    }

    private static func text(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }
}

private struct ReceiptReviewView: View {
    private let categories: [OperationCategorySuggestion]
    private let fundingSources: [OperationCategorySuggestion]
    private let priceHistory: ReceiptPriceInsights
    private let onSave: @MainActor ([ReviewedReceiptItem], String) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var items: [ReceiptReviewItemState]
    @State private var selectedFundingSource: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        drafts: [ReceiptExpenseDraft],
        categories: [OperationCategorySuggestion],
        fundingSources: [OperationCategorySuggestion],
        initialFundingSource: String,
        priceHistory: ReceiptPriceInsights,
        onSave: @escaping @MainActor ([ReviewedReceiptItem], String) async throws -> Void
    ) {
        var options = categories
        for draft in drafts {
            let name = draft.category.localized
            if !options.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
                options.append(OperationCategorySuggestion(
                    name: name,
                    icon: draft.category.icon,
                    color: CategoryColor.defaultColor(for: .expense)
                ))
            }
        }
        let otherName = ClassifiedTransactionCategory.other.localized
        if !options.contains(where: { $0.name.caseInsensitiveCompare(otherName) == .orderedSame }) {
            options.append(OperationCategorySuggestion(
                name: otherName,
                icon: ClassifiedTransactionCategory.other.icon,
                color: CategoryColor.defaultColor(for: .expense)
            ))
        }

        self.categories = options
        self.fundingSources = fundingSources
        self.priceHistory = priceHistory
        self.onSave = onSave
        _items = State(initialValue: drafts.map { ReceiptReviewItemState(draft: $0, categories: options) })
        _selectedFundingSource = State(initialValue: initialFundingSource)
    }

    private var canSave: Bool {
        !items.isEmpty &&
            !selectedFundingSource.isEmpty &&
            items.allSatisfy { $0.reviewed != nil } &&
            !isSaving
    }

    private var total: Decimal {
        items.compactMap(\.total).reduce(Decimal.zero, +)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(L10n.ReceiptReview.instructions)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section(L10n.AddOperation.sectionFundingSource) {
                    Picker(L10n.AddOperation.selectFundingSource, selection: $selectedFundingSource) {
                        Text(L10n.AddOperation.selectFundingSource).tag("")
                        ForEach(fundingSources) { source in
                            Label(source.name, systemImage: source.icon).tag(source.name)
                        }
                    }
                }

                ForEach($items) { $item in
                    Section {
                        TextField(L10n.ReceiptReview.itemName, text: $item.name)

                        HStack {
                            TextField(L10n.ReceiptReview.quantity, text: $item.quantityText)
                                .keyboardType(.decimalPad)
                            Divider()
                            TextField(L10n.ReceiptReview.unitPrice, text: $item.unitPriceText)
                                .keyboardType(.decimalPad)
                            Text(CurrencySettings.symbol(for: CurrencySettings.selectedCode))
                                .foregroundStyle(.secondary)
                        }

                        Menu {
                            ForEach(categories) { category in
                                Button {
                                    item.categoryName = category.name
                                    item.categoryIcon = category.icon
                                    item.categoryColor = category.color
                                } label: {
                                    Label(category.name, systemImage: category.icon)
                                }
                            }
                        } label: {
                            LabeledContent(L10n.ReceiptReview.category) {
                                Label(item.categoryName, systemImage: item.categoryIcon)
                            }
                        }

                        if let total = item.total {
                            LabeledContent(
                                L10n.ReceiptReview.lineTotal,
                                value: OperationFormatting.plain(total)
                            )
                        }

                        if let unitPrice = item.unitPrice,
                           let comparison = priceHistory.comparison(for: item.name, currentUnitPrice: unitPrice)
                        {
                            Text(comparison.shouldVerify
                                ? L10n.ReceiptReview.verifyPrice(
                                    OperationFormatting.plain(comparison.previousUnitPrice),
                                    comparison.percent
                                )
                                : L10n.ReceiptReview.previousPrice(
                                    OperationFormatting.plain(comparison.previousUnitPrice)
                                ))
                            .font(.caption)
                            .foregroundStyle(comparison.shouldVerify ? .orange : .secondary)
                        }

                        Button(L10n.ReceiptReview.removeItem, systemImage: "trash", role: .destructive) {
                            items.removeAll { $0.id == item.id }
                        }
                    }
                }

                Section {
                    Button(L10n.ReceiptReview.addItem, systemImage: "plus.circle") {
                        guard let category = categories.first(where: {
                            $0.name.caseInsensitiveCompare(ClassifiedTransactionCategory.other.localized) == .orderedSame
                        }) ?? categories.first else { return }
                        items.append(ReceiptReviewItemState(category: category))
                    }

                    LabeledContent(L10n.ReceiptReview.receiptTotal) {
                        Text(OperationFormatting.plain(total))
                            .fontWeight(.semibold)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(L10n.ReceiptReview.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? L10n.Common.saving : L10n.ReceiptReview.save) {
                        Task { await save() }
                    }
                    .disabled(!canSave)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }

    private func save() async {
        let reviewed = items.compactMap(\.reviewed)
        guard reviewed.count == items.count, canSave else { return }
        isSaving = true
        errorMessage = nil
        do {
            try await onSave(reviewed, selectedFundingSource)
            dismiss()
        } catch {
            errorMessage = L10n.ReceiptReview.saveFailed
            isSaving = false
        }
    }
}

private struct OperationCategorySuggestion: Identifiable {
    let name: String
    let icon: String
    let color: CategoryColor
    var savedCategory: TransactionCategory? = nil

    var id: String { name.lowercased() }
}

private struct CategorySelectionView: View {
    let kind: TransactionKind
    let categories: [OperationCategorySuggestion]
    let selectedCategory: String
    let navigationTitle: String
    let addCategory: AddTransactionCategoryUseCase
    let updateCategory: UpdateTransactionCategoryUseCase
    let onSelect: (TransactionCategory) -> Void
    let onCategorySaved: (TransactionCategory) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editorDestination: CategoryEditorDestination?
    @State private var createdCategory: TransactionCategory?

    var body: some View {
        List {
            Section {
                ForEach(categories) { category in
                    HStack(spacing: 8) {
                        Button {
                            select(category.savedCategory ?? TransactionCategory(
                                name: category.name,
                                kind: kind,
                                icon: category.icon,
                                color: category.color
                            ))
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: category.icon)
                                    .foregroundStyle(category.color.displayColor)
                                    .frame(width: 28)
                                Text(category.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if category.name.caseInsensitiveCompare(selectedCategory) == .orderedSame {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(
                            category.name.caseInsensitiveCompare(selectedCategory) == .orderedSame ? .isSelected : []
                        )

                        if let savedCategory = category.savedCategory {
                            Button {
                                editorDestination = .edit(savedCategory)
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 36, height: 36)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(L10n.NewCategory.editAction(category.name))
                        }
                    }
                }
            }

            Section {
                Button {
                    editorDestination = .new
                } label: {
                    Label(L10n.AddOperation.createCategory, systemImage: "plus.circle.fill")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background { DashboardBackground() }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editorDestination, onDismiss: selectCreatedCategory) { destination in
            switch destination {
            case .new:
                NewCategoryView(kind: kind, addCategory: addCategory) { category in
                    createdCategory = category
                    onCategorySaved(category)
                }
            case .edit(let category):
                NewCategoryView(
                    updateCategory: updateCategory,
                    editing: category,
                    onSaved: onCategorySaved
                )
            }
        }
    }

    private func select(_ category: TransactionCategory) {
        onSelect(category)
        dismiss()
    }

    private func selectCreatedCategory() {
        guard let createdCategory else { return }
        select(createdCategory)
    }
}

private enum CategoryEditorDestination: Identifiable {
    case new
    case edit(TransactionCategory)

    var id: String {
        switch self {
        case .new: "new"
        case .edit(let category): category.id.uuidString
        }
    }
}

private enum Field {
    case magic
    case amount
}

private enum OperationsFilter: CaseIterable {
    case all
    case expenses
    case income

    var title: String {
        switch self {
        case .all: L10n.Operations.filterAll
        case .expenses: L10n.Operations.filterExpenses
        case .income: L10n.Operations.filterIncome
        }
    }

    func matches(_ transaction: Transaction) -> Bool {
        switch self {
        case .all: true
        case .expenses: transaction.kind == .expense
        case .income: transaction.kind == .income
        }
    }
}

private enum OperationsPresentation: CaseIterable {
    case daily
    case calendar
    case monthly

    var title: String {
        switch self {
        case .daily: L10n.Operations.presentationDaily
        case .calendar: L10n.Operations.presentationCalendar
        case .monthly: L10n.Operations.presentationMonthly
        }
    }

    var systemImage: String {
        switch self {
        case .daily: "list.bullet"
        case .calendar: "calendar"
        case .monthly: "chart.bar.xaxis"
        }
    }
}

private struct OperationDaySection: Identifiable {
    let date: Date
    let transactions: [Transaction]
    let totalExpenses: Decimal
    let totalIncome: Decimal

    var id: Date { date }

    var title: String {
        if Calendar.current.isDateInToday(date) {
            return L10n.Operations.today
        }
        if Calendar.current.isDateInYesterday(date) {
            return L10n.Operations.yesterday
        }
        return date.formatted(
            .dateTime
                .day()
                .month(.wide)
                .year()
                .locale(Locale(identifier: LocalizationManager.shared.currentLanguage))
        )
    }
}

enum OperationFormatting {
    static func amount(_ amount: Decimal, sign kind: TransactionKind) -> String {
        kind == .income ? "+\(plain(amount))" : plain(amount)
    }

    /// Amount with currency and no forced sign, e.g. "4 280 ₼"; negative values keep the typographic minus.
    static func plain(_ amount: Decimal) -> String {
        let number = amountFormatter(for: LocalizationManager.shared.currentLanguage)
            .string(from: NSDecimalNumber(decimal: amount)) ?? amount.description
        return "\(number) \(CurrencySettings.symbol(for: CurrencySettings.selectedCode))"
    }

    private static let russianAmountFormatter = makeAmountFormatter(locale: "ru_RU")
    private static let englishAmountFormatter = makeAmountFormatter(locale: "en_US")

    private static func amountFormatter(for language: String) -> NumberFormatter {
        language == "en" ? englishAmountFormatter : russianAmountFormatter
    }

    private static func makeAmountFormatter(locale: String) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: locale)
        formatter.minusSign = "−"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }
}

extension TransactionKind {
    var title: String {
        switch self {
        case .income: L10n.Common.income
        case .expense: L10n.Common.expense
        }
    }
}

#Preview("Пустая история") {
    let container = AppContainer(isStoredInMemoryOnly: true)
    OperationsView(
        fetchTransactions: container.makeFetchTransactionsUseCase(),
        fetchCategories: container.makeFetchTransactionCategoriesUseCase(),
        fetchSubscriptions: container.makeFetchSubscriptionsUseCase(),
        fetchBudgets: container.makeFetchBudgetsUseCase(),
        fetchGoals: container.makeFetchSavingsGoalsUseCase(),
        addCategory: container.makeAddTransactionCategoryUseCase(),
        updateCategory: container.makeUpdateTransactionCategoryUseCase(),
        addTransaction: container.makeAddTransactionUseCase(),
        saveGoals: container.makeSaveSavingsGoalUseCase(),
        updateTransaction: container.makeUpdateTransactionUseCase(),
        deleteTransaction: container.makeDeleteTransactionUseCase(),
        parseNaturalInput: container.makeParseNaturalInputUseCase(),
        transactionClassifier: container.transactionClassifier
    )
}
