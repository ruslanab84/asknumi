//
//  OperationsPeriodViews.swift
//  Ask Numi
//

import SwiftUI

struct OperationsCalendarView: View {
    @Environment(\.appAccentColor) private var accentColor
    let transactions: [Transaction]
    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private var locale: Locale {
        Locale(identifier: LocalizationManager.shared.currentLanguage)
    }

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.locale = locale
        return calendar
    }

    private var monthTitle: String {
        displayedMonth.formatted(
            .dateTime.month(.wide).year().locale(locale)
        ).capitalized(with: locale)
    }

    var body: some View {
        let days = OperationCalendarLayout.days(for: displayedMonth, calendar: calendar)
        let weekdays = OperationCalendarLayout.weekdays(calendar: calendar)
        let totalsByDay = OperationTotals.groupedByDay(transactions, calendar: calendar)
        let monthTotals = OperationTotals(
            transactions: transactions.filter { transaction in
                calendar.isDate(transaction.date, equalTo: displayedMonth, toGranularity: .month)
            }
        )

        VStack(spacing: 14) {
            monthHeader
            OperationsPeriodSummary(totals: monthTotals)

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(weekdays) { weekday in
                    Text(weekday.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                }

                ForEach(days) { day in
                    dayButton(day, totals: totalsByDay[calendar.startOfDay(for: day.date)])
                }
            }
        }
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }

    private var monthHeader: some View {
        HStack {
            Button {
                moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel(L10n.Operations.previousMonth)

            Spacer()

            Text(monthTitle)
                .font(.headline)

            Spacer()

            Button {
                moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel(L10n.Operations.nextMonth)
        }
        .buttonStyle(.plain)
    }

    private func dayButton(_ day: OperationCalendarDay, totals: OperationTotals?) -> some View {
        let isSelected = calendar.isDate(day.date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(day.date)

        return Button {
            select(day.date)
        } label: {
            VStack(spacing: 3) {
                Text(day.date.formatted(.dateTime.day().locale(locale)))
                    .font(.caption.weight(isSelected ? .bold : .medium))

                if let totals, totals.count > 0 {
                    Text(OperationFormatting.compactBalance(totals.balance))
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(balanceColor(for: totals.balance))
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                } else {
                    Text(" ")
                        .font(.caption2)
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(day.isInDisplayedMonth ? Color.primary : Color.secondary.opacity(0.55))
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                isSelected ? accentColor.opacity(0.18) : .clear,
                in: .rect(cornerRadius: 12)
            )
            .overlay {
                if isToday && !isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentColor.opacity(0.65), lineWidth: 1)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: day.date, totals: totals))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func accessibilityLabel(for date: Date, totals: OperationTotals?) -> String {
        let formattedDate = date.formatted(
            .dateTime.day().month(.wide).year().locale(locale)
        )
        guard let totals, totals.count > 0 else { return formattedDate }
        return L10n.Operations.calendarDayBalance(
            formattedDate,
            OperationFormatting.plain(totals.balance)
        )
    }

    private func moveMonth(by offset: Int) {
        guard
            let date = calendar.date(byAdding: .month, value: offset, to: displayedMonth),
            let month = calendar.dateInterval(of: .month, for: date)?.start
        else { return }

        withAnimation(.snappy) {
            displayedMonth = month
            selectedDate = month
        }
    }

    private func select(_ date: Date) {
        withAnimation(.snappy) {
            selectedDate = calendar.startOfDay(for: date)
            if !calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month) {
                displayedMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
            }
        }
    }
}

struct OperationsMonthlyView: View {
    let transactions: [Transaction]

    private var locale: Locale {
        Locale(identifier: LocalizationManager.shared.currentLanguage)
    }

    private var sections: [OperationMonthSummary] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions) { transaction in
            calendar.dateInterval(of: .month, for: transaction.date)?.start ?? transaction.date
        }

        return grouped.keys.sorted(by: >).compactMap { month in
            grouped[month].map {
                OperationMonthSummary(month: month, totals: OperationTotals(transactions: $0))
            }
        }
    }

    var body: some View {
        ForEach(sections) { section in
            VStack(alignment: .leading, spacing: 12) {
                Text(section.month.formatted(.dateTime.month(.wide).year().locale(locale)).capitalized(with: locale))
                    .font(.headline)

                OperationsPeriodSummary(totals: section.totals)
            }
            .padding(14)
            .glassEffect(.regular, in: .rect(cornerRadius: 20))
            .accessibilityElement(children: .combine)
        }
    }
}

private struct OperationsPeriodSummary: View {
    let totals: OperationTotals

    var body: some View {
        HStack(spacing: 8) {
            metric(
                title: L10n.Operations.filterIncome,
                value: OperationFormatting.amount(totals.income, sign: .income),
                color: .green
            )
            Divider().frame(height: 34)
            metric(
                title: L10n.Operations.filterExpenses,
                value: OperationFormatting.plain(totals.expenses),
                color: .red
            )
            Divider().frame(height: 34)
            metric(
                title: L10n.Operations.balance,
                value: OperationFormatting.plain(totals.balance),
                color: balanceColor(for: totals.balance)
            )
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(.primary.opacity(0.045), in: .rect(cornerRadius: 14))
    }

    private func metric(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity)
    }
}

struct OperationTotals: Equatable {
    let income: Decimal
    let expenses: Decimal
    let count: Int

    var balance: Decimal { income - expenses }

    init(transactions: [Transaction]) {
        income = transactions.lazy
            .filter { $0.kind == .income }
            .reduce(Decimal.zero) { $0 + $1.amount }
        expenses = transactions.lazy
            .filter { $0.kind == .expense }
            .reduce(Decimal.zero) { $0 + $1.amount }
        count = transactions.count
    }

    static func groupedByDay(_ transactions: [Transaction], calendar: Calendar) -> [Date: OperationTotals] {
        Dictionary(grouping: transactions) { calendar.startOfDay(for: $0.date) }
            .mapValues { OperationTotals(transactions: $0) }
    }
}

private struct OperationMonthSummary: Identifiable {
    let month: Date
    let totals: OperationTotals

    var id: Date { month }
}

struct OperationCalendarDay: Identifiable {
    let date: Date
    let isInDisplayedMonth: Bool

    var id: Date { date }
}

struct OperationCalendarWeekday: Identifiable {
    let id: Int
    let title: String
}

enum OperationCalendarLayout {
    static func days(for month: Date, calendar: Calendar) -> [OperationCalendarDay] {
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }

        let leadingDays = (
            calendar.component(.weekday, from: interval.start) - calendar.firstWeekday + 7
        ) % 7
        guard let gridStart = calendar.date(byAdding: .day, value: -leadingDays, to: interval.start) else {
            return []
        }

        let daysThroughMonthEnd = calendar.dateComponents([.day], from: gridStart, to: interval.end).day ?? 0
        let trailingDays = (7 - daysThroughMonthEnd % 7) % 7

        return (0..<(daysThroughMonthEnd + trailingDays)).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: gridStart).map { date in
                OperationCalendarDay(
                    date: date,
                    isInDisplayedMonth: calendar.isDate(date, equalTo: interval.start, toGranularity: .month)
                )
            }
        }
    }

    static func weekdays(calendar: Calendar) -> [OperationCalendarWeekday] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        guard symbols.count == 7 else { return [] }

        return (0..<7).map { offset in
            let weekday = ((calendar.firstWeekday - 1 + offset) % 7) + 1
            return OperationCalendarWeekday(id: weekday, title: symbols[weekday - 1])
        }
    }

    #if DEBUG
    static func assertSelfCheck() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2

        let february = calendar.date(from: DateComponents(year: 2024, month: 2, day: 1))!
        let grid = days(for: february, calendar: calendar)
        assert(grid.count == 35)
        assert(calendar.dateComponents([.year, .month, .day], from: grid.first!.date) == DateComponents(year: 2024, month: 1, day: 29))
        assert(calendar.dateComponents([.year, .month, .day], from: grid.last!.date) == DateComponents(year: 2024, month: 3, day: 3))
        assert(grid.filter { $0.isInDisplayedMonth }.count == 29)

        let transactions = [
            Transaction(amount: 100, kind: .income, category: "Income", date: february),
            Transaction(amount: 40, kind: .expense, category: "Expense", date: february)
        ]
        let totals = OperationTotals(transactions: transactions)
        assert(totals.income == 100 && totals.expenses == 40 && totals.balance == 60)
    }
    #endif
}

extension OperationFormatting {
    static func compactBalance(_ amount: Decimal) -> String {
        let value = abs(amount).formatted(
            .number
                .notation(.compactName)
                .precision(.fractionLength(0...1))
                .locale(Locale(identifier: LocalizationManager.shared.currentLanguage))
        )
        if amount > 0 { return "+\(value)" }
        if amount < 0 { return "−\(value)" }
        return value
    }
}

private func balanceColor(for balance: Decimal) -> Color {
    if balance > 0 { return .green }
    if balance < 0 { return .red }
    return .secondary
}
