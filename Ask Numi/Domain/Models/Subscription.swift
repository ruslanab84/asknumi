//
//  Subscription.swift
//  Ask Numi
//

import Foundation

struct Subscription: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var amount: Decimal
    var billingDay: Int
    var nextChargeDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        nextChargeDate: Date,
        calendar: Calendar = .current
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.billingDay = calendar.component(.day, from: nextChargeDate)
        self.nextChargeDate = calendar.startOfDay(for: nextChargeDate)
    }

    nonisolated static func followingChargeDate(
        after date: Date,
        billingDay: Int,
        calendar: Calendar = .current
    ) -> Date {
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: date) ?? date
        let day = min(billingDay, calendar.range(of: .day, in: .month, for: nextMonth)?.count ?? billingDay)
        var components = calendar.dateComponents([.year, .month], from: nextMonth)
        components.day = day
        return calendar.date(from: components) ?? nextMonth
    }
}
