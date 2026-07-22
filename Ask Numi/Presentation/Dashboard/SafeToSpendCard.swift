//
//  SafeToSpendCard.swift
//  Ask Numi
//

import SwiftUI

struct SafeToSpendCard: View {
    let subscriptions: [Subscription]
    let goals: [SavingsGoal]
    let isLoading: Bool
    let hasCommitmentData: Bool

    @Environment(\.calendar) private var calendar
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("safeToSpend.currentBalance") private var balanceText = ""
    @AppStorage("safeToSpend.expectedIncome") private var incomeText = ""
    @AppStorage("safeToSpend.reserve") private var reserveText = ""
    @AppStorage("safeToSpend.payday") private var paydayTimestamp = 0.0
    @State private var now = Date.now
    @State private var isEditing = false

    private var result: SafeToSpendResult {
        CalculateSafeToSpendUseCase().execute(
            currentBalance: Self.amount(balanceText),
            expectedIncome: Self.amount(incomeText),
            reserve: Self.amount(reserveText),
            payday: paydayTimestamp > 0 ? Date(timeIntervalSince1970: paydayTimestamp) : nil,
            subscriptions: hasCommitmentData ? subscriptions : nil,
            goals: hasCommitmentData ? goals : nil,
            asOf: now,
            calendar: calendar
        )
    }

    var body: some View {
        Button { isEditing = true } label: {
            GlassCard(tint: DashboardPalette.income.opacity(0.14)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label(L10n.SafeToSpend.title, systemImage: "calendar.badge.checkmark")
                            .font(.headline)
                            .foregroundStyle(DashboardPalette.income)
                        Spacer()
                        Image(systemName: "slider.horizontal.3")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }

                    if let perDay = result.perDay, let payday = result.payday {
                        Text(L10n.SafeToSpend.perDay(OperationFormatting.plain(perDay)))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)
                            .contentTransition(.numericText())

                        Text(L10n.SafeToSpend.summary(
                            OperationFormatting.plain(perDay),
                            payday.formatted(
                                .dateTime.day().month(.wide)
                                    .locale(Locale(identifier: LocalizationManager.shared.currentLanguage))
                            )
                        ))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                        Text(L10n.SafeToSpend.evidence(
                            OperationFormatting.plain(Self.amount(balanceText) ?? 0),
                            OperationFormatting.plain(Self.amount(incomeText) ?? 0),
                            OperationFormatting.plain(result.scheduledPayments),
                            OperationFormatting.plain(Self.amount(reserveText) ?? 0),
                            OperationFormatting.plain(result.protectedGoals)
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(L10n.SafeToSpend.missing(
                            result.missingInputs.map { L10n.SafeToSpend.missingInput($0) }.joined(separator: ", ")
                        ))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .redacted(reason: isLoading ? .placeholder : [])
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .sheet(isPresented: $isEditing) {
            SafeToSpendEditor(
                balanceText: $balanceText,
                incomeText: $incomeText,
                reserveText: $reserveText,
                paydayTimestamp: $paydayTimestamp
            )
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { now = .now }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            now = .now
        }
    }

    fileprivate static func amount(_ text: String) -> Decimal? {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let value = Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")), value >= 0 else {
            return nil
        }
        return value
    }
}

private struct SafeToSpendEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var balanceText: String
    @Binding var incomeText: String
    @Binding var reserveText: String
    @Binding var paydayTimestamp: Double
    @State private var draftBalance: String
    @State private var draftIncome: String
    @State private var draftReserve: String
    @State private var draftPayday: Date

    init(
        balanceText: Binding<String>,
        incomeText: Binding<String>,
        reserveText: Binding<String>,
        paydayTimestamp: Binding<Double>
    ) {
        _balanceText = balanceText
        _incomeText = incomeText
        _reserveText = reserveText
        _paydayTimestamp = paydayTimestamp
        _draftBalance = State(initialValue: balanceText.wrappedValue)
        _draftIncome = State(initialValue: incomeText.wrappedValue)
        _draftReserve = State(initialValue: reserveText.wrappedValue)
        let savedDate = Date(timeIntervalSince1970: paydayTimestamp.wrappedValue)
        _draftPayday = State(initialValue: paydayTimestamp.wrappedValue > 0
            ? max(savedDate, Calendar.current.startOfDay(for: .now))
            : Calendar.current.startOfDay(for: .now))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.SafeToSpend.inputSection) {
                    amountField(L10n.SafeToSpend.balance, text: $draftBalance)
                    amountField(L10n.SafeToSpend.income, text: $draftIncome)
                    amountField(L10n.SafeToSpend.reserve, text: $draftReserve)
                    DatePicker(
                        L10n.SafeToSpend.payday,
                        selection: $draftPayday,
                        in: Calendar.current.startOfDay(for: .now)...,
                        displayedComponents: .date
                    )
                }

                Section {
                    Text(L10n.SafeToSpend.method)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(L10n.SafeToSpend.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.save) {
                        balanceText = draftBalance
                        incomeText = draftIncome
                        reserveText = draftReserve
                        paydayTimestamp = Calendar.current.startOfDay(for: draftPayday).timeIntervalSince1970
                        dismiss()
                    }
                }
            }
        }
    }

    private func amountField(_ title: String, text: Binding<String>) -> some View {
        HStack {
            TextField(title, text: text)
                .keyboardType(.decimalPad)
            Text(CurrencySettings.symbol(for: CurrencySettings.selectedCode))
                .foregroundStyle(.secondary)
        }
    }
}
