//
//  OperationsView.swift
//  Ask Numi
//

import SwiftUI

struct OperationsView: View {
    let fetchTransactions: FetchTransactionsUseCase
    let fetchCategories: FetchTransactionCategoriesUseCase
    let addCategory: AddTransactionCategoryUseCase
    let addTransaction: AddTransactionUseCase
    let updateTransaction: UpdateTransactionUseCase
    let deleteTransaction: DeleteTransactionUseCase
    @Binding var selectedTab: AppTab

    @State private var transactions: [Transaction] = []
    @State private var categories: [TransactionCategory] = []
    @State private var query = ""
    @State private var filter: OperationsFilter = .all
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isPresentingAddOperation = false
    @State private var editingTransaction: Transaction?
    @State private var deleteErrorMessage: String?

    private var sections: [OperationDaySection] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions) { calendar.startOfDay(for: $0.date) }

        return grouped.keys.sorted(by: >).compactMap { date in
            guard let transactions = grouped[date] else { return nil }
            let visibleTransactions = transactions.filter { transaction in
                filter.matches(transaction) &&
                    (query.isEmpty || transaction.category.localizedCaseInsensitiveContains(query))
            }
            guard !visibleTransactions.isEmpty else { return nil }

            return OperationDaySection(
                date: date,
                transactions: visibleTransactions.sorted { $0.date > $1.date },
                totalExpenses: total(for: transactions, kind: .expense),
                totalIncome: total(for: transactions, kind: .income)
            )
        }
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
                        .padding(.bottom, 104)
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
            .safeAreaInset(edge: .bottom) {
                AppTabBar(selection: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isPresentingAddOperation) {
                AddOperationView(
                    addTransaction: addTransaction,
                    updateTransaction: updateTransaction,
                    existingTransactions: transactions,
                    categories: categories,
                    addCategory: addCategory
                ) { transaction in
                    transactions.append(transaction)
                    transactions.sort { $0.date > $1.date }
                } onCategorySaved: { category in
                    categories.append(category)
                }
            }
            .sheet(item: $editingTransaction) { transaction in
                AddOperationView(
                    addTransaction: addTransaction,
                    updateTransaction: updateTransaction,
                    existingTransactions: transactions,
                    categories: categories,
                    addCategory: addCategory,
                    editing: transaction
                ) { updated in
                    if let index = transactions.firstIndex(where: { $0.id == updated.id }) {
                        transactions[index] = updated
                        transactions.sort { $0.date > $1.date }
                    }
                } onCategorySaved: { category in
                    categories.append(category)
                }
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
                    .glassEffect(.regular.tint(.indigo).interactive(), in: .circle)
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
                Button(item.title) {
                    filter = item
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(filter == item ? .white : .primary)
                .padding(.horizontal, 16)
                .frame(height: 34)
                .glassEffect(.regular.tint(filter == item ? .indigo : .clear).interactive(), in: .capsule)
                .accessibilityAddTraits(filter == item ? .isSelected : [])
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var content: some View {
        let visibleSections = sections

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
        } else if visibleSections.isEmpty {
            ContentUnavailableView.search(text: query)
                .padding(.top, 48)
        } else {
            ForEach(visibleSections) { section in
                transactionSection(section)
            }
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
}

private struct OperationsRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.categoryIcon)
                .font(.body.weight(.semibold))
                .foregroundStyle(transaction.kind == .income ? .green : .red)
                .frame(width: 42, height: 42)
                .background(
                    (transaction.kind == .income ? Color.green : .red).opacity(0.14),
                    in: .rect(cornerRadius: 13)
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
                    .foregroundStyle(transaction.kind == .income ? .green : .primary)
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
    let editing: Transaction?
    let onSaved: (Transaction) -> Void
    let onCategorySaved: (TransactionCategory) -> Void

    init(
        addTransaction: AddTransactionUseCase,
        updateTransaction: UpdateTransactionUseCase,
        existingTransactions: [Transaction],
        categories: [TransactionCategory],
        addCategory: AddTransactionCategoryUseCase,
        editing: Transaction? = nil,
        onSaved: @escaping (Transaction) -> Void,
        onCategorySaved: @escaping (TransactionCategory) -> Void
    ) {
        self.addTransaction = addTransaction
        self.updateTransaction = updateTransaction
        self.existingTransactions = existingTransactions
        self.categories = categories
        self.addCategory = addCategory
        self.editing = editing
        self.onSaved = onSaved
        self.onCategorySaved = onCategorySaved

        if let editing {
            _kind = State(initialValue: editing.kind)
            _category = State(initialValue: editing.category)
            _categoryIcon = State(initialValue: editing.categoryIcon)
            _amountText = State(initialValue: "\(editing.amount)")
            _date = State(initialValue: editing.date)
        }
    }

    private static let defaultCategories: [TransactionKind: [String]] = [
        .expense: L10n.AddOperation.defaultExpenseCategories,
        .income: L10n.AddOperation.defaultIncomeCategories
    ]

    @Environment(\.dismiss) private var dismiss
    @State private var kind: TransactionKind = .expense
    @State private var category = ""
    @State private var categoryIcon = CategoryIcon.fallback
    @State private var amountText = ""
    @State private var date = Date.now
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var isPresentingNewCategory = false
    @FocusState private var focusedField: Field?

    private var trimmedCategory: String {
        category.trimmingCharacters(in: .whitespacesAndNewlines)
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
        !trimmedCategory.isEmpty && trimmedCategory.count <= 60 && amount != nil && !isSaving
    }

    // Saved categories for the selected kind, most recent first, then defaults; deduped case-insensitively.
    private var suggestedCategories: [OperationCategorySuggestion] {
        let savedCategories = categories
            .filter { $0.kind == kind }
            .map { OperationCategorySuggestion(name: $0.name, icon: $0.icon) }
        let savedTransactions = existingTransactions
            .filter { $0.kind == kind }
            .sorted { $0.date > $1.date }
            .map { OperationCategorySuggestion(name: $0.category, icon: $0.categoryIcon) }
        let defaults = (Self.defaultCategories[kind] ?? []).map {
            OperationCategorySuggestion(name: $0, icon: CategoryIcon.suggested(for: $0, kind: kind))
        }

        var seen = Set<String>()
        return (savedCategories + savedTransactions + defaults)
            .filter { seen.insert($0.name.lowercased()).inserted }
            .filter {
                trimmedCategory.isEmpty ||
                    ($0.name.localizedCaseInsensitiveContains(trimmedCategory) &&
                        $0.name.caseInsensitiveCompare(trimmedCategory) != .orderedSame)
            }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.AddOperation.sectionKind) {
                    Picker(L10n.AddOperation.sectionKind, selection: $kind) {
                        ForEach(TransactionKind.allCases, id: \.self) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(kind == .expense ? .red : .green)
                }

                Section(L10n.AddOperation.sectionCategory) {
                    TextField(L10n.AddOperation.categoryPlaceholder, text: $category)
                        .focused($focusedField, equals: .category)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .amount }
                        .onChange(of: category) { _, value in
                            categoryIcon = categories.first {
                                $0.kind == kind && $0.name.caseInsensitiveCompare(value) == .orderedSame
                            }?.icon ?? CategoryIcon.suggested(for: value, kind: kind)
                        }

                    if category.count > 60 {
                        Text(L10n.AddOperation.categoryTooLong)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    if !suggestedCategories.isEmpty {
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                ForEach(suggestedCategories) { suggestion in
                                    Button {
                                        category = suggestion.name
                                        categoryIcon = suggestion.icon
                                        focusedField = .amount
                                    } label: {
                                        Label(suggestion.name, systemImage: suggestion.icon)
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
                        .scrollIndicators(.hidden)
                    }

                    Button {
                        isPresentingNewCategory = true
                    } label: {
                        Label(L10n.AddOperation.createCategory, systemImage: "plus.circle.fill")
                    }
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

                Section(L10n.AddOperation.sectionDate) {
                    DatePicker(
                        L10n.AddOperation.dateLabel,
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
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
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? L10n.Common.saving : L10n.Common.save) {
                        Task { await save() }
                    }
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $isPresentingNewCategory) {
                NewCategoryView(kind: kind, addCategory: addCategory) { newCategory in
                    onCategorySaved(newCategory)
                    kind = newCategory.kind
                    category = newCategory.name
                    categoryIcon = newCategory.icon
                    focusedField = .amount
                }
            }
            .onChange(of: kind) {
                categoryIcon = categories.first {
                    $0.kind == kind && $0.name.caseInsensitiveCompare(category) == .orderedSame
                }?.icon ?? CategoryIcon.suggested(for: category, kind: kind)
            }
            .onAppear { focusedField = .category }
        }
    }

    private func save() async {
        guard let amount, canSave else { return }
        isSaving = true
        errorMessage = nil

        let transaction = Transaction(
            id: editing?.id ?? UUID(),
            amount: amount,
            kind: kind,
            category: trimmedCategory,
            categoryIcon: categoryIcon,
            date: date,
            note: editing?.note
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
}

private struct OperationCategorySuggestion: Identifiable {
    let name: String
    let icon: String

    var id: String { name.lowercased() }
}

private enum Field {
    case category
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
        "\(kind == .income ? "+" : "−")\(plain(amount))"
    }

    /// Amount with currency and no forced sign, e.g. "4 280 AZN"; negative values keep the typographic minus.
    static func plain(_ amount: Decimal) -> String {
        let number = amountFormatter(for: LocalizationManager.shared.currentLanguage)
            .string(from: NSDecimalNumber(decimal: amount)) ?? amount.description
        return "\(number) \(CurrencySettings.selectedCode)"
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
        addCategory: container.makeAddTransactionCategoryUseCase(),
        addTransaction: container.makeAddTransactionUseCase(),
        updateTransaction: container.makeUpdateTransactionUseCase(),
        deleteTransaction: container.makeDeleteTransactionUseCase(),
        selectedTab: .constant(.operations)
    )
}
