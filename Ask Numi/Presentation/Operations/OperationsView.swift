//
//  OperationsView.swift
//  Ask Numi
//

import SwiftUI

struct OperationsView: View {
    let fetchTransactions: FetchTransactionsUseCase
    let addTransaction: AddTransactionUseCase
    @Binding var selectedTab: AppTab

    @State private var transactions: [Transaction] = []
    @State private var query = ""
    @State private var filter: OperationsFilter = .all
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isPresentingAddOperation = false

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
                    LazyVStack(alignment: .leading, spacing: 18) {
                        header
                        searchField
                        filters
                        content
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 104)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
            .safeAreaInset(edge: .bottom) {
                AppTabBar(selection: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isPresentingAddOperation) {
                AddOperationView(addTransaction: addTransaction) { transaction in
                    transactions.append(transaction)
                    transactions.sort { $0.date > $1.date }
                }
            }
            .task {
                await loadTransactions()
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Операции")
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
            .accessibilityLabel("Добавить операцию")
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Поиск по категории", text: $query)
                .font(.subheadline)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Очистить поиск")
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
        if isLoading && transactions.isEmpty {
            ProgressView("Загрузка операций…")
                .frame(maxWidth: .infinity)
                .padding(.top, 80)
        } else if let errorMessage, transactions.isEmpty {
            ContentUnavailableView {
                Label("Не удалось загрузить операции", systemImage: "exclamationmark.triangle")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("Повторить") {
                    Task { await loadTransactions() }
                }
            }
            .padding(.top, 48)
        } else if transactions.isEmpty {
            ContentUnavailableView {
                Label("Нет операций", systemImage: "tray")
            } description: {
                Text("Нажмите +, чтобы добавить первый расход или доход.")
            } actions: {
                Button("Добавить операцию") {
                    isPresentingAddOperation = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 48)
        } else if sections.isEmpty {
            ContentUnavailableView.search(text: query)
                .padding(.top, 48)
        } else {
            ForEach(sections) { section in
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
                        Text("Расходы \(OperationFormatting.amount(section.totalExpenses, sign: .expense))")
                            .foregroundStyle(.red)
                    }
                    if section.totalIncome > 0 {
                        Text("Доходы \(OperationFormatting.amount(section.totalIncome, sign: .income))")
                            .foregroundStyle(.green)
                    }
                }
                .font(.caption.weight(.semibold))
            }

            VStack(spacing: 0) {
                ForEach(section.transactions) { transaction in
                    OperationsRow(transaction: transaction)

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

    private func loadTransactions() async {
        isLoading = true
        defer { isLoading = false }

        do {
            transactions = try await fetchTransactions.execute()
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
            Image(systemName: transaction.kind == .income ? "arrow.down.left" : "arrow.up.right")
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
    let onSaved: (Transaction) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var kind: TransactionKind = .expense
    @State private var category = ""
    @State private var amountText = ""
    @State private var date = Date.now
    @State private var isSaving = false
    @State private var errorMessage: String?
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

    var body: some View {
        NavigationStack {
            Form {
                Section("Тип операции") {
                    Picker("Тип операции", selection: $kind) {
                        ForEach(TransactionKind.allCases, id: \.self) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(kind == .expense ? .red : .green)
                }

                Section("Категория") {
                    TextField("Например: Продукты, Bolt или зарплата", text: $category)
                        .focused($focusedField, equals: .category)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .amount }

                    if category.count > 60 {
                        Text("Название должно быть не длиннее 60 символов.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Сумма") {
                    HStack {
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .amount)
                        Text("AZN")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Дата операции") {
                    DatePicker(
                        "Дата и время",
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
            .navigationTitle("Новая операция")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Сохранение…" : "Сохранить") {
                        Task { await save() }
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear { focusedField = .category }
        }
    }

    private func save() async {
        guard let amount, canSave else { return }
        isSaving = true
        errorMessage = nil

        let transaction = Transaction(
            amount: amount,
            kind: kind,
            category: trimmedCategory,
            date: date
        )

        do {
            try await addTransaction.execute(transaction)
            onSaved(transaction)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
        }
    }
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
        case .all: "Все"
        case .expenses: "Расходы"
        case .income: "Доходы"
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
            return "Сегодня"
        }
        if Calendar.current.isDateInYesterday(date) {
            return "Вчера"
        }
        return date.formatted(
            .dateTime
                .day()
                .month(.wide)
                .year()
                .locale(Locale(identifier: "ru_RU"))
        )
    }
}

private enum OperationFormatting {
    static func amount(_ amount: Decimal, sign kind: TransactionKind) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2

        let number = formatter.string(from: NSDecimalNumber(decimal: amount)) ?? amount.description
        return "\(kind == .income ? "+" : "−")\(number) AZN"
    }
}

private extension TransactionKind {
    var title: String {
        switch self {
        case .income: "Доход"
        case .expense: "Расход"
        }
    }
}

#Preview("Пустая история") {
    let container = AppContainer(isStoredInMemoryOnly: true)
    OperationsView(
        fetchTransactions: container.makeFetchTransactionsUseCase(),
        addTransaction: container.makeAddTransactionUseCase(),
        selectedTab: .constant(.operations)
    )
}
